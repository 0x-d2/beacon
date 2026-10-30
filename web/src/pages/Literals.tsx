import { useMemo, useState } from 'react'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import type { LiteralGroup, LiteralKind } from '../../collector/schema.ts'
import { routeFor, useCatalog, useT } from '../data.tsx'
import { literalTitles, rgba, shortPath } from '../ui/bits.tsx'

const kinds: LiteralKind[] = ['radius', 'font', 'padding', 'spacing', 'frame', 'shadow', 'animation', 'color', 'material']

const notes: Record<LiteralKind, { tr: string; en: string }> = {
  radius: { tr: 'cornerRadius: ve .cornerRadius(…). Neredeyse hepsi style: .continuous.', en: 'cornerRadius: and .cornerRadius(…). Nearly all style: .continuous.' },
  font: { tr: '.system(size:weight:design:) ve macOS metin stilleri (.caption…).', en: '.system(size:weight:design:) and macOS\'s text styles (.caption…).' },
  padding: { tr: '.padding(n) ve .padding(.kenar, n).', en: '.padding(n) and .padding(.edge, n).' },
  spacing: { tr: 'Yığınların ve ızgaraların spacing:\'i.', en: 'Stacks\' and grids\' spacing:.' },
  frame: { tr: '.frame(width:height:…) içindeki sabit boyutlar.', en: 'The fixed sizes inside .frame(width:height:…).' },
  shadow: { tr: '.shadow(color:radius:x:y:), yarıçapa göre.', en: '.shadow(color:radius:x:y:), by radius.' },
  animation: { tr: '.animation(…) ve withAnimation(…) içindeki eğriler.', en: 'The curves inside .animation(…) and withAnimation(…).' },
  color: { tr: 'Token yerine yazılan renkler; bir token\'a ΔE 2\'den yakın olanlar işaretli.', en: 'Colours typed in place of a token; those within ΔE 2 of one are marked.' },
  material: { tr: 'SwiftUI malzemeleri, Liquid Glass ve NSVisualEffectView.', en: 'SwiftUI materials, Liquid Glass and NSVisualEffectView.' },
}

/**
 * Satır içi değerler: every value the views type in place, by kind, grouped by value with every place it's written. The
 * histogram shows how the numbers spread (seven radii between 6 and 12 say "a token is missing" better than a table).
 */
