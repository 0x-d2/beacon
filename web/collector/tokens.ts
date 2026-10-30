// The app's tokens as the source declares them (docs/beaconkit.md › Tokens). There are few: the panel's colours and
// surfaces (`PanelMetricColor`, `PanelSurface`, `Theme` in UI/Theme.swift), the section title, the panel rows' spacing
// (`PanelRowMetrics`), the Dynamic Island's springs (`NotchMotion`) and the other `…Motion` constants, and the palettes
// an enum switches over (`NotchMascotPalette`). Everything else is typed inline (literals.ts). A token's value is
// worked out from its expression in each appearance; the renders' tokens.json (docs/scripts/kit.sh) supersedes it
// with what the app itself resolves, once there is one.
import { parseColor, type Appearance, type ColorValue } from './colors.ts'
import { blockEnd, docAbove, type SourceFile } from './swift.ts'

export type Source = { file: string; line: number }
export type ColorToken = {
  id: string
  group: string
  doc: string
  expression: string
  values: { light: ColorValue | null; dark: ColorValue | null; lightHighContrast: ColorValue | null; darkHighContrast: ColorValue | null }
  source: Source
}
export type GradientToken = { id: string; group: string; doc: string; expression: string; stops: Record<Appearance, (ColorValue | null)[]>; direction: string; source: Source }
export type TextStyleToken = { id: string; size: number; weight: string; design: string; tracking: number; uppercase: boolean; color: string | null; doc: string; source: Source }
export type MetricToken = { id: string; group: string; value: number | null; island: number | null; expression: string; doc: string; source: Source }
export type MotionToken = { id: string; group: string; kind: 'spring' | 'seconds' | 'number'; duration: number | null; bounce: number | null; value: number | null; doc: string; source: Source }
export type PaletteToken = { id: string; group: string; property: string; doc: string; entries: { id: string; expression: string; value: ColorValue | null }[]; source: Source }

// MARK: Expressions

/**
 * The expression with every `condition ? a : b` whose condition `test` recognises replaced by the branch it picks, at
 * any depth (`Color.white.opacity(scheme == .light ? 0.95 : 0.30)`). Brackets are balanced, so the colons of a
 * `Color(red: …)` aren't taken for the ternary's.
 */
export function pickBranches(expression: string, test: RegExp, first: boolean): string {
  let text = expression
  for (let guard = 0; guard < 20; guard++) {
    const match = test.exec(text)
    if (!match) return text
    const start = match.index
    let i = start + match[0].length
    let depth = 0
    let colon = -1
    for (; i < text.length; i++) {
      const c = text[i]
      if ('([{'.includes(c)) depth++
      else if (')]}'.includes(c)) depth--
      else if (c === '?' && depth === 0) depth += 100 // a nested ternary: its own colon comes first
      else if (c === ':' && depth >= 100) depth -= 100
      else if (c === ':' && depth === 0) { colon = i; break }
    }
    if (colon < 0) return text
    let end = colon + 1
    depth = 0
    for (; end < text.length; end++) {
      const c = text[end]
      if ('([{'.includes(c)) depth++
      else if (')]}'.includes(c)) { if (depth === 0) break; depth-- }
      else if (c === ',' && depth === 0) break
    }
    const a = text.slice(start + match[0].length, colon).trim()
    const b = text.slice(colon + 1, end).trim()
    text = text.slice(0, start) + (first ? a : b) + text.slice(end)
  }
  return text
}

/** `scheme == .light ?`, bare or in brackets of its own; never the bracket a call opens (`.opacity(scheme == …`). */
const condition = (test: string) => new RegExp(`(?:\\(\\s*${test}\\s*\\)|${test})\\s*\\?`)
const lightTest = condition('(?:scheme|colorScheme)\\s*==\\s*\\.light')
const darkTest = condition('(?:scheme|colorScheme)\\s*==\\s*\\.dark')
const raisedTest = condition('raised')
const islandTest = condition('island')

/** The expression as the given appearance (and Increase Contrast, the `raised` flag `PanelSurface.border` reads) draws it. */
export function resolve(expression: string, appearance: Appearance, highContrast = false): string {
  let text = pickBranches(expression, lightTest, appearance === 'light')
  text = pickBranches(text, darkTest, appearance === 'dark')
  return pickBranches(text, raisedTest, highContrast)
}

/** A `static func name(for scheme:) -> T { … }` body as one expression: its last statement, `return` dropped. */
function functionBody(lines: string[], start: number): string {
  const end = blockEnd(lines, start)
  const body = lines.slice(start + 1, end).map((l) => l.trim()).filter((l) => l && !l.startsWith('//')).join(' ')
  const at = body.search(/\breturn\s/)
  return (at >= 0 ? body.slice(at).replace(/^return\s+/, '') : body).trim()
}

