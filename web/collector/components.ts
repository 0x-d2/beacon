// The components (docs/beaconkit.md › Components): the views, view modifiers, button and toggle styles and shapes the
// app draws in more than one place. The app has no component library to read them from, so the collector finds them:
// a top-level, non-private type that conforms to View (or a style, a shape, a representable) and that code in at least
// two other files names, or anything a design-system file (Theme.swift, SharedUI.swift, SettingsCard.swift,
// PanelLayout.swift, NotchComponents.swift) declares and someone uses. A type only one place draws is that place's own
// part, and its surface (surfaces.ts) shows it. A specimen in Sources/Vorssaint/Kit/ (docs/beaconkit.md › Renders)
// adds a component even when this rule wouldn't.
import { literalCounts, type LiteralKind } from './literals.ts'
import { area, blockEnd, codeLines, declarations, docAbove, initialisers, viewModifiers, withoutStrings, withPrivateHelpers, type Declaration, type SourceFile } from './swift.ts'

export type Usage = { total: number; files: number; byArea: Record<string, number>; places: { file: string; line: number }[] }
export type Component = {
  id: string
  kind: 'view' | 'modifier' | 'style' | 'shape' | 'representable'
  category: string
  source: { file: string; line: number }
  doc: string
  api: { signature: string; doc: string; line: number }[]
  uses: { tokens: string[]; components: string[] }
  literals: Partial<Record<LiteralKind, number>>
  usage: Usage
}

/** The files the app's look is mostly written in: what they declare counts as a component once anything uses it. */
const kitFiles = new Set([
  'Sources/Vorssaint/UI/Theme.swift',
  'Sources/Vorssaint/UI/SharedUI.swift',
  'Sources/Vorssaint/UI/ColorSwatch.swift',
  'Sources/Vorssaint/UI/Settings/SettingsCard.swift',
  'Sources/Vorssaint/UI/MenuPanel/PanelLayout.swift',
  'Sources/Vorssaint/UI/MenuPanel/Sparkline.swift',
  'Sources/Vorssaint/UI/Notch/NotchComponents.swift',
])

/** The catalog's categories, in the sidebar's order. */
export const categories = [
  { id: 'shared', title: { tr: 'Ortak', en: 'Shared' } },
  { id: 'panel', title: { tr: 'Menü paneli', en: 'Menu panel' } },
  { id: 'charts', title: { tr: 'Grafikler', en: 'Charts' } },
  { id: 'settings', title: { tr: 'Ayarlar', en: 'Settings' } },
  { id: 'notch', title: { tr: 'Dynamic Island', en: 'Dynamic Island' } },
  { id: 'tools', title: { tr: 'Yüzen araçlar', en: 'Floating tools' } },
]

/** Graphs and gauges, wherever they're declared: the System tab's and the island's instruments. */
const charts = /^(Sparkline|UsageBar|PressureIndicator|CPUCoreMatrix|NotchMeter|NotchEqualizerBars|MetricDetail\w*|\w*Gauge\w*|\w*Graph\w*|\w*Chart\w*)$/

function category(path: string, name: string): string {
  if (charts.test(name)) return 'charts'
  const folder = path.match(/^Sources\/Vorssaint\/UI\/(\w+)\//)?.[1]
  if (folder === 'MenuPanel') return 'panel'
  if (folder === 'Settings') return 'settings'
  if (folder === 'Notch') return 'notch'
  if (!folder) return 'shared'
  return 'tools'
}

const drawingConformance = /^(View|ViewModifier|ButtonStyle|PrimitiveButtonStyle|ToggleStyle|LabelStyle|Shape|InsettableShape|NSViewRepresentable|NSViewControllerRepresentable|TextFieldStyle|MenuStyle|GroupBoxStyle|DisclosureGroupStyle)$/

function kindOf(declaration: Declaration): Component['kind'] {
  const c = declaration.conformances.find((x) => drawingConformance.test(x)) ?? ''
  if (/Style$/.test(c)) return 'style'
  if (/Shape$/.test(c)) return 'shape'
  if (/Representable$/.test(c)) return 'representable'
  if (c === 'ViewModifier') return 'modifier'
  return 'view'
}

type Candidate = { name: string; file: SourceFile; declaration: Declaration | null; modifier: ReturnType<typeof viewModifiers>[number] | null }

/** Where each name is written in code (not in a string, not as a member `Foo.Bar`, not in its own declaration's line). */
function referenceIndex(files: SourceFile[], names: Set<string>, modifiers: Set<string>) {
  const index = new Map<string, { file: string; line: number }[]>()
  const add = (name: string, file: string, line: number) => {
    const list = index.get(name) ?? []
    index.set(name, list)
    list.push({ file, line })
  }
  for (const file of files) {
    for (const { text, line } of codeLines(file)) {
      const code = withoutStrings(text)
      if (/^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|internal|private|fileprivate|final)\s+)*(?:struct|enum|class|extension|protocol)\s/.test(code)) {
        // A declaration line names the type it declares; an extension of it isn't a use either.
        const own = code.match(/(?:struct|enum|class|extension|protocol)\s+(\w+)/)?.[1]
        for (const m of code.matchAll(/(?<![.\w])([A-Z]\w+)\b/g)) if (m[1] !== own && names.has(m[1])) add(m[1], file.path, line)
        continue
      }
      for (const m of code.matchAll(/(?<![.\w])([A-Z]\w+)\b/g)) if (names.has(m[1])) add(m[1], file.path, line)
      for (const m of code.matchAll(/\.(\w+)\(/g)) if (modifiers.has(m[1])) add(`.${m[1]}()`, file.path, line)
    }
  }
  return index
}

