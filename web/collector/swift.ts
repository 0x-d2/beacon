// Reading the Swift sources (docs/beaconkit.md › Collector): doc comments, declarations, the code lines that count as
// uses, and the initialisers a view offers. Line-based on purpose: the app's files follow
// one style (four-space indents, one declaration per line), so a declaration's first line and the `///` block above it
// are enough, and the collector stays a plain script with nothing to build.
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'

export type SourceFile = { path: string; lines: string[] }

/** Every `.swift` file under `folder`, sorted, with paths relative to the repo's root. */
export function readSources(root: string, folder: string): SourceFile[] {
  const files: SourceFile[] = []
  const walk = (dir: string) => {
    for (const name of readdirSync(dir).sort()) {
      const full = join(dir, name)
      if (statSync(full).isDirectory()) walk(full)
      else if (name.endsWith('.swift')) files.push({ path: relative(root, full), lines: readFileSync(full, 'utf8').split('\n') })
    }
  }
  walk(join(root, folder))
  return files
}

/** The `///` block right above `index` (attributes such as `@MainActor` in between), as paragraphs. */
export function docAbove(lines: string[], index: number): string {
  const doc: string[] = []
  for (let i = index - 1; i >= 0; i--) {
    const line = lines[i].trim()
    if (line.startsWith('///')) doc.unshift(line.replace(/^\/\/\/ ?/, ''))
    else if (line.startsWith('@')) continue
    else break
  }
  return paragraphs(doc)
}

/** Doc lines joined into paragraphs (a blank `///` starts one; `- ` lines stay lines). */
function paragraphs(doc: string[]): string {
  const out: string[] = []
  for (const line of doc) {
    if (line === '') out.push('')
    else if (out.length === 0 || out[out.length - 1] === '' || /^\s*-\s/.test(line)) out.push(line)
    else out[out.length - 1] += ' ' + line.trim()
  }
  return out.join('\n').replace(/\n{2,}/g, '\n\n').trim()
}

export function count(text: string, char: string): number {
  return text.split(char).length - 1
}

/** Code lines only: `//` and `///` comments don't count as uses or as inline values. */
export function codeLines(file: SourceFile): { text: string; line: number }[] {
  const out: { text: string; line: number }[] = []
  let block = false
  for (let i = 0; i < file.lines.length; i++) {
    const text = file.lines[i]
    const trimmed = text.trim()
    if (block) {
      if (trimmed.includes('*/')) block = false
      continue
    }
    if (trimmed.startsWith('/*')) {
      block = !trimmed.includes('*/')
      continue
    }
    if (trimmed.startsWith('//')) continue
    out.push({ text: text.replace(/\s\/\/(?!\/).*$/, ''), line: i + 1 })
  }
  return out
}

/** A line without its string literals' text: a type's name in a sentence isn't a use of it. */
export function withoutStrings(text: string): string {
  return text.replace(/"(?:[^"\\]|\\.)*"/g, '""')
}

/** The line where the brace opened on `start` closes (the declaration's body), or the file's last line. */
export function blockEnd(lines: string[], start: number): number {
  let depth = 0
  let opened = false
  for (let i = start; i < lines.length; i++) {
    const text = withoutStrings(lines[i].replace(/\/\/.*$/, ''))
    depth += count(text, '{') - count(text, '}')
    if (count(text, '{') > 0) opened = true
    if (opened && depth <= 0) return i
  }
  return lines.length - 1
}

/** A top-level type: its kind, name, generic clause and conformances, as its first line writes them. */
export type Declaration = { kind: string; name: string; conformances: string[]; line: number; access: string }

