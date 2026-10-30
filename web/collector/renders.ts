// The renders docs/scripts/kit.sh writes (docs/beaconkit.md › Renders), as the site serves them: each variant's and
// surface's PNG, per language and theme, turned into lossless WebP (crisp edges, exact colours) under
// web/public/renders, skipped when the WebP is newer than its PNG. Their sizes are in points (the renders are @2x).
//
//   <kit>/export/registry.json                         the specimens and their variants, in render order
//   <kit>/render/components/<lang>/<theme>/<slug>/<variant>.png        + manifest.json (slug: the id's letters)
//   <kit>/render/surfaces/<lang>/<theme>/<surface>.png                + manifest.json
//   <kit>/render/rendered.json                         each group's commit and time
import { existsSync, mkdirSync, readFileSync, statSync } from 'node:fs'
import { dirname, join } from 'node:path'

/** `mode`: how the image was taken (`screen`: the screen itself; `window`: the renderer's windows alone, without
 *  Screen Recording permission, so materials come out flat; `imageRenderer`: SwiftUI alone). */
type Image = { src: string; width: number; height: number; mode: string }
type Manifest = Record<string, { width: number; height: number; mode?: string }>
type Registry = { specimens: { id: string; slug: string; variants: { id: string; title: string; capture: 'screen' | 'imageRenderer' }[] }[] }
type Rendered = { sha: string; at: string } | null

const readJSON = <T>(path: string): T | null => (existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) as T : null)

export async function readRenders(kit: string, web: string, warnings: string[]) {
  const registry = readJSON<Registry>(join(kit, 'export', 'registry.json'))
  const rendered = readJSON<{ components?: Rendered; surfaces?: Rendered }>(join(kit, 'render', 'rendered.json'))
  const variants = new Map<string, { id: string; title: string; capture: 'screen' | 'imageRenderer'; images: Record<string, Image> }[]>()
  const surfaces = new Map<string, Record<string, Image>>()
  if (!registry) {
    warnings.push(`no registry at ${join(kit, 'export', 'registry.json')}: run docs/scripts/kit.sh first`)
    return { variants, surfaces, rendered: { components: null, surfaces: null } }
  }
  const sharp = (await import('sharp')).default
  const jobs: (() => Promise<void>)[] = []
  const convert = (input: string, output: string) => {
    if (existsSync(output) && statSync(output).mtimeMs >= statSync(input).mtimeMs) return
    jobs.push(async () => {
      mkdirSync(dirname(output), { recursive: true })
      await sharp(input).webp({ lossless: true, effort: 4 }).toFile(output)
    })
  }

  const componentManifest = readJSON<Manifest>(join(kit, 'render', 'components', 'manifest.json')) ?? {}
  for (const specimen of registry.specimens) {
    variants.set(specimen.id, specimen.variants.map((variant) => {
      const images: Record<string, Image> = {}
      for (const [key, size] of Object.entries(componentManifest)) {
        const [language, theme, slug, name] = key.split('/')
        if (slug !== specimen.slug || name !== variant.id) continue
        const png = join(kit, 'render', 'components', language, theme, slug, `${name}.png`)
        if (!existsSync(png)) continue
        const src = `renders/components/${language}/${theme}/${slug}/${name}.webp`
        convert(png, join(web, 'public', src))
        images[`${language}-${theme}`] = { src, width: size.width, height: size.height, mode: size.mode ?? 'screen' }
      }
      return { ...variant, images }
    }))
  }

  const surfaceManifest = readJSON<Manifest>(join(kit, 'render', 'surfaces', 'manifest.json')) ?? {}
  for (const [key, size] of Object.entries(surfaceManifest)) {
    const [language, theme, id] = key.split('/')
    const png = join(kit, 'render', 'surfaces', language, theme, `${id}.png`)
    if (!existsSync(png)) continue
    const src = `renders/surfaces/${language}/${theme}/${id}.webp`
    convert(png, join(web, 'public', src))
    surfaces.set(id, { ...(surfaces.get(id) ?? {}), [`${language}-${theme}`]: { src, width: size.width, height: size.height, mode: size.mode ?? 'screen' } })
  }

  // A few at a time: sharp is threaded, so four files at once keep every core busy.
  let next = 0
  await Promise.all(Array.from({ length: 4 }, async () => { while (next < jobs.length) await jobs[next++]() }))
  return { variants, surfaces, rendered: { components: rendered?.components ?? null, surfaces: rendered?.surfaces ?? null } }
}
