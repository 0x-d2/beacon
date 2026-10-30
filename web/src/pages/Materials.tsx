import { Link } from 'react-router-dom'
import { routeFor, useCatalog, useT } from '../data.tsx'
import { rgba, SourceLink } from '../ui/bits.tsx'

const notes: Record<string, { tr: string; en: string }> = {
  '.regularMaterial': { tr: 'Panelin camı (Liquid Glass kapalıyken) ve çoğu açılır pencere.', en: 'The panel\'s glass (with Liquid Glass off) and most pop-ups.' },
  '.ultraThinMaterial': { tr: 'Arkasını en çok gösteren katman.', en: 'The layer that shows the most of what\'s behind.' },
  '.ultraThickMaterial': { tr: 'Neredeyse opak katman.', en: 'An almost opaque layer.' },
  '.glassEffect(.regular)': { tr: 'macOS 26 Liquid Glass; yalnız ayar açıkken ve #if compiler(>=6.2) içinde.', en: 'macOS 26 Liquid Glass; only with the setting on, inside #if compiler(>=6.2).' },
  '.glassEffect(.clear)': { tr: 'Daha saydam Liquid Glass.', en: 'The clearer Liquid Glass.' },
  'NSVisualEffectView .hudWindow': { tr: 'Yüzen panellerin HUD materyali (HUDBackdrop).', en: 'The floating panels\' HUD material (HUDBackdrop).' },
  'NSVisualEffectView .toolTip': { tr: 'İpucu baloncuğu materyali.', en: 'The tooltip material.' },
}

/**
 * The materials: what the panels are made of. The preview is the panel card's recipe drawn in CSS with the app's own
 * numbers (PanelSurface.baseFill, cardFill, border on a blurred ground), close to the app but not its pixels; those are
 * the renders'.
 */
export function Materials() {
  const { catalog } = useCatalog()
  const t = useT()
  const token = (id: string) => catalog.tokens.colors.find((c) => c.id === id)

  return (
    <div className="page">
      <div className="eyebrow">{t('Temeller', 'Foundations')}</div>
      <h1 className="title">{t('Malzemeler', 'Materials')}</h1>
      <p className="lede">{t(
        'Menü paneli saydam bir malzemeden yapılır: macOS 26\'da ve ayar açıkken Liquid Glass (.glassEffect), yoksa .regularMaterial; üstüne PanelSurface.baseFill, kartlar için cardFill ve ince bir border. Yüzen araçlar HUD materyalini (HUDBackdrop) kullanır.',
        'The menu panel is made of a translucent material: Liquid Glass (.glassEffect) on macOS 26 with the setting on, .regularMaterial otherwise; PanelSurface.baseFill over it, cardFill for the cards and a thin border. The floating tools use the HUD material (HUDBackdrop).',
      )}</p>

      <h2 className="section">{t('Panel kartının tarifi', 'The panel card\'s recipe')}</h2>
      <p className="section-note">{t('CSS ile, uygulamanın sayılarıyla çizilmiş yaklaşık bir önizleme; uygulamanın kendi pikselleri bileşen görüntülerinde.', 'An approximate preview drawn in CSS with the app\'s numbers; the app\'s own pixels are in the component images.')}</p>
      <div className="grid cols-2">
        {(['dark', 'light'] as const).map((appearance) => (
          <div key={appearance} className={`ground${appearance === 'light' ? ' light' : ''}`}>
            <div className="material-card" style={{
              background: `linear-gradient(${rgba(token('PanelSurface.cardFill')?.values[appearance] ?? null)}, ${rgba(token('PanelSurface.cardFill')?.values[appearance] ?? null)}), ${rgba(token('PanelSurface.baseFill')?.values[appearance] ?? null)}`,
              boxShadow: `inset 0 0 0 0.7px ${rgba(token('PanelSurface.border')?.values[appearance] ?? null)}`,
              color: appearance === 'light' ? '#1d1d1f' : '#f5f5f7',
            }}>
              <small>{t('Sistem', 'System')}</small>
              CPU 23% · {t('Bellek', 'Memory')} 11.2 GB
            </div>
          </div>
        ))}
      </div>
      <div className="chips" style={{ marginTop: 12 }}>
        <Link className="chip" to={routeFor(catalog, '.panelCard()')}>.panelCard()</Link>
        <Link className="chip" to={routeFor(catalog, '.panelGlassSurface()')}>.panelGlassSurface()</Link>
        <Link className="chip" to="/renkler#PanelSurface">PanelSurface</Link>
        <Link className="chip" to={routeFor(catalog, 'HUDBackdrop')}>HUDBackdrop</Link>
      </div>

      <h2 className="section">{t('Kullanılan malzemeler', 'Materials in use')} <span className="count">{catalog.literals.material.length}</span></h2>
      <div className="panel">
        <table className="table">
          <thead><tr><th>{t('Malzeme', 'Material')}</th><th>{t('Ne için', 'What for')}</th><th className="num">{t('Yer', 'Places')}</th><th>{t('İlk yer', 'First place')}</th></tr></thead>
          <tbody>
            {catalog.literals.material.map((g) => (
              <tr key={g.key}>
                <td><code>{g.key}</code></td>
                <td className="dim">{notes[g.key]?.[t.language] ?? ''}</td>
                <td className="num"><Link to={`/degerler/material?deger=${encodeURIComponent(g.key)}`}>{g.count}</Link></td>
                <td><SourceLink file={g.places[0].file} line={g.places[0].line} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