const declarationLine = /^(?:@\w+(?:\([^)]*\))?\s+)*(?:(public|internal|private|fileprivate)\s+)?(?:final\s+)?(struct|enum|class|actor|protocol)\s+(\w+)(?:<[^{]*?>)?\s*(?::\s*([^{]+?))?\s*(?:where [^{]+)?\{?\s*$/

/** The file's top-level types (nested ones aside: four spaces in, they belong to their owner). */
export function declarations(file: SourceFile): Declaration[] {
  const out: Declaration[] = []
  for (let i = 0; i < file.lines.length; i++) {
    const match = file.lines[i].match(declarationLine)
    if (!match) continue
    out.push({
      access: match[1] ?? 'internal',
      kind: match[2],
      name: match[3],
      conformances: (match[4] ?? '').split(',').map((c) => c.trim()).filter(Boolean),
      line: i + 1,
    })
  }
  return out
}

/** `func name(` declared inside an `extension View {` (or `extension Shape`, `extension Text`), with its doc. */
export function viewModifiers(file: SourceFile): { name: string; signature: string; doc: string; line: number; on: string }[] {
  const out: { name: string; signature: string; doc: string; line: number; on: string }[] = []
  for (let i = 0; i < file.lines.length; i++) {
    const on = file.lines[i].match(/^extension (View|Shape|Text|Image)\b[^{]*\{/)?.[1]
    if (!on) continue
    const end = blockEnd(file.lines, i)
    for (let j = i + 1; j < end; j++) {
      const match = file.lines[j].match(/^ {4}(?:@\w+\s+)*(?:public\s+)?func (\w+)(?:<[^>]*>)?\(/)
      if (!match) continue
      out.push({ name: match[1], signature: signatureAt(file.lines, j), doc: docAbove(file.lines, j), line: j + 1, on })
    }
    i = end
  }
  return out
}

/** A declaration's signature as written, its lines joined and whitespace folded, without the body's brace. */
export function signatureAt(lines: string[], index: number): string {
  let signature = lines[index].trim()
  let depth = count(signature, '(') - count(signature, ')')
  let j = index
  while ((depth > 0 || !/[{]\s*$/.test(signature)) && j + 1 < lines.length && j - index < 12) {
    j++
    signature += ' ' + lines[j].trim()
    depth += count(lines[j], '(') - count(lines[j], ')')
  }
  return signature.replace(/\s*\{.*$/, '').replace(/\s+/g, ' ').replace(/^(?:@\w+\s+)+/, '')
}

/**
 * The public face of a type: its initialisers, or the memberwise one Swift writes for a struct without an `init`
 * (`SettingsCard(title:icon:content:)`), in file order.
 */
export function initialisers(file: SourceFile, declaration: Declaration): { signature: string; doc: string; line: number }[] {
  const start = declaration.line - 1
  const end = blockEnd(file.lines, start)
  const out: { signature: string; doc: string; line: number }[] = []
  for (let i = start + 1; i < end; i++) {
    const line = file.lines[i]
    if (/^ {4}(?:@\w+\s+)*(?:public\s+|internal\s+)?(?:convenience\s+)?init[<(?]/.test(line) && !/^ {4}(?:private|fileprivate)/.test(line)) {
      out.push({ signature: `${declaration.name}${signatureAt(file.lines, i).replace(/^.*?init/, '')}`, doc: docAbove(file.lines, i), line: i + 1 })
    }
  }
  if (out.length || declaration.kind !== 'struct') return out
  const memberwise = memberwiseInit(file.lines, start, end)
  return memberwise ? [{ signature: `${declaration.name}(${memberwise})`, doc: '', line: declaration.line }] : []
}

/** A struct's stored properties in order, private and environment ones aside, a default where the source has one. */
function memberwiseInit(lines: string[], start: number, end: number): string | null {
  const parameters: string[] = []
  let depth = 0
  for (let i = start; i <= end; i++) {
    const line = lines[i]
    if (depth === 1) {
      const binding = line.match(/^ {4}@Binding var (\w+): (.+?)\s*$/)
      const viewBuilder = line.match(/^ {4}@ViewBuilder (?:let|var) (\w+): (.+?)\s*$/)
      const stored = line.match(/^ {4}(?:let|var) (\w+): ([^={]+?)(?:\s*=\s*(.+?))?\s*$/)
      const inferred = line.match(/^ {4}var (\w+) = (.+?)\s*$/)
      if (binding) parameters.push(`${binding[1]}: Binding<${binding[2]}>`)
      else if (viewBuilder) parameters.push(`@ViewBuilder ${viewBuilder[1]}: ${viewBuilder[2]}`)
      else if (inferred && !stored) parameters.push(`${inferred[1]} = ${inferred[2]}`)
      else if (stored && !/^ {4}(private|fileprivate|static|@)/.test(line)) {
        const optional = stored[2].trim().endsWith('?') && !stored[3]
        if (!(line.trim().startsWith('let') && stored[3])) {
          parameters.push(`${stored[1]}: ${stored[2].trim()}${stored[3] ? ` = ${stored[3]}` : optional ? ' = nil' : ''}`)
        }
      }
    }
    const text = withoutStrings(line)
    depth += count(text, '{') - count(text, '}')
    if (i > start && depth <= 0) break
  }
  return parameters.length ? parameters.join(', ') : null
}

/** The doc above a declaration, else the file's first `///` block above a top-level declaration. */
export function declarationDoc(file: SourceFile, line: number): string {
  return docAbove(file.lines, line - 1)
}

/**
 * The private types a stretch of code reaches in its own file (`.panelCard()` → `PanelCardModifier`,
 * `.panelGlassSurface()` → `PanelGlassSurface`), two levels deep: what they draw is the component's look.
 */
export function withPrivateHelpers(file: SourceFile, range: [number, number]): [number, number][] {
  const helpers = new Map<string, [number, number]>()
  for (const declaration of declarations(file)) {
    if (declaration.access !== 'private' && declaration.access !== 'fileprivate') continue
    helpers.set(declaration.name, [declaration.line - 1, blockEnd(file.lines, declaration.line - 1)])
  }
  const ranges: [number, number][] = [range]
  const seen = new Set<string>()
  for (let depth = 0; depth < 2; depth++) {
    for (const [start, end] of [...ranges]) {
      for (let i = start; i <= end; i++) {
        for (const m of withoutStrings(file.lines[i]).matchAll(/(?<![.\w])([A-Z]\w+)\b/g)) {
          const helper = helpers.get(m[1])
          if (helper && !seen.has(m[1])) {
            seen.add(m[1])
            ranges.push(helper)
          }
        }
      }
    }
  }
  return ranges
}

/**
 * The area a file draws on, for "where it's used": the menu panel, Settings, the Dynamic Island, onboarding, one of the
 * floating tools (by folder), the menu bar, or the app's shared code.
 */
export function area(path: string): string {
  const ui = path.match(/^Sources\/Vorssaint\/UI\/(\w+)\//)?.[1]
  if (ui === 'MenuPanel') return 'panel'
  if (ui === 'Settings') return 'settings'
  if (ui === 'Notch') return 'notch'
  if (ui === 'Onboarding') return 'onboarding'
  if (ui) return 'tools'
  if (path.startsWith('Sources/Vorssaint/Services/Notch/')) return 'notch'
  if (path.startsWith('Sources/Vorssaint/App/')) return 'app'
  if (path.startsWith('Sources/Vorssaint/UI/')) return 'shared'
  return 'services'
}

export const areaTitles: Record<string, { tr: string; en: string }> = {
  panel: { tr: 'Menü paneli', en: 'Menu panel' },
  settings: { tr: 'Ayarlar', en: 'Settings' },
  notch: { tr: 'Dynamic Island', en: 'Dynamic Island' },
  onboarding: { tr: 'Karşılama', en: 'Onboarding' },
  tools: { tr: 'Yüzen araçlar', en: 'Floating tools' },
  app: { tr: 'Menü çubuğu ve pencereler', en: 'Menu bar and windows' },
  shared: { tr: 'Ortak arayüz', en: 'Shared UI' },
  services: { tr: 'Servisler', en: 'Services' },
}