function usageOf(places: { file: string; line: number }[], ownFile: string, ownLines: [number, number]): Usage {
  const outside = places.filter((p) => p.file !== ownFile || p.line < ownLines[0] || p.line > ownLines[1])
  const byArea: Record<string, number> = {}
  for (const place of outside) byArea[area(place.file)] = (byArea[area(place.file)] ?? 0) + 1
  return { total: outside.length, files: new Set(outside.map((p) => p.file)).size, byArea, places: outside }
}

/** Tokens a stretch of code names. */
export function tokenReferences(lines: { text: string }[], tokens: Set<string>): string[] {
  const found = new Set<string>()
  for (const { text } of lines) {
    for (const m of text.matchAll(/\b(PanelMetricColor|PanelSurface|PanelRowMetrics|NotchMotion|Theme)\.(\w+)/g)) {
      if (tokens.has(`${m[1]}.${m[2]}`)) found.add(`${m[1]}.${m[2]}`)
    }
    if (/\bsectionTitle\(/.test(text) && tokens.has('sectionTitle')) found.add('sectionTitle')
  }
  return [...found].sort()
}

export function findComponents(files: SourceFile[], tokens: Set<string>, specimens: Set<string> = new Set(), surfaces: Set<string> = new Set()): Component[] {
  const ui = files.filter((f) => f.path.startsWith('Sources/Vorssaint/UI/'))
  const candidates: Candidate[] = []
  for (const file of ui) {
    for (const declaration of declarations(file)) {
      if (declaration.access === 'private' || declaration.access === 'fileprivate') continue
      if (!declaration.conformances.some((c) => drawingConformance.test(c))) continue
      // A panel section, a Settings page, an island module: a surface (surfaces.ts), not a part others draw with.
      if (surfaces.has(declaration.name) && !specimens.has(declaration.name)) continue
      candidates.push({ name: declaration.name, file, declaration, modifier: null })
    }
    // Overloads of one modifier (`.notchBand(…)` three ways) are one component, its first declaration.
    const seen = new Set<string>()
    for (const modifier of viewModifiers(file)) {
      if (seen.has(modifier.name)) continue
      seen.add(modifier.name)
      candidates.push({ name: `.${modifier.name}()`, file, declaration: null, modifier })
    }
  }
  const names = new Set(candidates.filter((c) => c.declaration).map((c) => c.name))
  const modifierNames = new Set(candidates.filter((c) => c.modifier).map((c) => c.modifier!.name))
  const index = referenceIndex(files, names, modifierNames)

  const out: Component[] = []
  for (const candidate of candidates) {
    const start = (candidate.declaration?.line ?? candidate.modifier!.line) - 1
    const end = blockEnd(candidate.file.lines, start)
    const usage = usageOf(index.get(candidate.name) ?? [], candidate.file.path, [start + 1, end + 1])
    const otherFiles = new Set(usage.places.map((p) => p.file).filter((f) => f !== candidate.file.path)).size
    const isComponent = specimens.has(candidate.name) || otherFiles >= 2 || (kitFiles.has(candidate.file.path) && usage.total > 0)
    if (!isComponent) continue
    const body = withPrivateHelpers(candidate.file, [start, end])
      .flatMap(([from, to]) => codeLines({ path: candidate.file.path, lines: candidate.file.lines.slice(from, to + 1) }))
    const uses = new Set<string>()
    for (const { text } of body) {
      const code = withoutStrings(text)
      for (const m of code.matchAll(/(?<![.\w])([A-Z]\w+)\b/g)) if (names.has(m[1]) && m[1] !== candidate.name) uses.add(m[1])
      for (const m of code.matchAll(/\.(\w+)\(/g)) if (modifierNames.has(m[1]) && `.${m[1]}()` !== candidate.name) uses.add(`.${m[1]}()`)
    }
    out.push({
      id: candidate.name,
      kind: candidate.modifier ? 'modifier' : kindOf(candidate.declaration!),
      category: category(candidate.file.path, candidate.name.replace(/^\.|\(\)$/g, '')),
      source: { file: candidate.file.path, line: start + 1 },
      doc: docAbove(candidate.file.lines, start),
      api: candidate.modifier
        ? viewModifiers(candidate.file).filter((m) => m.name === candidate.modifier!.name)
          .map((m) => ({ signature: m.signature.replace(/^func /, '.'), doc: m.doc, line: m.line }))
        : initialisers(candidate.file, candidate.declaration!),
      uses: { tokens: tokenReferences(body, tokens), components: [...uses].sort() },
      literals: literalCounts(body),
      usage,
    })
  }
  return out.sort((a, b) => categories.findIndex((c) => c.id === a.category) - categories.findIndex((c) => c.id === b.category) || b.usage.total - a.usage.total)
}
