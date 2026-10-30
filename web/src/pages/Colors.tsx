import { Link } from 'react-router-dom'
import type { ColorToken } from '../../collector/schema.ts'
import { useCatalog, useT } from '../data.tsx'
import { contrast, Doc, NoteButton, Notes, rgba, SourceLink, Swatch, useHashScroll } from '../ui/bits.tsx'

/** The colour tokens (UI/Theme.swift), the gradients and palettes, and the system colours the app names. */
export function Colors() {
  const { catalog } = useCatalog()
  const t = useT()
  useHashScroll()
  const window = catalog.systemColors.find((c) => c.id === 'windowBackground')
  const ground = { light: window?.light.hex ?? '#ffffff', dark: window?.dark.hex ?? '#1e1e1e' }
  const metric = catalog.tokens.colors.filter((c) => c.group === 'PanelMetricColor')
  const surface = catalog.tokens.colors.filter((c) => c.group === 'PanelSurface')
  const inline = catalog.literals.color.reduce((n, g) => n + g.count, 0)

  return (
    <div className="page">
      <div className="eyebrow">{t('Temeller', 'Foundations')} · <span lang="en">UI/Theme.swift</span></div>
      <h1 className="title">{t('Renkler', 'Colours')}</h1>
      <p className="lede">{t(
        'Token\'lar birer fonksiyon: açık ve koyu tema için ayrı değer döndürürler (scheme == .light ? … : …). Metrik renkleri koyu temada sistem renginin kendisi, açık temada okunabilsin diye koyulaştırılmış bir RGB. Yüzey renkleri saydam: panelin materyalinin üstüne biner.',
        'The tokens are functions: they return a value for the light and the dark appearance (scheme == .light ? … : …). The metric colours are the system colour itself in dark mode and a darkened RGB in light mode, so they read. The surface colours are translucent: they sit on the panel\'s material.',
      )}</p>

      <h2 className="section" id="PanelMetricColor">PanelMetricColor <span className="count">{metric.length}</span></h2>
      <p className="section-note">{t(
        `Grafikler, ölçüler ve durum renkleri. Kontrast, pencere zemini üstünde (${ground.light} / ${ground.dark}).`,
        `Charts, meters and status colours. Contrast is over the window background (${ground.light} / ${ground.dark}).`,
      )}</p>
      <ColorTable tokens={metric} ground={ground} />

      <h2 className="section" id="PanelSurface">PanelSurface <span className="count">{surface.length}</span></h2>
      <p className="section-note">{t(
        'Kartların, kontrollerin ve çizgilerin saydam katmanları. Önizleme, panelin zeminine yakın bir gri üstünde; çizgilerin "Kontrast Artır" açıkken aldığı değer ayrıca gösterilir.',
        'The translucent layers of cards, controls and outlines. The preview sits on a grey close to the panel\'s ground; the outlines\' Increase Contrast value is shown beside.',
      )}</p>
      <ColorTable tokens={surface} ground={ground} translucent />

      <h2 className="section">{t('Geçişler', 'Gradients')} <span className="count">{catalog.tokens.gradients.length}</span></h2>
      <div className="grid cols-2">
        {catalog.tokens.gradients.map((g) => (
          <div className="panel padded" key={g.id} id={g.id}>
            <div className="variant-head"><code>{g.id}</code><span className="actions"><SourceLink file={g.source.file} line={g.source.line}>{t('kaynak', 'source')}</SourceLink></span></div>
            <div className="grid cols-2" style={{ marginTop: 10 }}>
              {(['light', 'dark'] as const).map((appearance) => (
                <div key={appearance}>
                  <div className="gradient-strip" style={{ background: `linear-gradient(${direction(g.direction)}, ${g.stops[appearance].map(rgba).join(', ')}), ${appearance === 'light' ? '#e8e8ea' : '#2a2a2d'}` }} />
                  <div className="dims">{appearance === 'light' ? t('Açık', 'Light') : t('Koyu', 'Dark')} · {g.direction}</div>
                </div>
              ))}
            </div>
            <Doc text={g.doc} style={{ marginTop: 8 }} />
            <div className="dims">{t.n(g.usage.total, 'kullanım', 'use')}</div>
          </div>
        ))}
      </div>

      <h2 className="section" id="system">{t('Sistem renkleri', 'System colours')} <span className="count">{catalog.systemColors.length}</span></h2>
      <p className="section-note">{t(
        `Kodun adıyla andığı sistem renkleri (.green, .secondary, Color.accentColor); değerleri macOS ${catalog.meta.systemColors}'nin çizdiği gibi. Vurgu rengi, kullanıcının seçtiği renktir (burada varsayılan mavi).`,
        `The system colours the code names (.green, .secondary, Color.accentColor), valued as macOS ${catalog.meta.systemColors} draws them. The accent is whatever the user picked (the default blue here).`,
      )}</p>
      <div className="panel">
        <table className="table">
          <thead><tr><th>{t('Ad', 'Name')}</th><th>{t('Açık', 'Light')}</th><th>{t('Koyu', 'Dark')}</th><th className="num">{t('Satır içi', 'Inline')}</th></tr></thead>
          <tbody>
            {catalog.systemColors.map((c) => (
              <tr key={c.id}>
                <td><code>{c.id === 'accentColor' ? 'Color.accentColor' : `.${c.id}`}</code></td>
                <td><span className="pair"><Swatch {...c.light} light small /><span className="hex">{c.light.hex}{c.light.alpha < 1 ? ` · ${Math.round(c.light.alpha * 100)}%` : ''}</span></span></td>
                <td><span className="pair"><Swatch {...c.dark} small /><span className="hex">{c.dark.hex}{c.dark.alpha < 1 ? ` · ${Math.round(c.dark.alpha * 100)}%` : ''}</span></span></td>
                <td className="num"><Link to={`/degerler/color?deger=${encodeURIComponent(c.id === 'accentColor' ? 'Color.accentColor' : `.${c.id}`)}`}>{c.count}</Link></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 className="section">{t('Paletler', 'Palettes')} <span className="count">{catalog.tokens.palettes.length}</span></h2>
      <p className="section-note">{t('Bir enum\'un case\'lerine göre seçilen renkler (maskot, dairesel menü, ada kutuları).', 'Colours an enum picks per case (the mascot, the radial menu, the island\'s tiles).')}</p>
      <div className="grid cols-2">
        {catalog.tokens.palettes.map((p) => (
          <div className="panel padded" key={p.id} id={p.id}>
            <div className="variant-head"><code>{p.id}</code><span className="actions"><SourceLink file={p.source.file} line={p.source.line}>{t('kaynak', 'source')}</SourceLink></span></div>
            <div className="palette-row" style={{ marginTop: 10 }}>
              {p.entries.map((e) => (
                <span className="entry" key={e.id} title={e.expression}>
                  {e.value ? <Swatch {...e.value} small /> : <span className="swatch small" />}
                  {e.id}
                </span>
              ))}
            </div>
            <Doc text={p.doc} style={{ marginTop: 8 }} />
          </div>
        ))}
      </div>

      <h2 className="section">{t('Satır içi renkler', 'Inline colours')}</h2>
      <p className="section-note">{t(
        `Token yerine doğrudan yazılmış ${inline} renk (Color(red:…), Color.white.opacity(…), .orange…). Bir token'a çok yakın olanlar işaretli.`,
        `${inline} colours typed in place of a token (Color(red:…), Color.white.opacity(…), .orange…). The ones very close to a token are marked.`,
      )}</p>
      <Link className="button brand" to="/degerler/color">{t('Satır içi renkler →', 'Inline colours →')}</Link>
    </div>
  )
}

function ColorTable({ tokens, ground, translucent = false }: { tokens: ColorToken[]; ground: { light: string; dark: string }; translucent?: boolean }) {
  const { catalog } = useCatalog()
  const t = useT()
  return (
    <div className="panel">
      <table className="table">
        <thead>
          <tr>
            <th>Token</th><th>{t('Açık', 'Light')}</th><th>{t('Koyu', 'Dark')}</th>
            {translucent && <th>{t('Kontrast Artır', 'Increase Contrast')}</th>}
            <th className="num">{t('Kullanım', 'Uses')}</th><th />
          </tr>
        </thead>
        <tbody>
          {tokens.map((c) => {
            const notes = catalog.issues.filter((i) => i.item === c.id)
            return (
              <tr key={c.id} id={c.id}>
                <td style={{ maxWidth: 360 }}>
                  <code>{c.id.split('.')[1]}</code>
                  <div className="mono muted" style={{ fontSize: 11, marginTop: 2, whiteSpace: 'normal' }}>{c.expression}</div>
                  <Doc text={c.doc} style={{ marginTop: 4, fontSize: 12 }} />
                  <Notes issues={notes} />
                </td>
                {(['light', 'dark'] as const).map((appearance) => {
                  const value = c.values[appearance]
                  return (
                    <td key={appearance}>
                      {value ? (
                        <span className="pair">
                          {translucent
                            ? <span className={`on-ground ${appearance}`}><i style={{ background: rgba(value) }} /></span>
                            : <Swatch {...value} light={appearance === 'light'} />}
                          <span>
                            <span className="hex">{value.hex}{value.alpha < 1 ? ` · ${Math.round(value.alpha * 1000) / 10}%` : ''}</span>
                            {!translucent && <span className="ratio" style={{ display: 'block' }}>{contrast(value.hex, ground[appearance]).toFixed(2)}:1</span>}
                          </span>
                        </span>
                      ) : <span className="muted mono">—</span>}
                    </td>
                  )
                })}
                {translucent && (
                  <td>
                    {c.values.lightHighContrast || c.values.darkHighContrast
                      ? <span className="hex">{t('açık', 'light')} {Math.round((c.values.lightHighContrast?.alpha ?? 0) * 100)}% · {t('koyu', 'dark')} {Math.round((c.values.darkHighContrast?.alpha ?? 0) * 100)}%</span>
                      : <span className="muted mono">—</span>}
                  </td>
                )}
                <td className="num">{c.usage.total}</td>
                <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
                  <SourceLink file={c.source.file} line={c.source.line}>{t('kaynak', 'source')}</SourceLink>{' '}
                  <NoteButton item={c.id} label={t('Not', 'Note')} />
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}

/** SwiftUI's unit points (`topLeading→bottomTrailing`) as a CSS gradient's direction. */
function direction(points: string): string {
  const map: Record<string, string> = {
    'top→bottom': 'to bottom', 'bottom→top': 'to top', 'leading→trailing': 'to right', 'trailing→leading': 'to left',
    'topLeading→bottomTrailing': 'to bottom right', 'bottomTrailing→topLeading': 'to top left', 'topTrailing→bottomLeading': 'to bottom left', 'bottomLeading→topTrailing': 'to top right',
  }
  return map[points] ?? 'to bottom'
}
