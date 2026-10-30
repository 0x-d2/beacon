// Beacon, the iPhone app (iOS/), in the catalog (docs/beaconkit.md › iOS): its components with their `///` docs and
// their specimens' images, its screens on the demo Mac, and its colour tokens beside the Mac token each keeps the
// meaning of. The components and colours come from the sources, so the pages exist before any render; docs/scripts/
// kit.sh's iOS step adds the images (export/ios-*.json, render/ios/).
import { existsSync, mkdirSync, readFileSync, statSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { parseColor, type ColorValue } from './colors.ts'
import { docAbove, readSources } from './swift.ts'

type Image = { src: string; width: number; height: number; mode: string }

const screenTitles: Record<string, { tr: string; en: string }> = {
  macs: { tr: 'Mac listesi (boş)', en: 'Macs (empty)' },
  dashboard: { tr: 'Gösterge paneli', en: 'Dashboard' },
  cpu: { tr: 'CPU', en: 'CPU' },
  memory: { tr: 'Bellek', en: 'Memory' },
  network: { tr: 'Ağ', en: 'Network' },
  power: { tr: 'Güç', en: 'Power' },
  disk: { tr: 'Diskler', en: 'Disks' },
  temperature: { tr: 'Sıcaklıklar', en: 'Temperatures' },
}

const readJSON = <T>(path: string): T | null => (existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) as T : null)

export async function collectIOS(root: string, web: string, kit: string | undefined) {
  if (!existsSync(join(root, 'iOS', 'Beacon'))) return null
  const files = readSources(root, 'iOS/Beacon')

  // Components: every `KitSpecimen("Name", .category, [ KitVariant("id", "title" …` in the sources.
  const components: { id: string; category: string; doc: string; source: { file: string; line: number }; variants: { id: string; title: string; images: Record<string, Image> }[] }[] = []
  for (const file of files) {
    file.lines.forEach((line, index) => {
      const specimen = line.match(/KitSpecimen\("([^"]+)", \.(\w+), \[/)
      if (!specimen) return
      const declaration = files.flatMap((f) => f.lines.map((l, i) => ({ f, l, i }))).find(({ l }) => new RegExp(`^struct ${specimen[1]}\\b`).test(l))
      const variants: { id: string; title: string; images: Record<string, Image> }[] = []
      for (let i = index + 1; i < file.lines.length && !/^ {4}\]\)/.test(file.lines[i]); i++) {
        const variant = file.lines[i].match(/KitVariant\("([^"]+)", "((?:[^"\\]|\\.)*)"/)
        if (variant) variants.push({ id: variant[1], title: variant[2].replace(/\\"/g, '"'), images: {} })
      }
      components.push({
        id: specimen[1],
        category: specimen[2],
        doc: declaration ? docAbove(declaration.f.lines, declaration.i) : '',
        source: declaration ? { file: declaration.f.path, line: declaration.i + 1 } : { file: file.path, line: index + 1 },
        variants,
      })
    })
  }

  // Colours: BeaconColor's `static let name = dynamic(light: (r, g, b), dark: UIColor.systemX)` and the plain ones,
  // with the Mac token their doc names (`/// CPU: PanelMetricColor.green.`).
  const colorFile = files.find((f) => f.path.endsWith('DesignSystem/BeaconColor.swift'))
  const colors: { id: string; doc: string; mac: string | null; expression: string; light: ColorValue | null; dark: ColorValue | null; source: { file: string; line: number } }[] = []
  colorFile?.lines.forEach((line, index) => {
    const match = line.match(/^ {4}static let (\w+) = (.+)$/)
    if (!match) return
    const doc = docAbove(colorFile.lines, index)
    const dynamic = match[2].match(/dynamic\(light: \(([0-9.]+), ([0-9.]+), ([0-9.]+)\), dark: UIColor\.system(\w+)\)/)
    const light = dynamic ? parseColor(`Color(red: ${dynamic[1]}, green: ${dynamic[2]}, blue: ${dynamic[3]})`, 'light') : null
    const dark = dynamic ? parseColor(`.${dynamic[4][0].toLowerCase()}${dynamic[4].slice(1)}`, 'dark') : null
    colors.push({
      id: match[1], doc, mac: doc.match(/PanelMetricColor\.\w+/)?.[0] ?? null, expression: match[2],
      light, dark, source: { file: colorFile.path, line: index + 1 },
    })
  })

  const screens: { id: string; title: { tr: string; en: string }; images: Record<string, Image> }[] = Object.keys(screenTitles)
    .map((id) => ({ id, title: screenTitles[id], images: {} }))
  let rendered: { sha: string; at: string } | null = null

  if (kit && existsSync(join(kit, 'render', 'ios'))) {
    const sharp = (await import('sharp')).default
    const jobs: (() => Promise<void>)[] = []
    const convert = (input: string, output: string) => {
      if (existsSync(output) && statSync(output).mtimeMs >= statSync(input).mtimeMs) return
      jobs.push(async () => {
        mkdirSync(dirname(output), { recursive: true })
        await sharp(input).webp({ lossless: true, effort: 4 }).toFile(output)
      })
    }
    const componentManifest = readJSON<Record<string, { width: number; height: number }>>(join(kit, 'render', 'ios', 'components', 'manifest.json')) ?? {}
    for (const [key, size] of Object.entries(componentManifest)) {
      const [language, theme, id, variantID] = key.split('/')
      const variant = components.find((c) => c.id === id)?.variants.find((v) => v.id === variantID)
      const png = join(kit, 'render', 'ios', 'components', language, theme, id, `${variantID}.png`)
      if (!variant || !existsSync(png)) continue
      const src = `renders/ios/components/${language}/${theme}/${id}/${variantID}.webp`
      convert(png, join(web, 'public', src))
      variant.images[`${language}-${theme}`] = { src, width: size.width, height: size.height, mode: 'imageRenderer' }
    }
    const screenManifest = readJSON<Record<string, { width: number; height: number }>>(join(kit, 'render', 'ios', 'screens', 'manifest.json')) ?? {}
    for (const [key, size] of Object.entries(screenManifest)) {
      const [language, theme, id] = key.split('/')
      const screen = screens.find((s) => s.id === id)
      const png = join(kit, 'render', 'ios', 'screens', language, theme, `${id}.png`)
      if (!screen || !existsSync(png)) continue
      const src = `renders/ios/screens/${language}/${theme}/${id}.webp`
      convert(png, join(web, 'public', src))
      screen.images[`${language}-${theme}`] = { src, width: size.width, height: size.height, mode: 'screen' }
    }
    // The app's own resolution of its colours replaces the sources' reading where there is one.
    const tokens = readJSON<{ colors: { id: string; light: ColorValue; dark: ColorValue }[] }>(join(kit, 'export', 'ios-tokens.json'))
    for (const token of tokens?.colors ?? []) {
      const color = colors.find((c) => c.id === token.id)
      if (color) { color.light = token.light; color.dark = token.dark }
    }
    rendered = readJSON<{ ios?: { sha: string; at: string } }>(join(kit, 'render', 'rendered.json'))?.ios ?? null
    let next = 0
    await Promise.all(Array.from({ length: 4 }, async () => { while (next < jobs.length) await jobs[next++]() }))
  }

  return { components, colors, screens, rendered }
}
