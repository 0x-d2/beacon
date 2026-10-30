import { useCatalog, useT } from '../data.tsx'
import { shortPath, SourceLink } from '../ui/bits.tsx'

/** The newest commits that touched the look: the UI, the island, the menu bar's renderer, the brand art. */
export function Changes() {
  const { catalog } = useCatalog()
  const t = useT()
  return (
    <div className="page">
      <div className="eyebrow">{t('İnceleme', 'Review')}</div>
      <h1 className="title">{t('Değişiklikler', 'Changes')}</h1>
      <p className="lede">{t(
        'Görünüme dokunan son commit\'ler (UI/, Dynamic Island, menü çubuğu, marka görselleri) ve her birinin değiştirdiği dosyalar.',
        'The latest commits that touched the look (UI/, the Dynamic Island, the menu bar, the brand art) and the files each changed.',
      )}</p>
      <div className="panel" style={{ marginTop: 28 }}>
        {catalog.changes.map((change) => (
          <div className="commit" key={change.sha}>
            <a className="mono dim" href={`https://github.com/${catalog.meta.repo}/commit/${change.sha}`} target="_blank" rel="noreferrer">{change.sha.slice(0, 7)}</a>
            <span>{change.subject}</span>
            <span className="mono muted" style={{ fontSize: 11 }}>{t.since(change.at)}</span>
            <div className="files">
              {change.files.slice(0, 12).map((file) => <SourceLink key={file} file={file}>{shortPath(file)}</SourceLink>)}
              {change.files.length > 12 && <span>{t(`+${change.files.length - 12} dosya`, `+${change.files.length - 12} files`)}</span>}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
