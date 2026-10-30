// The inline values (docs/beaconkit.md › Inline values): what the views type in place instead of naming a token. The
// app keeps few tokens (tokens.ts) and draws most of its look with literals: corner radii, font sizes, paddings,
// spacings, shadows, animation curves, colours and materials. Each kind is grouped by value, with every place it's
// written (file, line, the code), so a change to "every 7 pt corner" or "the 0.15 s ease-outs" starts from a list.
import { parseColor, type ColorValue } from './colors.ts'
import { codeLines, type SourceFile } from './swift.ts'

export type Place = { file: string; line: number; code: string }
export type LiteralGroup = {
  key: string
  /** The number it sorts by (a radius, a size, a duration), null for a name. */
  value: number | null
  count: number
  files: number
  places: Place[]
  /** A colour group's value, in both appearances where it differs. */
  color: { light: ColorValue | null; dark: ColorValue | null } | null
}
export type LiteralKind = 'radius' | 'font' | 'padding' | 'spacing' | 'shadow' | 'animation' | 'color' | 'material' | 'frame'

const number = '([0-9]+(?:\\.[0-9]+)?)'

type Rule = { kind: LiteralKind; scan: (text: string) => { key: string; value: number | null }[] }

const all = (text: string, pattern: RegExp, make: (m: RegExpMatchArray) => { key: string; value: number | null } | null) =>
  [...text.matchAll(pattern)].map(make).filter((x): x is { key: string; value: number | null } => x !== null)