/** A statement that runs over several lines (`static let x = LinearGradient(\n…\n)`), joined until its brackets close. */
function statement(lines: string[], start: number): string {
  let text = lines[start].trim()
  let depth = 0
  for (let i = start; i < lines.length; i++) {
    if (i > start) text += ' ' + lines[i].trim()
    depth += [...lines[i]].reduce((n, c) => n + ('([{'.includes(c) ? 1 : ')]}'.includes(c) ? -1 : 0), 0)
    if (depth <= 0 && i >= start) break
  }
  return text.replace(/\s+/g, ' ').replace(/\(\s+/g, '(').replace(/\s+\)/g, ')').replace(/\[\s+/g, '[').replace(/\s+\]/g, ']')
}

/** The lines inside `enum <name> {` (its own members, four spaces in). */
function enumBody(file: SourceFile, name: string): { start: number; end: number } | null {
  const start = file.lines.findIndex((l) => new RegExp(`^(?:private |fileprivate )?enum ${name}\\b`).test(l))
  return start < 0 ? null : { start, end: blockEnd(file.lines, start) }
}

// MARK: Colours and gradients

/** The colour functions of an enum (`static func green(for scheme: ColorScheme) -> Color`), in every appearance. */
export function colorFunctions(file: SourceFile, group: string): { colors: ColorToken[]; gradients: GradientToken[] } {
  const body = enumBody(file, group)
  const colors: ColorToken[] = []
  const gradients: GradientToken[] = []
  if (!body) return { colors, gradients }
  for (let i = body.start + 1; i < body.end; i++) {
    const match = file.lines[i].match(/^ {4}static func (\w+)\(for (?:scheme|colorScheme): ColorScheme\) -> (Color|LinearGradient)/)
    if (!match) continue
    const expression = functionBody(file.lines, i)
    const source = { file: file.path, line: i + 1 }
    const id = `${group}.${match[1]}`
    if (match[2] === 'Color') {
      colors.push({
        id, group, doc: docAbove(file.lines, i), expression, source,
        values: {
          light: parseColor(resolve(expression, 'light'), 'light'),
          dark: parseColor(resolve(expression, 'dark'), 'dark'),
          lightHighContrast: /raised/.test(expression) ? parseColor(resolve(expression, 'light', true), 'light') : null,
          darkHighContrast: /raised/.test(expression) ? parseColor(resolve(expression, 'dark', true), 'dark') : null,
        },
      })
    } else {
      gradients.push(gradient(id, group, docAbove(file.lines, i), expression, source))
    }
    i = blockEnd(file.lines, i)
  }
  return { colors, gradients }
}

