import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useAreaTitle, useCatalog, useT, useText } from '../data.tsx'
import { Segmented } from '../ui/Layout.tsx'
import { Doc, LiteralChips, shortPath } from '../ui/bits.tsx'
import { Thumb } from '../ui/Stage.tsx'

const kindTitles = {
  view: { tr: 'view', en: 'view' }, modifier: { tr: 'modifier', en: 'modifier' }, style: { tr: 'stil', en: 'style' },
  shape: { tr: 'şekil', en: 'shape' }, representable: { tr: 'AppKit', en: 'AppKit' },
}

/** The components (collector/components.ts), all or a category, as cards or as a list. */
export function Components() {
  const { catalog, settings, set } = useCatalog()
  const text = useText()
  const t = useT()
  const areaTitle = useAreaTitle()
  const { category } = useParams()
  const [query, setQuery] = useState('')
  const current = catalog.categories.find((c) => c.id === category)
  const items = catalog.components
    .filter((c) => !category || c.category === category)
    .filter((c) => !query || `${c.id} ${c.source.file} ${c.doc}`.toLocaleLowerCase(t.language).includes(query.toLocaleLowerCase(t.language)))

  return (
    <div className="page">
      <div className="eyebrow"><Link to="/bilesenler">{t('Bileşenler', 'Components')}</Link>{current ? ` · ${text(current.title)}` : ''}</div>
      <h1 className="title">{current ? text(current.title) : t('Bileşenler', 'Components')}</h1>
      <p className="lede">{t(
        'Uygulamada birden çok yerde kullanılan view\'lar, modifier\'lar ve stiller. Uygulamanın bir bileşen kütüphanesi yok; liste koddan çıkarılır: başka en az iki dosyanın kullandığı, ya da Theme.swift, SharedUI.swift, SettingsCard.swift gibi ortak dosyalarda tanımlı olan her şey.',
        'The views, modifiers and styles used in more than one place. The app has no component library; the list is worked out from the code: anything at least two other files use, or that a shared file such as Theme.swift, SharedUI.swift or SettingsCard.swift declares.',
      )}</p>
      <div className="filter" style={{ marginTop: 24 }}>
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder={t('Süz: ad, dosya, açıklama', 'Filter: name, file, description')} />
        <span className="spacer" />
        <Segmented value={settings.componentView} onChange={(componentView) => set({ componentView })}
          options={[['grid', t('Izgara', 'Grid')], ['list', t('Liste', 'List')]]} />
      </div>
      {settings.componentView === 'grid' ? (
        <div className="grid cols-3">
          {items.map((c) => (
            <Link key={c.id} to={`/bilesen/${encodeURIComponent(c.id)}`} className="card">
              <Thumb images={c.variants[0]?.images} title={c.id} subtitle={shortPath(c.source.file)} />
              <div className="body">
                <b>{c.id}</b>
                <span>{kindTitles[c.kind][settings.language]} · {t.n(c.usage.total, 'kullanım', 'use')} · {t.n(c.usage.files, 'dosya', 'file')}{c.variants.length ? ` · ${t.n(c.variants.length, 'hâl', 'variant')}` : ''}</span>
                <Doc text={c.doc} />
              </div>
              {c.issues.length > 0 && <div className="foot"><span className="badge warn">{t.n(c.issues.length, 'not', 'note')}</span></div>}
            </Link>
          ))}
        </div>
      ) : (
        <div className="panel">
          <table className="table">
            <thead><tr><th>{t('Bileşen', 'Component')}</th><th>{t('Dosya', 'File')}</th><th className="num">{t('Kullanım', 'Uses')}</th><th>{t('Nerede', 'Where')}</th><th>{t('Satır içi değerler', 'Inline values')}</th><th className="num">{t('Son değişiklik', 'Last change')}</th></tr></thead>
            <tbody>
              {items.map((c) => (
                <tr key={c.id}>
                  <td style={{ maxWidth: 360 }}>
                    <Link to={`/bilesen/${encodeURIComponent(c.id)}`}><b style={{ fontWeight: 600 }}>{c.id}</b></Link>
                    <Doc text={c.doc.split('. ')[0]} style={{ fontSize: 12, marginTop: 2 }} />
                  </td>
                  <td className="mono muted">{shortPath(c.source.file)}</td>
                  <td className="num">{c.usage.total}</td>
                  <td className="dim" style={{ fontSize: 12 }}>{Object.entries(c.usage.byArea).sort((a, b) => b[1] - a[1]).map(([area]) => areaTitle(area)).join(', ')}</td>
                  <td><LiteralChips literals={c.literals} /></td>
                  <td className="num muted">{t.since(c.lastChange)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {!items.length && <p className="muted">{t('Bu süzgece uyan bileşen yok.', 'No component matches this filter.')}</p>}
    </div>
  )
}
