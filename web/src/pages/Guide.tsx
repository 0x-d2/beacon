import { Link } from 'react-router-dom'
import { routeFor, useCatalog, useT, useText } from '../data.tsx'
import { NoteButton, SourceLink, useHashScroll } from '../ui/bits.tsx'

/** "Neyi nereden değiştiririm": the guide (collector/guide.ts), grouped by area, each entry the line that sets it. */
export function Guide() {
  const { catalog } = useCatalog()
  const text = useText()
  const t = useT()
  useHashScroll()
  const areas = [...new Map(catalog.guide.map((g) => [g.area.en, g.area])).values()]

  return (
    <div className="page">
      <div className="eyebrow">{t('Başlarken', 'Start here')}</div>
      <h1 className="title">{t('Neyi nereden değiştiririm', 'What to change where')}</h1>
      <p className="lede">{t(
        'Görünümün bir parçasından onu belirleyen satıra. Satırlar her derlemede kaynakta yeniden aranır, kod değiştikçe yerleri güncel kalır. Bir revize için maddenin yanındaki "Not bırak"ı kullanın.',
        'From a part of the look to the line that sets it. The lines are looked up in the source at every build, so they follow the code. For a revision, use "Leave a note" beside the entry.',
      )}</p>
      {areas.map((area) => (
        <div className="guide-area" key={area.en}>
          <h3 className="sub">{text(area)}</h3>
          <div className="panel">
            {catalog.guide.filter((g) => g.area.en === area.en).map((entry) => (
              <div className="guide-row" key={entry.id} id={entry.id}>
                <div>
                  <b>{text(entry.what)}</b>
                  {entry.link && <div style={{ marginTop: 6 }}><Link className="chip" to={routeFor(catalog, entry.link)}>{entry.link}</Link></div>}
                </div>
                <div className="how">{text(entry.how)}</div>
                <div className="where">
                  <SourceLink file={entry.file} line={entry.line} />
                  {entry.code ? <code title={entry.code}>{entry.code}</code> : <span className="badge warn">{t('satır bulunamadı', 'line not found')}</span>}
                  <span><NoteButton item={`rehber:${entry.id}`} label={t('Not', 'Note')} /></span>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}
