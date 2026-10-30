// Small pieces every page uses: the note that opens a GitHub issue, a source link at the catalog's commit, when the
// renders were taken, where an item is used, a colour swatch, a doc comment, a component's inline-value counts.
import { useEffect, type CSSProperties, type ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'
import type { LiteralKind, Rendered, Usage } from '../../collector/schema.ts'
import { routeFor, useAreaTitle, useCatalog, useT } from '../data.tsx'

/**
 * "Not bırak": opens GitHub's new-issue page on the kit-revize form, filled with what the note is about (the item, the
 * theme and language on screen, the commit, a link back here). The viewer's own GitHub account sends it; the site holds
 * no token. The next collect shows it on the item.
 */
export function NoteButton({ item, variant, label }: { item: string; variant?: string; label?: string }) {
  const { catalog, settings } = useCatalog()
  const t = useT()
  // The issue itself is the owner's, in Turkish (.github/ISSUE_TEMPLATE/kit-revize.yml), whatever the site's language.
  const theme = settings.theme === 'split' ? 'koyu + açık' : settings.theme === 'dark' ? 'koyu' : 'açık'
  const link = `${location.origin}${location.pathname}${variant ? `#${variant}` : location.hash}`
  const params = new URLSearchParams({
    template: 'kit-revize.yml',
    labels: 'kit-revize',
    title: `[BeaconKit™] ${item}${variant ? ` · ${variant}` : ''}: `,
    item,
    variant: variant ?? '',
    context: `${theme} · ${settings.language.toUpperCase()} · ${catalog.meta.sha.slice(0, 7)}`,
    link,
  })
  return (
    <a className="button brand" href={`https://github.com/${catalog.meta.repo}/issues/new?${params}`} target="_blank" rel="noreferrer"
      title={t('GitHub\'da bir revize notu açar (kit-revize)', 'Opens a revision note on GitHub (kit-revize)')}>
      ✎ {label ?? t('Not bırak', 'Leave a note')}
    </a>
  )
}

/** The open notes on an item, each a link to its issue. */
export function Notes({ issues }: { issues: { number: number; title: string; url: string }[] }) {
  const t = useT()
  if (!issues.length) return null
  return (
    <div className="chips">
      {issues.map((issue) => (
        <a key={issue.number} className="badge note warn" href={issue.url} target="_blank" rel="noreferrer" title={issue.title}>
          #{issue.number} {issue.title.replace(/^\[BeaconKit™\]\s*/, '').slice(0, 60)}
        </a>
      ))}
      <span className="muted mono" style={{ fontSize: 11 }}>{t.n(issues.length, 'açık not', 'open note')}</span>
    </div>
  )
}

/** The file at the catalog's commit on GitHub, at a line. */
export function SourceLink({ file, line, children }: { file: string; line?: number | null; children?: ReactNode }) {
  const { catalog } = useCatalog()
  const url = `https://github.com/${catalog.meta.repo}/blob/${catalog.meta.sha}/${file}${line ? `#L${line}` : ''}`
  return <a href={url} target="_blank" rel="noreferrer" className="mono dim">{children ?? `${shortPath(file)}${line ? `:${line}` : ''}`}</a>
}

export const shortPath = (file: string) => file.replace(/^Sources\/Vorssaint\//, '')

/** A link to the page of a token, component or surface id. */
export function ItemLink({ id, children }: { id: string; children?: ReactNode }) {
  const { catalog } = useCatalog()
  return <Link to={routeFor(catalog, id)} className="chip">{children ?? id}</Link>
}

/** When a group of renders was taken and at which commit: a run can publish the site on renders kept from an earlier one. */
export function RenderStamp({ label, render }: { label: string; render: Rendered }) {
  const { catalog } = useCatalog()
  const t = useT()
  if (!render) return <span className="stamp">{label}: <span>{t('henüz çekilmedi', 'not rendered yet')}</span></span>
  const date = t.date(render.at, { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
  return (
    <span className="stamp">
      {label}: {date} ·
      <a href={`https://github.com/${catalog.meta.repo}/commit/${render.sha}`} target="_blank" rel="noreferrer" title={render.sha}>{render.sha.slice(0, 7)}</a>
      {render.sha !== catalog.meta.sha && <span className="badge warn" title={t('Görüntüler sitenin commit\'inden önceki bir commit\'ten', 'The images are from a commit before the site\'s')}>{t('önceki commit', 'earlier commit')}</span>}
    </span>
  )
}

/** How much each area (the menu panel, Settings, the island, …) uses an item. */
export function UsageBars({ usage }: { usage: Usage }) {
  const t = useT()
  const areaTitle = useAreaTitle()
  const entries = Object.entries(usage.byArea).sort((a, b) => b[1] - a[1])
  if (!entries.length) return <p className="muted" style={{ margin: 0, fontSize: 12 }}>{t('Başka yerde kullanılmıyor.', 'Not used anywhere else.')}</p>
  const max = Math.max(...entries.map(([, n]) => n))
  return (
    <div className="bars">
      {entries.map(([area, n]) => (
        <div className="bar" key={area}>
          <span>{areaTitle(area)}</span>
          <span className="track"><span className="fill" style={{ width: `${(n / max) * 100}%` }} /></span>
          <b>{n}</b>
        </div>
      ))}
    </div>
  )
}

/** The places an item is used, each a link to its line. */
export function Places({ usage, limit = 14 }: { usage: Usage; limit?: number }) {
  const t = useT()
  if (!usage.places.length) return null
  return (
    <div className="places">
      {usage.places.slice(0, limit).map((place) => (
        <SourceLink key={`${place.file}:${place.line}`} file={place.file} line={place.line} />
      ))}
      {usage.total > limit && <span className="muted">{t(`… ve ${usage.total - limit} yer daha`, `… and ${usage.total - limit} more`)}</span>}
    </div>
  )
}

/** A colour on its theme's checkerboard, so a translucent one shows what it lets through. */
export function Swatch({ hex, alpha, light = false, small = false }: { hex: string; alpha: number; light?: boolean; small?: boolean }) {
  return (
    <span className={`swatch${light ? ' light' : ''}${small ? ' small' : ''}`} title={`${hex} · ${Math.round(alpha * 100)}%`}>
      <i style={{ background: hex, opacity: alpha }} />
    </span>
  )
}

export const rgba = (value: { hex: string; alpha: number } | null) => {
  if (!value) return 'transparent'
  const v = parseInt(value.hex.slice(1), 16)
  return `rgb(${(v >> 16) & 255} ${(v >> 8) & 255} ${v & 255} / ${value.alpha})`
}

/** WCAG contrast of a colour over another (both opaque hexes). */
export function contrast(a: string, b: string): number {
  const luminance = (hex: string) => {
    const v = parseInt(hex.slice(1), 16)
    const [r, g, bl] = [(v >> 16) & 255, (v >> 8) & 255, v & 255].map((c) => {
      const s = c / 255
      return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4
    })
    return 0.2126 * r + 0.7152 * g + 0.0722 * bl
  }
  const [x, y] = [luminance(a), luminance(b)].sort((m, n) => n - m)
  return (x + 0.05) / (y + 0.05)
}

/** A doc comment as the source writes it: `code` in backticks shows as code. */
export function Doc({ text, className = 'doc', style }: { text: string; className?: string; style?: CSSProperties }) {
  if (!text) return null
  return (
    <div className={className} style={style}>
      {text.split(/(`[^`]+`)/g).map((part, i) => (part.startsWith('`') && part.endsWith('`') ? <code key={i}>{part.slice(1, -1)}</code> : part))}
    </div>
  )
}

export const literalTitles: Record<LiteralKind, { tr: string; en: string }> = {
  radius: { tr: 'Köşe', en: 'Corner' },
  font: { tr: 'Yazı', en: 'Type' },
  padding: { tr: 'Dolgu', en: 'Padding' },
  spacing: { tr: 'Aralık', en: 'Spacing' },
  frame: { tr: 'Boyut', en: 'Frame' },
  shadow: { tr: 'Gölge', en: 'Shadow' },
  animation: { tr: 'Animasyon', en: 'Animation' },
  color: { tr: 'Renk', en: 'Colour' },
  material: { tr: 'Malzeme', en: 'Material' },
}

/** How many inline values of each kind an item writes, each a link to the kind's page. */
export function LiteralChips({ literals }: { literals: Partial<Record<LiteralKind, number>> }) {
  const { settings } = useCatalog()
  const entries = (Object.entries(literals) as [LiteralKind, number][]).sort((a, b) => b[1] - a[1])
  if (!entries.length) return null
  return (
    <div className="chips">
      {entries.map(([kind, n]) => (
        <Link key={kind} className="chip" to={`/degerler/${kind}`}>{literalTitles[kind][settings.language]} <b>{n}</b></Link>
      ))}
    </div>
  )
}

/** Scrolls to the element the URL's hash names once the page has drawn it. */
export function useHashScroll() {
  const { hash, pathname } = useLocation()
  useEffect(() => {
    if (!hash) return
    const id = decodeURIComponent(hash.slice(1))
    const frame = requestAnimationFrame(() => document.getElementById(id)?.scrollIntoView({ block: 'center' }))
    return () => cancelAnimationFrame(frame)
  }, [hash, pathname])
}