/** `static let x = LinearGradient(colors: […], startPoint: …, endPoint: …)` members of an enum. */
export function gradientConstants(file: SourceFile, group: string): GradientToken[] {
  const body = enumBody(file, group)
  if (!body) return []
  const out: GradientToken[] = []
  for (let i = body.start + 1; i < body.end; i++) {
    const match = file.lines[i].match(/^ {4}static let (\w+) = LinearGradient\(/)
    if (!match) continue
    const expression = statement(file.lines, i).replace(/^static let \w+ = /, '')
    out.push(gradient(`${group}.${match[1]}`, group, docAbove(file.lines, i), expression, { file: file.path, line: i + 1 }))
  }
  return out
}

function gradient(id: string, group: string, doc: string, expression: string, source: Source): GradientToken {
  const stops = (appearance: Appearance) => {
    const resolved = resolve(expression, appearance)
    const list = resolved.match(/colors:\s*\[(.*?)\]\s*,/)?.[1] ?? ''
    return splitTop(list).map((c) => parseColor(c, appearance))
  }
  const start = expression.match(/startPoint:\s*\.(\w+)/)?.[1] ?? 'top'
  const end = expression.match(/endPoint:\s*\.(\w+)/)?.[1] ?? 'bottom'
  return { id, group, doc, expression, stops: { light: stops('light'), dark: stops('dark') }, direction: `${start}→${end}`, source }
}

/** A comma-separated list split at its top level only. */
function splitTop(list: string): string[] {
  const out: string[] = []
  let depth = 0
  let current = ''
  for (const c of list) {
    if ('([{'.includes(c)) depth++
    if (')]}'.includes(c)) depth--
    if (c === ',' && depth === 0) { out.push(current.trim()); current = '' } else current += c
  }
  if (current.trim()) out.push(current.trim())
  return out
}

// MARK: Text styles

/** `func sectionTitle(_:)` and the like: a free function that returns a styled `Text`. */
export function textStyleFunctions(file: SourceFile): TextStyleToken[] {
  const out: TextStyleToken[] = []
  for (let i = 0; i < file.lines.length; i++) {
    const match = file.lines[i].match(/^func (\w+)\(_ \w+: String\) -> some View \{/)
    if (!match) continue
    const end = blockEnd(file.lines, i)
    const body = file.lines.slice(i, end + 1).join(' ')
    const font = body.match(/\.font\(\.system\(size:\s*([0-9.]+)(?:,\s*weight:\s*\.(\w+))?(?:,\s*design:\s*\.(\w+))?/)
    if (!font) continue
    out.push({
      id: match[1],
      size: Number(font[1]),
      weight: font[2] ?? 'regular',
      design: font[3] ?? 'default',
      tracking: Number(body.match(/\.(?:kerning|tracking)\(([0-9.]+)\)/)?.[1] ?? 0),
      uppercase: /uppercased\(\)/.test(body),
      color: body.match(/\.foregroundStyle\(\.(\w+)\)/)?.[1] ?? null,
      doc: docAbove(file.lines, i),
      source: { file: file.path, line: i + 1 },
    })
  }
  return out
}

// MARK: Metrics

/** `static let x: CGFloat = n` and `static func x(island: Bool) -> CGFloat { island ? a : b }` of an enum. */
export function metricConstants(file: SourceFile, group: string): MetricToken[] {
  const body = enumBody(file, group)
  if (!body) return []
  const out: MetricToken[] = []
  const known = new Map<string, { value: number | null; island: number | null }>()
  for (let i = body.start + 1; i < body.end; i++) {
    const line = file.lines[i]
    const constant = line.match(/^ {4}static let (\w+)(?::\s*(?:CGFloat|Double|TimeInterval))?\s*=\s*([0-9.]+)\s*$/)
    const branch = line.match(/^ {4}static func (\w+)\(island: Bool\) -> CGFloat \{\s*(.*?)\s*\}?\s*$/)
    if (constant) {
      const value = Number(constant[2])
      known.set(constant[1], { value, island: null })
      out.push({ id: `${group}.${constant[1]}`, group, value, island: null, expression: constant[2], doc: docAbove(file.lines, i), source: { file: file.path, line: i + 1 } })
    } else if (branch) {
      const expression = branch[2] || functionBody(file.lines, i)
      const evaluate = (island: boolean) => {
        const picked = pickBranches(expression, islandTest, island)
        const substituted = picked.replace(/(\w+)\(island: island\)/g, (_, name) => String((island ? known.get(name)?.island : known.get(name)?.value) ?? NaN))
          .replace(/\b([a-z]\w*)\b/g, (name) => String(known.get(name)?.value ?? NaN))
        return /^[0-9.+\-*/ ()]+$/.test(substituted) ? Number(Function(`return (${substituted})`)()) : null
      }
      const value = evaluate(false)
      const island = evaluate(true)
      known.set(branch[1], { value, island })
      out.push({ id: `${group}.${branch[1]}`, group, value, island: island === value ? null : island, expression, doc: docAbove(file.lines, i), source: { file: file.path, line: i + 1 } })
      i = blockEnd(file.lines, i)
    }
  }
  return out
}

// MARK: Motion

/** An enum's `Spring(duration:bounce:)` constants and its seconds and numbers (`NotchMotion`, `NotchMascotMotion`). */
export function motionConstants(file: SourceFile, group: string): MotionToken[] {
  const body = enumBody(file, group)
  if (!body) return []
  const out: MotionToken[] = []
  for (let i = body.start + 1; i < body.end; i++) {
    const line = file.lines[i]
    const spring = line.match(/^ {4}static let (\w+) = Spring\(duration:\s*([0-9.]+),\s*bounce:\s*([0-9.]+)\)/)
    const number = line.match(/^ {4}static let (\w+):\s*(TimeInterval|CGFloat|Double)\s*=\s*([0-9.]+)\s*$/)
    const source = { file: file.path, line: i + 1 }
    if (spring) {
      out.push({ id: `${group}.${spring[1]}`, group, kind: 'spring', duration: +spring[2], bounce: +spring[3], value: null, doc: docAbove(file.lines, i), source })
    } else if (number) {
      out.push({ id: `${group}.${number[1]}`, group, kind: number[2] === 'TimeInterval' ? 'seconds' : 'number', duration: null, bounce: null, value: +number[3], doc: docAbove(file.lines, i), source })
    }
  }
  return out
}

// MARK: Palettes

/**
 * Every enum that switches over its cases for a colour (`var light: NotchMascotColor { switch self { case .pearl:
 * return NotchMascotColor(red: …) … } }`): one palette per property.
 */
export function palettes(files: SourceFile[]): PaletteToken[] {
  const out: PaletteToken[] = []
  for (const file of files) {
    for (let i = 0; i < file.lines.length; i++) {
      const owner = file.lines[i].match(/^enum (\w+)\b/)?.[1]
      if (!owner) continue
      const end = blockEnd(file.lines, i)
      for (let j = i + 1; j < end; j++) {
        const property = file.lines[j].match(/^ {4}var (\w+): (\w*Colou?r) \{/)
        if (!property) continue
        const propertyEnd = blockEnd(file.lines, j)
        const entries: PaletteToken['entries'] = []
        for (let k = j + 1; k < propertyEnd; k++) {
          const entry = file.lines[k].match(/^\s+case \.(\w+):\s*return\s+(.+?)\s*$/)
          if (entry) entries.push({ id: entry[1], expression: entry[2], value: parseColor(entry[2], 'dark') })
        }
        if (entries.filter((e) => e.value).length >= 2) {
          out.push({ id: `${owner}.${property[1]}`, group: owner, property: property[1], doc: docAbove(file.lines, j) || docAbove(file.lines, i), entries, source: { file: file.path, line: j + 1 } })
        }
        j = propertyEnd
      }
      i = end
    }
  }
  return out
}
