// `npm run collect` (docs/beaconkit.md › Collector): the Swift sources, git and the open revision notes (and, with
// `--kit <dir>`, the renders docs/scripts/kit.sh wrote) → web/public/data/catalog.json, checked against schema.ts.
//
//   npm run collect                       the sources alone: tokens, components, surfaces, inline values, guide
//   npm run collect -- --kit ~/BeaconKit/kit   with the renders (Bileşenler and Yüzeyler show the app's pixels)
import { mkdirSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { deltaE2000, hexToLab, systemColors, type ColorValue } from './colors.ts'
import { categories, findComponents, type Component } from './components.ts'
import { git, lastChanges, recentChanges, repository, revisionNotes } from './git.ts'
import { resolveGuide, resolveLandmarks } from './guide.ts'
import { scanLiterals, type LiteralGroup, type LiteralKind } from './literals.ts'
import { readRenders } from './renders.ts'
import { catalog as schema } from './schema.ts'
import { appStrings } from './strings.ts'
import { findSurfaces, surfaceGroups } from './surfaces.ts'
import { area, areaTitles, blockEnd, codeLines, readSources, type SourceFile } from './swift.ts'
import { colorFunctions, gradientConstants, metricConstants, motionConstants, palettes, textStyleFunctions } from './tokens.ts'

const web = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const root = resolve(web, '..')
const argument = (name: string) => {
  const at = process.argv.indexOf(name)
  return at >= 0 ? process.argv[at + 1] : undefined
}
const kit = argument('--kit')
const started = Date.now()
const warnings: string[] = []

const files = readSources(root, 'Sources/Vorssaint')
const byPath = new Map(files.map((f) => [f.path, f]))
const file = (path: string) => {
  const found = byPath.get(`Sources/Vorssaint/${path}`)
  if (!found) warnings.push(`missing source: ${path}`)
  return found ?? { path, lines: [] }
}

// MARK: Tokens

const theme = file('UI/Theme.swift')
const metricColors = colorFunctions(theme, 'PanelMetricColor')
const surfacesColors = colorFunctions(theme, 'PanelSurface')
const colorTokens = [...metricColors.colors, ...surfacesColors.colors]
const gradientTokens = [...gradientConstants(theme, 'Theme'), ...metricColors.gradients, ...surfacesColors.gradients]
const textStyles = textStyleFunctions(theme)
const metrics = metricConstants(file('UI/MenuPanel/MenuPanelView.swift'), 'PanelRowMetrics')
const motionFiles: [SourceFile, string][] = []
for (const f of files) {
  for (const line of f.lines) {
    const name = line.match(/^enum (\w+Motion)\b/)?.[1]
    if (name) motionFiles.push([f, name])
  }
}
const motions = motionFiles.flatMap(([f, name]) => motionConstants(f, name))
const tokenIds = new Set([...colorTokens, ...gradientTokens, ...textStyles, ...metrics, ...motions].map((t) => t.id))

/**
 * Where a token is named: `PanelSurface.cardFill(` anywhere, `sectionTitle(` for a text style, and a member used bare
 * inside its own enum (`NotchMotion.spring(from:to:)` picking `growingWidth`).
 */
function tokenUsage(id: string, own: { file: string; line: number }) {
  const [group, name] = id.includes('.') ? id.split('.') : ['', id]
  const qualified = group ? new RegExp(`\\b${group}\\.${name}\\b`) : new RegExp(`(?<![.\\w])${name}\\(`)
  const bare = new RegExp(`(?<![.\\w])${name}\\b`)
  const ownFile = byPath.get(own.file)
  const ownEnum = ownFile && group ? ownFile.lines.findIndex((l) => new RegExp(`^enum ${group}\\b`).test(l)) : -1
  const ownEnd = ownEnum >= 0 ? blockEnd(ownFile!.lines, ownEnum) : -1
  const places: { file: string; line: number }[] = []
  for (const f of files) {
    for (const { text, line } of codeLines(f)) {
      if (f.path === own.file && line === own.line) continue
      const inside = f.path === own.file && line - 1 > ownEnum && line - 1 < ownEnd
      if (qualified.test(text) || (inside && bare.test(text) && !/static (let|func|var)/.test(text))) places.push({ file: f.path, line })
    }
  }
  const byArea: Record<string, number> = {}
  for (const p of places) byArea[area(p.file)] = (byArea[area(p.file)] ?? 0) + 1
  return { total: places.length, files: new Set(places.map((p) => p.file)).size, byArea, places }
}
const withUsage = <T extends { id: string; source: { file: string; line: number } }>(tokens: T[]) => tokens.map((t) => ({ ...t, usage: tokenUsage(t.id, t.source) }))

// MARK: Inline values

const literals = scanLiterals(files.filter((f) => f.path.startsWith('Sources/Vorssaint/UI/') || f.path.startsWith('Sources/Vorssaint/App/') || f.path.startsWith('Sources/Vorssaint/Services/Notch/')))
const landmarks = resolveLandmarks(files)
const sameAs = (value: number, ids: { id: string; value: number }[]) => ids.filter((t) => t.value === value).map((t) => t.id)

/** A token an inline value equals (a corner like the panel card's, a size like the section title's, a colour within ΔE 2). */
function match(kind: LiteralKind, group: LiteralGroup): { token: string; note: { tr: string; en: string } } | null {
  if (kind === 'radius' && group.value !== null) {
    const same = sameAs(group.value, landmarks.filter((l) => l.id === 'panelCard.cornerRadius'))
    if (same.length) return { token: '.panelCard()', note: { tr: 'Panel kartının köşesiyle aynı (10)', en: 'Same as the panel card\'s corner (10)' } }
  }
  if (kind === 'font') {
    const style = textStyles.find((s) => group.key === `${s.size} · ${s.weight}`)
    if (style) return { token: style.id, note: { tr: `${style.id} ile aynı boyut ve kalınlık`, en: `Same size and weight as ${style.id}` } }
  }
  if ((kind === 'padding' || kind === 'spacing') && group.value !== null) {
    const same = metrics.filter((m) => m.value === group.value || m.island === group.value)
    if (same.length) return { token: same[0].id, note: { tr: `${same.map((m) => m.id).join(', ')} ile aynı sayı`, en: `Same number as ${same.map((m) => m.id).join(', ')}` } }
  }
  if (kind === 'color' && group.color) {
    for (const token of colorTokens) {
      for (const appearance of ['light', 'dark'] as const) {
        const a = group.color[appearance]
        const b = token.values[appearance]
        if (!a || !b || Math.abs(a.alpha - b.alpha) > 0.02) continue
        const distance = deltaE2000(hexToLab(a.hex), hexToLab(b.hex))
        if (distance < 2) {
          return { token: token.id, note: { tr: `${token.id} ile neredeyse aynı (${appearance === 'light' ? 'açık' : 'koyu'}, ΔE ${distance.toFixed(1)})`, en: `Nearly ${token.id} (${appearance}, ΔE ${distance.toFixed(1)})` } }
        }
      }
    }
  }
  return null
}
const literalCatalog = Object.fromEntries(Object.entries(literals).map(([kind, groups]) =>
  [kind, groups.map((g) => ({ ...g, match: match(kind as LiteralKind, g) }))])) as Record<LiteralKind, (LiteralGroup & { match: ReturnType<typeof match> })[]>

const systemColorList = Object.entries(systemColors.colors)
  .map(([id, values]) => ({
    id, light: values.light as ColorValue, dark: values.dark as ColorValue,
    count: literals.color.filter((g) => g.key === `.${id}` || (id === 'accentColor' && g.key === 'Color.accentColor') || g.key === `Color(nsColor: .${id}Color)`).reduce((n, g) => n + g.count, 0),
  }))
  .filter((c) => c.count > 0)
  .sort((a, b) => b.count - a.count)

// MARK: Components and surfaces

const strings = appStrings(files)
const kitSpecimens = new Set<string>()
const preliminary = findComponents(files, tokenIds)
const surfaceResult = findSurfaces(files, strings, new Set(preliminary.map((c) => c.id)), tokenIds)
const components: Component[] = findComponents(files, tokenIds, kitSpecimens, surfaceResult.views)
const componentIds = new Set(components.map((c) => c.id))
// A surface's components are counted against the final list (the surfaces themselves aren't components).
const { surfaces } = findSurfaces(files, strings, componentIds, tokenIds)

const renders = kit ? await readRenders(kit, web, warnings) : null
const changed = lastChanges(root, ['Sources/Vorssaint'])
const repo = repository(root)
const issues = revisionNotes(repo)
const notesFor = (item: string) => issues.filter((i) => i.item === item || i.item.startsWith(`${item} `) || i.item.startsWith(`${item}·`))

const usedBy = new Map<string, Set<string>>()
for (const c of components) for (const used of c.uses.components) usedBy.set(used, (usedBy.get(used) ?? new Set()).add(c.id))
for (const s of surfaces) for (const used of Object.keys(s.components)) usedBy.set(used, (usedBy.get(used) ?? new Set()).add(s.id))

const guide = resolveGuide(files)
for (const missing of guide.missing) warnings.push(`guide entry no longer found: ${missing}`)

const status = git(root, 'status', '--porcelain', '--', 'Sources', 'web', 'docs')
const catalog = schema.parse({
  meta: {
    sha: git(root, 'rev-parse', 'HEAD') || 'unknown',
    branch: process.env.GITHUB_REF_NAME || git(root, 'rev-parse', '--abbrev-ref', 'HEAD') || 'unknown',
    dirty: status.length > 0,
    builtAt: new Date().toISOString(),
    repo,
    languages: ['tr', 'en'],
    systemColors: systemColors.macOS,
    renders: renders?.rendered ?? { components: null, surfaces: null },
    counts: {
      files: files.length,
      uiFiles: files.filter((f) => f.path.startsWith('Sources/Vorssaint/UI/')).length,
      lines: files.reduce((n, f) => n + f.lines.length, 0),
    },
  },
  categories,
  surfaceGroups,
  areas: areaTitles,
  tokens: {
    colors: withUsage(colorTokens),
    gradients: withUsage(gradientTokens),
    textStyles: withUsage(textStyles),
    metrics: withUsage(metrics),
    motions: withUsage(motions),
    palettes: palettes(files),
    landmarks,
  },
  systemColors: systemColorList,
  literals: literalCatalog,
  components: components.map((c) => ({
    ...c,
    usedBy: [...(usedBy.get(c.id) ?? [])].sort(),
    lastChange: changed.get(c.source.file) ?? null,
    variants: renders?.variants.get(c.id) ?? [],
    issues: notesFor(c.id),
  })),
  surfaces: surfaces.map((s) => ({
    ...s,
    lastChange: changed.get(s.source.file) ?? null,
    images: renders?.surfaces.get(s.id) ?? {},
    issues: notesFor(s.id),
  })),
  guide: guide.entries,
  changes: recentChanges(root, ['Sources/Vorssaint/UI', 'Sources/Vorssaint/Services/Notch', 'Sources/Vorssaint/App/MenuBarRenderer.swift', 'Resources/Brand']),
  issues,
})

const out = join(web, 'public', 'data', 'catalog.json')
mkdirSync(dirname(out), { recursive: true })
writeFileSync(out, JSON.stringify(catalog))

const literalTotal = Object.values(catalog.literals).reduce((n, groups) => n + groups.reduce((m, g) => m + g.count, 0), 0)
console.log([
  `BeaconKit™ catalog → ${out.replace(root + '/', '')} (${Math.round(JSON.stringify(catalog).length / 1024)} KB, ${Date.now() - started} ms)`,
  `  ${catalog.tokens.colors.length} colours, ${catalog.tokens.gradients.length} gradients, ${catalog.tokens.textStyles.length} text styles, ${catalog.tokens.metrics.length} metrics, ${catalog.tokens.motions.length} motions, ${catalog.tokens.palettes.length} palettes`,
  `  ${catalog.components.length} components, ${catalog.surfaces.length} surfaces, ${literalTotal} inline values, ${catalog.guide.length} guide entries, ${issues.length} open notes`,
  renders ? `  renders: ${[...renders.variants.values()].reduce((n, v) => n + v.length, 0)} variants, ${renders.surfaces.size} surfaces` : '  renders: none (npm run collect -- --kit <dir>)',
].join('\n'))
for (const warning of warnings) console.warn(`  ! ${warning}`)