export function Literals() {
  const { catalog, settings } = useCatalog()
  const t = useT()
  const { kind: param } = useParams()
  const kind = (kinds.includes(param as LiteralKind) ? param : 'radius') as LiteralKind
  const [search, setSearch] = useSearchParams()
  const selected = search.get('deger')
  const [query, setQuery] = useState('')
  const groups = catalog.literals[kind]
  const total = groups.reduce((n, g) => n + g.count, 0)
  const filtered = useMemo(() => {
    const q = query.toLocaleLowerCase(t.language)
    return q ? groups.filter((g) => g.key.toLocaleLowerCase(t.language).includes(q) || g.places.some((p) => p.file.toLocaleLowerCase().includes(q))) : groups
  }, [groups, query, t.language])
  const numeric = groups.filter((g) => g.value !== null)
  const toggle = (key: string) => setSearch(selected === key ? {} : { deger: key }, { replace: true })

  return (
    <div className="page">
      <div className="eyebrow">{t('İnceleme', 'Review')}</div>
      <h1 className="title">{t('Satır içi değerler', 'Inline values')}</h1>
      <p className="lede">{t(
        'View\'lara token yerine doğrudan yazılmış her değer, türüne ve değerine göre, yazıldığı her yerle. Bir değeri toptan değiştirmek ya da bir token\'a çevirmek bu listeden başlar.',
        'Every value typed into the views in place of a token, by kind and value, with every place it\'s written. Changing a value across the app, or turning it into a token, starts from this list.',
      )}</p>
      <div className="tabs">
        {kinds.map((k) => (
          <Link key={k} to={`/degerler/${k}`} className={k === kind ? 'on' : ''}>
            {literalTitles[k][settings.language]} <span className="count">{catalog.literals[k].reduce((n, g) => n + g.count, 0)}</span>
          </Link>
        ))}
      </div>
      <p className="section-note">{notes[kind][settings.language]} {t(`${t.n(groups.length, 'farklı değer', 'distinct value')}, ${total} yer.`, `${t.n(groups.length, 'farklı değer', 'distinct value')}, ${total} places.`)}</p>

      {numeric.length > 3 && kind !== 'font' && kind !== 'animation' && kind !== 'shadow' && <Histogram groups={numeric} selected={selected} onSelect={toggle} />}

      <div className="filter" style={{ marginTop: 18 }}>
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder={t('Süz: değer ya da dosya (ör. 8, Settings)', 'Filter: value or file (e.g. 8, Settings)')} />
        {selected && <button className="button" onClick={() => setSearch({}, { replace: true })}>✕ {selected}</button>}
      </div>
      <div className="panel">
        <table className="table">
          <thead><tr><th>{t('Değer', 'Value')}</th><th className="num">{t('Yer', 'Places')}</th><th className="num">{t('Dosya', 'Files')}</th><th>{t('Token', 'Token')}</th></tr></thead>
          <tbody>
            {filtered.map((g) => (
              <Row key={g.key} kind={kind} group={g} open={selected === g.key} onToggle={() => toggle(g.key)} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function Row({ kind, group, open, onToggle }: { kind: LiteralKind; group: LiteralGroup; open: boolean; onToggle: () => void }) {
  const { catalog } = useCatalog()
  const t = useT()
  return (
    <>
      <tr id={group.key} onClick={onToggle} style={{ cursor: 'pointer' }}>
        <td>
          <span className="pair">
            {kind === 'radius' && <span className="radius-demo" style={{ borderRadius: Math.min(group.value ?? 0, 12) }} />}
            {kind === 'color' && group.color && (
              <>
                <span className="swatch small light"><i style={{ background: rgba(group.color.light) }} /></span>
                <span className="swatch small"><i style={{ background: rgba(group.color.dark) }} /></span>
              </>
            )}
            <span className="literal-key">{open ? '▾' : '▸'} {group.key}</span>
          </span>
        </td>
        <td className="num">{group.count}</td>
        <td className="num muted">{group.files}</td>
        <td>{group.match ? <Link className="badge brand" to={routeFor(catalog, group.match.token)} title={group.match.note[t.language]} onClick={(e) => e.stopPropagation()}>{group.match.token}</Link> : null}</td>
      </tr>
      {open && (
        <tr>
          <td colSpan={4} style={{ paddingTop: 0 }}>
            {group.match && <p className="muted" style={{ margin: '0 0 6px', fontSize: 12 }}>{group.match.note[t.language]}</p>}
            <div className="place-list">
              {group.places.map((p) => (
                <a key={`${p.file}:${p.line}`} href={`https://github.com/${catalog.meta.repo}/blob/${catalog.meta.sha}/${p.file}#L${p.line}`} target="_blank" rel="noreferrer">
                  <span>{shortPath(p.file)}:{p.line}</span><span className="code">{p.code}</span>
                </a>
              ))}
            </div>
          </td>
        </tr>
      )}
    </>
  )
}

function Histogram({ groups, selected, onSelect }: { groups: LiteralGroup[]; selected: string | null; onSelect: (key: string) => void }) {
  // One column per value (the keys that share a value, `12 · .horizontal` and `12`, sum), smallest first.
  const byValue = new Map<number, { count: number; key: string }>()
  for (const g of groups) {
    const entry = byValue.get(g.value!) ?? { count: 0, key: g.key }
    entry.count += g.count
    byValue.set(g.value!, entry)
  }
  const columns = [...byValue.entries()].sort((a, b) => a[0] - b[0]).slice(0, 48)
  const max = Math.max(...columns.map(([, c]) => c.count))
  return (
    <div className="panel">
      <div className="histogram">
        {columns.map(([value, c]) => (
          <div key={value} className={`col${selected === c.key ? ' on' : ''}`} title={`${value}: ${c.count}`} onClick={() => onSelect(c.key)}>
            <i style={{ height: `${Math.max(2, (c.count / max) * 100)}%` }} />
          </div>
        ))}
      </div>
      <div className="histogram-axis">{columns.map(([value]) => <span key={value}>{value}</span>)}</div>
    </div>
  )
}
