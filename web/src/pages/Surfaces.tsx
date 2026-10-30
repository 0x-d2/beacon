import { Link, useParams } from 'react-router-dom'
import { useCatalog, useT, useText } from '../data.tsx'
import { shortPath } from '../ui/bits.tsx'
import { Thumb } from '../ui/Stage.tsx'

/** The surfaces (collector/surfaces.ts) of a group, or every group: each with its view, file and what it's built from. */
export function Surfaces() {
  const { catalog } = useCatalog()
  const text = useText()
  const t = useT()
  const { group } = useParams()
  const groups = catalog.surfaceGroups.filter((g) => !group || g.id === group)

  return (
    <div className="page">
      <div className="eyebrow"><Link to="/yuzeyler">{t('Yüzeyler', 'Surfaces')}</Link></div>
      <h1 className="title">{group ? text(catalog.surfaceGroups.find((g) => g.id === group)?.title) : t('Yüzeyler', 'Surfaces')}</h1>
      <p className="lede">{t(
        'Uygulamanın bütün olarak çizdiği yerler: menü panelinin sekmeleri, Ayarlar sayfaları, Dynamic Island modülleri, pencereler. Her biri onu çizen view ve dosyayla; içindeki bileşenler ve satır içi değerler sayfasında.',
        'The places the app draws whole: the menu panel\'s tabs, the Settings pages, the Dynamic Island\'s modules, the windows. Each with the view and file that draw it; its components and inline values are on its page.',
      )}</p>
      {groups.map((g) => (
        <div key={g.id}>
          <h2 className="section">{text(g.title)} <span className="count">{catalog.surfaces.filter((s) => s.group === g.id).length}</span></h2>
          <div className="grid cols-3">
            {catalog.surfaces.filter((s) => s.group === g.id).map((s) => {
              const components = Object.keys(s.components).length
              const literals = Object.values(s.literals).reduce((n, v) => n + (v ?? 0), 0)
              return (
                <Link key={s.id} to={`/yuzey/${encodeURIComponent(s.id)}`} className="card">
                  <Thumb images={s.images} title={text(s.title)} subtitle={s.view} />
                  <div className="body">
                    <b>{text(s.title)}</b>
                    <span>{s.view} · {shortPath(s.source.file)}</span>
                    <span>{t.n(components, 'bileşen', 'component')} · {t.n(literals, 'satır içi değer', 'inline value')}</span>
                  </div>
                  {s.issues.length > 0 && <div className="foot"><span className="badge warn">{t.n(s.issues.length, 'not', 'note')}</span></div>}
                </Link>
              )
            })}
          </div>
        </div>
      ))}
    </div>
  )
}
