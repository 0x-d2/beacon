import { Link, useParams } from 'react-router-dom'
import { routeFor, useCatalog, useT, useText } from '../data.tsx'
import { Doc, ItemLink, LiteralChips, NoteButton, Notes, shortPath, SourceLink } from '../ui/bits.tsx'
import { Stage } from '../ui/Stage.tsx'

/** One surface: its render, the view and file that draw it, the components and tokens it's built from, its inline values. */
export function SurfacePage() {
  const { catalog, surface } = useCatalog()
  const text = useText()
  const t = useT()
  const { id = '' } = useParams()
  const s = surface(decodeURIComponent(id))
  if (!s) return <div className="page"><h1 className="title">{t('Yüzey yok', 'No such surface')}</h1><Link className="button" to="/yuzeyler">← {t('Yüzeyler', 'Surfaces')}</Link></div>
  const group = catalog.surfaceGroups.find((g) => g.id === s.group)
  const components = Object.entries(s.components).sort((a, b) => b[1] - a[1])
  const tokens = Object.entries(s.tokens).sort((a, b) => b[1] - a[1])
  const literalTotal = Object.values(s.literals).reduce((n, v) => n + (v ?? 0), 0)

  return (
    <div className="page">
      <div className="eyebrow"><Link to="/yuzeyler">{t('Yüzeyler', 'Surfaces')}</Link> · <Link to={`/yuzeyler/${s.group}`}>{text(group?.title)}</Link></div>
      <h1 className="title">{text(s.title)}</h1>
      <Doc text={s.doc || t(`${s.view} bu yüzeyi çizer.`, `${s.view} draws this surface.`)} className="lede" />
      <div className="chips" style={{ marginTop: 14 }}>
        <span className="chip"><b>{s.view}</b></span>
        <SourceLink file={s.source.file} line={s.source.line} />
        {s.symbol && <span className="chip" title="SF Symbol">{s.symbol}</span>}
        <span className="chip">{t('Son değişiklik', 'Last change')}: {t.since(s.lastChange)}</span>
        <NoteButton item={s.id} />
      </div>
      <div style={{ marginTop: 10 }}><Notes issues={s.issues} /></div>

      <div className="detail">
        <div>
          <h3 className="sub" style={{ marginTop: 0 }}>{t('Görüntü', 'Image')}</h3>
          <Stage images={s.images} title={text(s.title)} scale={s.group === 'settings' || s.group === 'window' ? 0.6 : 1} />

          <h3 className="sub">{t('Stilini değiştirmek için', 'To change its style')}</h3>
          <div className="panel padded doc">
            {t.language === 'en' ? <>
              The view is <code>{s.view}</code> in <code>{shortPath(s.source.file)}</code>. It draws with {components.length} shared {components.length === 1 ? 'component' : 'components'}{' '}
              (a change there shows wherever they're used) and writes {literalTotal} inline {literalTotal === 1 ? 'value' : 'values'} of its own (a change there shows only here).
              {tokens.length > 0 ? ` It names ${tokens.length} ${tokens.length === 1 ? 'token' : 'tokens'}.` : ' It names no token directly.'}
            </> : <>
              View <code>{s.view}</code>, dosya <code>{shortPath(s.source.file)}</code>. {components.length} ortak bileşenle çizilir (orada yapılan değişiklik
              kullanıldıkları her yerde görünür) ve kendine ait {literalTotal} satır içi değer yazar (orada yapılan değişiklik yalnız burada görünür).
              {tokens.length > 0 ? ` ${tokens.length} token'ı adıyla kullanır.` : ' Doğrudan bir token kullanmaz.'}
            </>}
          </div>
        </div>

        <aside className="rail">
          <div>
            <h4>{t('Bileşenler', 'Components')}</h4>
            {components.length ? <div className="chips">{components.map(([c, n]) => <ItemLink key={c} id={c}>{c} <b>{n}</b></ItemLink>)}</div> : <p className="muted" style={{ fontSize: 12, margin: 0 }}>{t('Ortak bileşen kullanmıyor.', 'Uses no shared component.')}</p>}
          </div>
          <div>
            <h4>{t('Token\'lar', 'Tokens')}</h4>
            {tokens.length ? <div className="chips">{tokens.map(([x, n]) => <Link key={x} className="chip" to={routeFor(catalog, x)}>{x} <b>{n}</b></Link>)}</div> : <p className="muted" style={{ fontSize: 12, margin: 0 }}>{t('Yok.', 'None.')}</p>}
          </div>
          <div>
            <h4>{t('Satır içi değerler', 'Inline values')}</h4>
            {literalTotal ? <LiteralChips literals={s.literals} /> : <p className="muted" style={{ fontSize: 12, margin: 0 }}>{t('Yok.', 'None.')}</p>}
          </div>
        </aside>
      </div>
    </div>
  )
}
