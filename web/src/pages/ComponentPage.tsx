import { Link, useParams } from 'react-router-dom'
import { routeFor, useCatalog, useT, useText } from '../data.tsx'
import { Doc, ItemLink, LiteralChips, NoteButton, Notes, Places, shortPath, SourceLink, UsageBars, useHashScroll } from '../ui/bits.tsx'
import { Stage } from '../ui/Stage.tsx'

/** One component: its doc, every variant's render, where it's used, and in the rail its API, what it draws with, its source. */
export function ComponentPage() {
  const { catalog, component } = useCatalog()
  const text = useText()
  const t = useT()
  useHashScroll()
  const { id = '' } = useParams()
  const c = component(decodeURIComponent(id))
  if (!c) return <div className="page"><h1 className="title">{t('Bileşen yok', 'No such component')}</h1><Link className="button" to="/bilesenler">← {t('Bileşenler', 'Components')}</Link></div>
  const category = catalog.categories.find((x) => x.id === c.category)

  return (
    <div className="page">
      <div className="eyebrow"><Link to="/bilesenler">{t('Bileşenler', 'Components')}</Link> · <Link to={`/bilesenler/${c.category}`}>{text(category?.title)}</Link></div>
      <h1 className="title">{c.id}</h1>
      <Doc text={c.doc || t('Kaynakta açıklama yok.', 'No doc comment in the source.')} className="lede" />
      <div className="chips" style={{ marginTop: 14 }}>
        <SourceLink file={c.source.file} line={c.source.line} />
        <span className="chip">{t.n(c.usage.total, 'kullanım', 'use')} · {t.n(c.usage.files, 'dosya', 'file')}</span>
        <span className="chip">{t('Son değişiklik', 'Last change')}: {t.since(c.lastChange)}</span>
        <NoteButton item={c.id} />
      </div>
      <div style={{ marginTop: 10 }}><Notes issues={c.issues} /></div>

      <div className="detail">
        <div>
          <h3 className="sub" style={{ marginTop: 0 }}>{t('Hâller', 'Variants')} <span className="muted">{c.variants.length || ''}</span></h3>
          {c.variants.length === 0 && (
            <div className="missing" style={{ justifyItems: 'start', textAlign: 'left' }}>
              {t('Bu bileşenin henüz bir specimen\'ı yok, o yüzden görüntüsü de yok.', 'This component has no specimen yet, so no image either.')}<br />
              {t('Eklemek için: Sources/Vorssaint/Kit/Specimens/ (docs/beaconkit.md › Renders).', 'To add one: Sources/Vorssaint/Kit/Specimens/ (docs/beaconkit.md › Renders).')}
            </div>
          )}
          {c.variants.map((v) => (
            <div className="variant" key={v.id} id={v.id}>
              <div className="variant-head">
                <code>{v.title}</code><span className="id mono">{v.id}</span>
                {v.capture === 'imageRenderer' && <span className="badge" title={t('ImageRenderer ile çizildi: malzemeler ve AppKit kontrolleri yok', 'Drawn with ImageRenderer: no materials or AppKit controls')}>ImageRenderer</span>}
                <span className="actions"><NoteButton item={c.id} variant={v.id} label={t('Not', 'Note')} /></span>
              </div>
              <Stage images={v.images} title={v.title} />
            </div>
          ))}

          <h3 className="sub">{t('Nerede kullanılıyor', 'Where it\'s used')}</h3>
          <div className="panel padded"><UsageBars usage={c.usage} /></div>
          {c.usedBy.length > 0 && (
            <>
              <h3 className="sub">{t('Kullanan bileşenler ve yüzeyler', 'Components and surfaces that use it')}</h3>
              <div className="chips">{c.usedBy.map((u) => <ItemLink key={u} id={u}>{catalog.surfaces.find((s) => s.id === u) ? text(catalog.surfaces.find((s) => s.id === u)!.title) : u}</ItemLink>)}</div>
            </>
          )}
          <h3 className="sub">{t('Yerler', 'Places')}</h3>
          <Places usage={c.usage} limit={40} />
        </div>

        <aside className="rail">
          <div>
            <h4>API</h4>
            {c.api.length ? c.api.map((a) => (
              <div className="signature" key={a.line}>
                {a.signature}
                {a.doc && <div className="small-doc">{a.doc}</div>}
              </div>
            )) : <p className="muted" style={{ fontSize: 12, margin: 0 }}>{t('Açık bir init yok.', 'No public initialiser.')}</p>}
          </div>
          <div>
            <h4>{t('Kullandığı token\'lar', 'Tokens it uses')}</h4>
            {c.uses.tokens.length ? <div className="chips">{c.uses.tokens.map((x) => <Link key={x} className="chip" to={routeFor(catalog, x)}>{x}</Link>)}</div> : <p className="muted" style={{ fontSize: 12, margin: 0 }}>{t('Hiçbiri: değerleri satır içinde.', 'None: its values are inline.')}</p>}
          </div>
          {c.uses.components.length > 0 && (
            <div>
              <h4>{t('İçindeki bileşenler', 'Components inside')}</h4>
              <div className="chips">{c.uses.components.map((x) => <ItemLink key={x} id={x} />)}</div>
            </div>
          )}
          <div>
            <h4>{t('Satır içi değerleri', 'Its inline values')}</h4>
            {Object.keys(c.literals).length ? <LiteralChips literals={c.literals} /> : <p className="muted" style={{ fontSize: 12, margin: 0 }}>{t('Yok.', 'None.')}</p>}
          </div>
          <div>
            <h4>{t('Kaynak', 'Source')}</h4>
            <div className="places"><SourceLink file={c.source.file} line={c.source.line}>{shortPath(c.source.file)}:{c.source.line}</SourceLink></div>
          </div>
        </aside>
      </div>
    </div>
  )
}
