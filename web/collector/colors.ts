// Swift colour expressions as the site shows them: `Color(red: 0.00, green: 0.44, blue: 0.18)`, `Color.white.opacity(0.68)`,
// `.green` (a system colour, resolved on a Mac by docs/scripts/kit-system-colors.swift into system-colors.json), each in
// the light and the dark appearance. And how far apart two colours look (CIEDE2000), for the inline colours a token
// nearly matches.
import { readFileSync } from 'node:fs'

export type Appearance = 'light' | 'dark'
export type ColorValue = { hex: string; alpha: number }

type SystemColors = { macOS: string; colors: Record<string, Record<Appearance, ColorValue>> }
export const systemColors: SystemColors = JSON.parse(readFileSync(new URL('./system-colors.json', import.meta.url), 'utf8'))

const channel = (value: number) => Math.round(Math.min(1, Math.max(0, value)) * 255).toString(16).padStart(2, '0')
const rgb = (r: number, g: number, b: number) => `#${channel(r)}${channel(g)}${channel(b)}`
const round = (n: number) => Math.round(n * 1000) / 1000

/**
 * One colour expression in an appearance: an RGB or white literal (the app's own `Color(red:…)` and look-alikes such as
 * `NotchMascotColor(red:…)`), a system colour by name, either with `.opacity(…)` after it. Null for anything else
 * (a variable, a computed tint), which the site then shows as code.
 */
export function parseColor(expression: string, appearance: Appearance): ColorValue | null {
  let text = expression.trim().replace(/^return\s+/, '')
  let alpha = 1
  for (;;) {
    const opacity = text.match(/^(.*)\.opacity\(([0-9.]+)\)$/)
    if (!opacity) break
    alpha *= Number(opacity[2])
    text = opacity[1].trim()
  }
  const literal = text.match(/^\w*Colou?r\(\s*red:\s*([0-9.]+),\s*green:\s*([0-9.]+),\s*blue:\s*([0-9.]+)(?:,\s*opacity:\s*([0-9.]+))?\s*\)$/)
  if (literal) return { hex: rgb(+literal[1], +literal[2], +literal[3]), alpha: round(alpha * (literal[4] ? +literal[4] : 1)) }
  const white = text.match(/^Color\(\s*white:\s*([0-9.]+)(?:,\s*opacity:\s*([0-9.]+))?\s*\)$/)
  if (white) return { hex: rgb(+white[1], +white[1], +white[1]), alpha: round(alpha * (white[2] ? +white[2] : 1)) }
  const ns = text.match(/^Color\(nsColor:\s*\.(\w+?)(?:Color)?\)$/)
  const name = ns ? nsNames[ns[1]] ?? ns[1] : text.match(/^(?:Color)?\.(\w+)$/)?.[1]
  const system = name ? systemColors.colors[name] : undefined
  if (system) return { hex: system[appearance].hex, alpha: round(alpha * system[appearance].alpha) }
  return null
}

const nsNames: Record<string, string> = {
  controlAccent: 'accentColor', label: 'primary', secondaryLabel: 'secondary', tertiaryLabel: 'tertiary',
  quaternaryLabel: 'quaternary', systemRed: 'red', systemOrange: 'orange', systemYellow: 'yellow', systemGreen: 'green',
  systemMint: 'mint', systemTeal: 'teal', systemCyan: 'cyan', systemBlue: 'blue', systemIndigo: 'indigo',
  systemPurple: 'purple', systemPink: 'pink', systemBrown: 'brown', systemGray: 'gray', windowBackground: 'windowBackground',
  controlBackground: 'controlBackground', underPageBackground: 'underPageBackground', separator: 'separator',
}

/** `scheme == .light ? A : B` (either order) as its light and dark sides; the expression itself when it doesn't branch. */
export function schemeBranches(expression: string): Record<Appearance, string> {
  const text = expression.trim().replace(/^return\s+/, '')
  const light = text.match(/^\(?\s*(?:scheme|colorScheme)\s*==\s*\.light\s*\)?\s*\?\s*(.+?)\s*:\s*(.+)$/)
  if (light) return { light: light[1], dark: light[2] }
  const dark = text.match(/^\(?\s*(?:scheme|colorScheme)\s*==\s*\.dark\s*\)?\s*\?\s*(.+?)\s*:\s*(.+)$/)
  if (dark) return { light: dark[2], dark: dark[1] }
  return { light: text, dark: text }
}

// MARK: CIEDE2000

type Lab = [number, number, number]

export function hexToLab(hex: string): Lab {
  const value = parseInt(hex.replace('#', ''), 16)
  const [r, g, b] = [(value >> 16) & 255, (value >> 8) & 255, value & 255].map((c) => {
    const s = c / 255
    return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4
  })
  const x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
  const y = r * 0.2126 + g * 0.7152 + b * 0.0722
  const z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
  const f = (t: number) => (t > 0.008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116)
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))]
}

export function deltaE2000(a: Lab, b: Lab): number {
  const [l1, a1, b1] = a
  const [l2, a2, b2] = b
  const rad = Math.PI / 180
  const c1 = Math.hypot(a1, b1), c2 = Math.hypot(a2, b2)
  const cBar = (c1 + c2) / 2
  const g = 0.5 * (1 - Math.sqrt(cBar ** 7 / (cBar ** 7 + 25 ** 7)))
  const a1p = (1 + g) * a1, a2p = (1 + g) * a2
  const c1p = Math.hypot(a1p, b1), c2p = Math.hypot(a2p, b2)
  const h = (x: number, y: number) => (x === 0 && y === 0 ? 0 : ((Math.atan2(y, x) / rad) + 360) % 360)
  const h1p = h(a1p, b1), h2p = h(a2p, b2)
  const dL = l2 - l1, dC = c2p - c1p
  let dh = h2p - h1p
  if (c1p * c2p === 0) dh = 0
  else if (dh > 180) dh -= 360
  else if (dh < -180) dh += 360
  const dH = 2 * Math.sqrt(c1p * c2p) * Math.sin((dh / 2) * rad)
  const lBar = (l1 + l2) / 2, cBarP = (c1p + c2p) / 2
  let hBar = h1p + h2p
  if (c1p * c2p !== 0) hBar = Math.abs(h1p - h2p) > 180 ? (h1p + h2p + (h1p + h2p < 360 ? 360 : -360)) / 2 : (h1p + h2p) / 2
  const t = 1 - 0.17 * Math.cos((hBar - 30) * rad) + 0.24 * Math.cos(2 * hBar * rad) + 0.32 * Math.cos((3 * hBar + 6) * rad)
    - 0.2 * Math.cos((4 * hBar - 63) * rad)
  const sl = 1 + (0.015 * (lBar - 50) ** 2) / Math.sqrt(20 + (lBar - 50) ** 2)
  const sc = 1 + 0.045 * cBarP, sh = 1 + 0.015 * cBarP * t
  const rt = -2 * Math.sqrt(cBarP ** 7 / (cBarP ** 7 + 25 ** 7)) * Math.sin(60 * Math.exp(-(((hBar - 275) / 25) ** 2)) * rad)
  return Math.sqrt((dL / sl) ** 2 + (dC / sc) ** 2 + (dH / sh) ** 2 + rt * (dC / sc) * (dH / sh))
}
