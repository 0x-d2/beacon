// ⌘K: everything the catalog has, by name — components, tokens, surfaces, the guide's entries and the inline values.
import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { routeFor, useCatalog, useT, useText } from '../data.tsx'

type Hit = { kind: 'component' | 'surface' | 'guide' | 'color' | 'text' | 'metric' | 'motion' | 'value'; label: string; hint: string; to: string }

export function SearchPalette({ onClose }: { onClose: () => void }) {
  const { catalog } = useCatalog()
  const text = useText()
  const t = useT()
  const kinds = useMemo<Record<Hit['kind'], string>>(() => ({
    component: t('Bileşen', 'Component'), surface: t('Yüzey', 'Surface'), guide: t('Rehber', 'Guide'), color: t('Renk', 'Colour'),
    text: t('Yazı', 'Text'), metric: t('Ölçü', 'Metric'), motion: t('Hareket', 'Motion'), value: t('Değer', 'Value'),
  }), [t])
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [cursor, setCursor] = useState(0)
  const input = useRef<HTMLInputElement>(null)
  useEffect(() => { input.current?.focus() }, [])

  const all = useMemo<Hit[]>(() => [
    ...catalog.components.map((c) => ({ kind: 'component' as const, label: c.id, hint: c.source.file.replace('Sources/Vorssaint/', ''), to: routeFor(catalog, c.id) })),
    ...catalog.surfaces.map((s) => ({ kind: 'surface' as const, label: text(s.title), hint: s.view, to: routeFor(catalog, s.id) })),
    ...catalog.guide.map((g) => ({ kind: 'guide' as const, label: text(g.what), hint: g.file.split('/').pop() ?? '', to: `/nereden#${g.id}` })),
    ...catalog.tokens.colors.map((c) => ({ kind: 'color' as const, label: c.id, hint: c.values.dark?.hex ?? '', to: `/renkler#${c.id}` })),
    ...catalog.tokens.gradients.map((c) => ({ kind: 'color' as const, label: c.id, hint: c.direction, to: `/renkler#${c.id}` })),
    ...catalog.tokens.textStyles.map((s) => ({ kind: 'text' as const, label: s.id, hint: `${s.size} pt ${s.weight}`, to: `/tipografi#${s.id}` })),
    ...catalog.tokens.metrics.map((m) => ({ kind: 'metric' as const, label: m.id, hint: String(m.value), to: `/olculer#${m.id}` })),
    ...catalog.tokens.landmarks.map((m) => ({ kind: 'metric' as const, label: text(m.title), hint: String(m.value), to: `/olculer#${m.id}` })),
    ...catalog.tokens.motions.map((m) => ({ kind: 'motion' as const, label: m.id, hint: m.kind, to: `/hareket#${m.id}` })),
    ...(Object.entries(catalog.literals) as [string, typeof catalog.literals.radius][]).flatMap(([kind, groups]) =>
      groups.slice(0, 60).map((g) => ({ kind: 'value' as const, label: `${kind} ${g.key}`, hint: t.n(g.count, 'yer', 'place'), to: `/degerler/${kind}?deger=${encodeURIComponent(g.key)}` }))),
  ], [catalog, text, t])

  const hits = useMemo(() => {
    const words = query.toLocaleLowerCase(t.language).split(/\s+/).filter(Boolean)
    if (!words.length) return all.filter((h) => h.kind === 'guide' || h.kind === 'surface').slice(0, 40)
    // Within each kind, the name typed in full first, then the names it starts ("row": Row…, then SettingsRow).
    const typed = words.join(' ')
    const rank = (h: Hit) => {
      const names = [h.label, h.hint].map((n) => n.toLocaleLowerCase(t.language))
      return names.includes(typed) ? 0 : names.some((n) => n.startsWith(typed)) ? 1 : 2
    }
    const kindOrder = Object.keys(kinds)
    return all.filter((h) => words.every((w) => `${h.label} ${h.hint} ${kinds[h.kind]}`.toLocaleLowerCase(t.language).includes(w)))
      .sort((a, b) => kindOrder.indexOf(a.kind) - kindOrder.indexOf(b.kind) || rank(a) - rank(b))
      .slice(0, 60)
  }, [all, query, kinds, t.language])

  const go = (hit: Hit | undefined) => {
    if (!hit) return
    navigate(hit.to)
    onClose()
  }

  return (
    <div className="palette-backdrop" onMouseDown={onClose}>
      <div className="palette" role="dialog" aria-label={t('Ara', 'Search')} onMouseDown={(e) => e.stopPropagation()}>
        <input ref={input} value={query} placeholder={t('Ara: SettingsCard, cardFill, Sistem, radius 8…', 'Search: SettingsCard, cardFill, System, radius 8…')}
          onChange={(e) => { setQuery(e.target.value); setCursor(0) }}
          onKeyDown={(e) => {
            if (e.key === 'Escape') onClose()
            if (e.key === 'ArrowDown') { e.preventDefault(); setCursor((c) => Math.min(c + 1, hits.length - 1)) }
            if (e.key === 'ArrowUp') { e.preventDefault(); setCursor((c) => Math.max(c - 1, 0)) }
            if (e.key === 'Enter') go(hits[cursor])
          }} />
        <ul>
          {hits.map((hit, index) => (
            <li key={`${hit.kind}${hit.to}${hit.label}`}>
              <a className={index === cursor ? 'on' : ''} onMouseEnter={() => setCursor(index)} onClick={() => go(hit)}>
                <span className="kind">{kinds[hit.kind]}</span>{hit.label}<span className="hint">{hit.hint}</span>
              </a>
            </li>
          ))}
          {!hits.length && <li className="muted" style={{ padding: 14 }}>{t('Sonuç yok.', 'No results.')}</li>}
        </ul>
      </div>
    </div>
  )
}
