// The app's own Turkish and English copy (Core/Localization.swift's `Strings.enUS`, Core/Localizations/Strings+Turkish.swift's
// `Strings.tr`), so a surface is titled as the app titles it: "Ses mikseri" / "Volume mixer". Only plain string
// properties; the ones built by a function stay out.
import type { SourceFile } from './swift.ts'

export type Localized = { tr: string; en: string }

function table(file: SourceFile | undefined, name: string): Map<string, string> {
  const out = new Map<string, string>()
  if (!file) return out
  const start = file.lines.findIndex((l) => new RegExp(`static let ${name} = Strings\\(`).test(l))
  if (start < 0) return out
  for (let i = start + 1; i < file.lines.length; i++) {
    const line = file.lines[i]
    if (/^ {4}\)/.test(line)) break
    const match = line.match(/^\s+(\w+): "((?:[^"\\]|\\.)*)",?\s*$/)
    if (match) out.set(match[1], match[2].replace(/\\"/g, '"').replace(/\\n/g, ' '))
  }
  return out
}

export function appStrings(files: SourceFile[]) {
  const find = (path: string) => files.find((f) => f.path === path)
  const en = table(find('Sources/Vorssaint/Core/Localization.swift'), 'enUS')
  const tr = table(find('Sources/Vorssaint/Core/Localizations/Strings+Turkish.swift'), 'tr')
  /** A `Strings` key in both languages; null when either is missing. */
  return (key: string): Localized | null => {
    const t = tr.get(key)
    const e = en.get(key)
    return t && e ? { tr: t, en: e } : null
  }
}
