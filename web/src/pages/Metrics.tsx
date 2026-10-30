import { Link } from 'react-router-dom'
import type { LiteralKind } from '../../collector/schema.ts'
import { useCatalog, useT, useText } from '../data.tsx'
import { Doc, literalTitles, NoteButton, SourceLink, useHashScroll } from '../ui/bits.tsx'

/** The metric tokens (`PanelRowMetrics`), the layout numbers a surface's size comes from, and the most common inline sizes. */
export function Metrics() {
  const { catalog, settings } = useCatalog()
  const text = useText()
  const t = useT()
  useHashScroll()

  return (
    <div className="page">
      <div className="eyebrow">{t('Temeller', 'Foundations')}</div>
      <h1 className="title">{t('Ölçüler', 'Metrics')}</h1>
      <p className="lede">{t(
        'Ölçü token\'ı olarak yalnız panel satırlarının boşlukları var (PanelRowMetrics). Panelin, kartın ve Ayarlar penceresinin boyutu ise view\'larda yazılı sayılar; aşağıda ikisi de tanımlandıkları satırla.',
        'The only metric tokens are the panel rows\' spacing (PanelRowMetrics). The panel\'s, the card\'s and the Settings window\'s sizes are numbers written in the views; both are below, with the line that sets them.',
      )}</p>

      <h2 className="section" id="PanelRowMetrics">PanelRowMetrics <span className="count">{catalog.tokens.metrics.length}</span></h2>
      <div className="panel">
        <table className="table">
          <thead><tr><th>Token</th><th className="num">{t('Panel', 'Panel')}</th><th className="num">{t('Ada', 'Island')}</th><th>{t('İfade', 'Expression')}</th><th className="num">{t('Kullanım', 'Uses')}</th><th /></tr></thead>
          <tbody>
            {catalog.tokens.metrics.map((m) => (
              <tr key={m.id} id={m.id}>
                <td><code>{m.id.split('.')[1]}</code><Doc text={m.doc} style={{ fontSize: 12, marginTop: 2 }} /></td>
                <td className="num">{m.value ?? '—'}</td>
                <td className="num">{m.island ?? <span className="muted">=</span>}</td>
                <td><code className="muted">{m.expression}</code></td>
                <td className="num">{m.usage.total}</td>
                <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}><SourceLink file={m.source.file} line={m.source.line}>{t('kaynak', 'source')}</SourceLink> <NoteButton item={m.id} label={t('Not', 'Note')} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 className="section">{t('Yerleşim sayıları', 'Layout numbers')} <span className="count">{catalog.tokens.landmarks.length}</span></h2>
      <p className="section-note">{t('Token değiller ama bir yüzeyin boyutunu belirliyorlar.', 'Not tokens, but they set a whole surface\'s size.')}</p>
      <div className="panel">
        <table className="table">
          <tbody>
            {catalog.tokens.landmarks.map((l) => (
              <tr key={l.id} id={l.id}>
                <td><b style={{ fontWeight: 600 }}>{text(l.title)}</b></td>
                <td className="num" style={{ fontSize: 14, color: 'var(--text)' }}>{l.value}</td>
                <td><code className="muted">{l.code}</code></td>
                <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}><SourceLink file={l.source.file} line={l.source.line} /> <NoteButton item={l.id} label={t('Not', 'Note')} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 className="section">{t('En çok yazılan değerler', 'The most written values')}</h2>
      <div className="grid cols-3">
        {(['radius', 'padding', 'spacing'] as LiteralKind[]).map((kind) => (
          <div key={kind}>
            <h3 className="sub"><Link to={`/degerler/${kind}`}>{literalTitles[kind][settings.language]} →</Link></h3>
            <div className="panel">
              <table className="table">
                <tbody>
                  {catalog.literals[kind].slice(0, 10).map((g) => (
                    <tr key={g.key}>
                      <td>
                        <span className="pair">
                          {kind === 'radius' && <span className="radius-demo" style={{ borderRadius: Math.min(g.value ?? 0, 12) }} />}
                          <span className="literal-key">{g.key}</span>
                        </span>
                      </td>
                      <td className="num"><Link to={`/degerler/${kind}?deger=${encodeURIComponent(g.key)}`}>{g.count}</Link></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