const rules: Rule[] = [
  {
    kind: 'radius',
    scan: (text) => [
      ...all(text, new RegExp(`cornerRadius:\\s*${number}(?![\\w.])`, 'g'), (m) => ({ key: m[1], value: +m[1] })),
      ...all(text, new RegExp(`\\.cornerRadius\\(${number}\\)`, 'g'), (m) => ({ key: m[1], value: +m[1] })),
    ],
  },
  {
    kind: 'font',
    scan: (text) => [
      ...all(text, new RegExp(`\\.system\\(size:\\s*${number}(?:,\\s*weight:\\s*\\.(\\w+))?(?:,\\s*design:\\s*\\.(\\w+))?\\)`, 'g'), (m) => ({
        key: [m[1], m[2] ?? 'regular', m[3]].filter(Boolean).join(' · '), value: +m[1],
      })),
      ...all(text, /\.font\(\.(largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)\b(?:\.weight\(\.(\w+)\))?/g, (m) => ({
        key: [`.${m[1]}`, m[2]].filter(Boolean).join(' · '), value: semanticSizes[m[1]] ?? null,
      })),
      ...all(text, /\.system\(size:\s*([a-zA-Z_][\w.]*)/g, () => ({ key: 'size: (değişken)', value: null })),
    ],
  },
  {
    kind: 'padding',
    scan: (text) => all(text, new RegExp(`\\.padding\\((?:\\.(\\w+),\\s*)?${number}\\)`, 'g'), (m) => ({ key: m[1] ? `${m[2]} · .${m[1]}` : m[2], value: +m[2] })),
  },
  {
    kind: 'spacing',
    scan: (text) => all(text, new RegExp(`\\bspacing:\\s*${number}(?![\\w.])`, 'g'), (m) => ({ key: m[1], value: +m[1] })),
  },
  {
    kind: 'frame',
    scan: (text) => all(text, new RegExp(`\\.frame\\((?:[^)]*?\\b(width|height|minWidth|minHeight|maxWidth|maxHeight):\\s*${number})`, 'g'), (m) => ({ key: `${m[1]}: ${m[2]}`, value: +m[2] })),
  },
  {
    kind: 'shadow',
    scan: (text) => all(text, /\.shadow\(((?:[^()]|\((?:[^()]|\([^()]*\))*\))*)\)/g, (m) => {
      const radius = m[1].match(/radius:\s*([0-9.]+)/)?.[1]
      const y = m[1].match(/\by:\s*(-?[0-9.]+)/)?.[1]
      // The colour's opacity, both of a light / dark pair (`opacity(colorScheme == .light ? 0.08 : 0.28)`).
      const opacity = m[1].match(/opacity\((?:[^()?]*\?\s*([0-9.]+)\s*:\s*([0-9.]+)|([0-9.]+))\)/)
      if (!radius) return { key: 'radius: (değişken)', value: null }
      const alpha = opacity ? (opacity[3] ?? `${opacity[1]}/${opacity[2]}`) : null
      return { key: [`radius ${radius}`, y && y !== '0' ? `y ${y}` : null, alpha ? `opacity ${alpha}` : null].filter(Boolean).join(' · '), value: +radius }
    }),
  },
  {
    kind: 'animation',
    scan: (text) => /animation|withAnimation|Animation\b|transaction/.test(text)
      ? all(text, /\.(easeOut|easeIn|easeInOut|linear|spring|smooth|snappy|bouncy|interactiveSpring|interpolatingSpring|default)\b(\((?:[^()]|\([^()]*\))*\))?/g, (m) => {
        const duration = m[2]?.match(/(?:duration|response):\s*([0-9.]+)/)?.[1] ?? m[2]?.match(/^\(([0-9.]+)/)?.[1]
        return { key: `.${m[1]}${m[2] ? m[2].replace(/\s+/g, ' ') : ''}`, value: duration ? +duration : null }
      })
      : [],
  },
  {
    kind: 'color',
    scan: (text) => [
      ...all(text, /\b\w*Colou?r\(\s*red:\s*[0-9.]+,\s*green:\s*[0-9.]+,\s*blue:\s*[0-9.]+(?:,\s*opacity:\s*[0-9.]+)?\s*\)(?:\.opacity\([0-9.]+\))?/g, (m) => ({ key: normalise(m[0]), value: null })),
      ...all(text, /\bColor\(\s*white:\s*[0-9.]+(?:,\s*opacity:\s*[0-9.]+)?\)(?:\.opacity\([0-9.]+\))?/g, (m) => ({ key: normalise(m[0]), value: null })),
      ...all(text, /\bColor\.(?:white|black)\.opacity\([0-9.]+\)/g, (m) => ({ key: normalise(m[0]), value: null })),
      ...all(text, /\bColor\(nsColor:\s*\.\w+\)/g, (m) => ({ key: normalise(m[0]), value: null })),
      ...all(text, /\bColor\.accentColor\b|\.tint\(\.accentColor\)|\(\.accentColor\)/g, () => ({ key: 'Color.accentColor', value: null })),
      ...all(text, /(?:\bColor|foregroundStyle\(|foregroundColor\(|\.fill\(|\.stroke\(|\.tint\()\s*\.?(red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|brown|gray)\b(?!\w)/g, (m) => ({ key: `.${m[1]}`, value: null })),
    ],
  },
  {
    kind: 'material',
    scan: (text) => [
      ...all(text, /\.(ultraThinMaterial|thinMaterial|regularMaterial|thickMaterial|ultraThickMaterial|bar)\b(?=[)\s,])/g, (m) => ({ key: `.${m[1]}`, value: null })),
      ...all(text, /\.glassEffect\((\.\w+)?/g, (m) => ({ key: `.glassEffect(${m[1] ?? ''})`, value: null })),
      ...all(text, /\bmaterial\s*=\s*\.(\w+)/g, (m) => ({ key: `NSVisualEffectView .${m[1]}`, value: null })),
    ],
  },
]

/** macOS's text styles in points (they don't scale with Dynamic Type on the Mac). */
export const semanticSizes: Record<string, number> = {
  largeTitle: 26, title: 22, title2: 17, title3: 15, headline: 13, body: 13, callout: 12, subheadline: 11, footnote: 10, caption: 10, caption2: 10,
}

const normalise = (text: string) => text.replace(/\s+/g, ' ').replace(/\(\s+/g, '(').replace(/\s+\)/g, ')')

/** Every inline value in the UI's sources, by kind, each kind's groups by count. */
export function scanLiterals(files: SourceFile[]): Record<LiteralKind, LiteralGroup[]> {
  const groups = new Map<string, Map<string, { value: number | null; places: Place[] }>>()
  for (const file of files) {
    for (const { text, line } of codeLines(file)) {
      for (const rule of rules) {
        for (const hit of rule.scan(text)) {
          const kind = groups.get(rule.kind) ?? new Map()
          groups.set(rule.kind, kind)
          const group = kind.get(hit.key) ?? { value: hit.value, places: [] }
          kind.set(hit.key, group)
          group.places.push({ file: file.path, line, code: text.trim().slice(0, 180) })
        }
      }
    }
  }
  const out = {} as Record<LiteralKind, LiteralGroup[]>
  for (const rule of rules) {
    if (out[rule.kind]) continue
    const kind = groups.get(rule.kind) ?? new Map<string, { value: number | null; places: Place[] }>()
    out[rule.kind] = [...kind.entries()]
      .map(([key, group]) => ({
        key,
        value: group.value,
        count: group.places.length,
        files: new Set(group.places.map((p) => p.file)).size,
        places: group.places,
        color: rule.kind === 'color' ? { light: parseColor(key, 'light'), dark: parseColor(key, 'dark') } : null,
      }))
      .sort((a, b) => b.count - a.count || (a.value ?? 0) - (b.value ?? 0) || a.key.localeCompare(b.key))
  }
  return out
}

/** How many inline values of each kind a stretch of code has (a component's body, a surface's file). */
export function literalCounts(lines: { text: string }[]): Partial<Record<LiteralKind, number>> {
  const out: Partial<Record<LiteralKind, number>> = {}
  for (const { text } of lines) {
    for (const rule of rules) {
      const n = rule.scan(text).length
      if (n) out[rule.kind] = (out[rule.kind] ?? 0) + n
    }
  }
  return out
}
