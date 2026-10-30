import { Link } from 'react-router-dom'
import { useCatalog, useT } from '../data.tsx'
import { Doc, NoteButton, SourceLink, useHashScroll } from '../ui/bits.tsx'

const weights: Record<string, number> = { ultraLight: 100, thin: 200, light: 300, regular: 400, medium: 500, semibold: 600, bold: 700, heavy: 800, black: 900 }
/** macOS's text styles (they don't scale on the Mac): size and weight. */
const semantic: Record<string, [number, string]> = {
  largeTitle: [26, 'regular'], title: [22, 'regular'], title2: [17, 'regular'], title3: [15, 'regular'], headline: [13, 'bold'],
  body: [13, 'regular'], callout: [12, 'regular'], subheadline: [11, 'regular'], footnote: [10, 'regular'], caption: [10, 'regular'], caption2: [10, 'regular'],
}

/**
 * The type: one token (`sectionTitle`), then every size, weight and design the views write, with SF Pro drawing the
 * sample where the browser has it (Safari and Chrome on a Mac), so the sizes compare as the app shows them.
 */
export function Typography() {
  const { catalog } = useCatalog()
  const t = useT()
  useHashScroll()
  const groups = catalog.literals.font.filter((g) => g.value !== null)
  const variable = catalog.literals.font.find((g) => g.key.includes('(değişken)'))
  const total = catalog.literals.font.reduce((n, g) => n + g.count, 0)
  const sizes = [...new Set(groups.map((g) => g.value!))].sort((a, b) => b - a)

  return (
    <div className="page">
      <div className="eyebrow">{t('Temeller', 'Foundations')}</div>
      <h1 className="title">{t('Tipografi', 'Typography')}</h1>
      <p className="lede">{t(
        `Tek bir yazı token'ı var: sectionTitle. Geri kalan ${total} yazı tanımı view'larda: ya .system(size:weight:design:) ile doğrudan bir boyut, ya da macOS'un metin stillerinden biri (.caption, .callout…). Örnekler SF Pro ile, uygulamanın boyutunda çizilir.`,
        `There's one type token: sectionTitle. The other ${total} type settings are in the views: either a size straight in .system(size:weight:design:), or one of macOS's text styles (.caption, .callout…). The samples draw in SF Pro, at the app's size.`,
      )}</p>

      <h2 className="section">{t('Token', 'Token')}</h2>
      {catalog.tokens.textStyles.map((style) => (
        <div className="panel padded" key={style.id} id={style.id} style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) auto', gap: 16, alignItems: 'center' }}>
          <div>
            <div className="type-sample upper" style={{ fontSize: style.size * 1.6, fontWeight: weights[style.weight], letterSpacing: style.tracking * 1.6 }}>{t('Sistem · Bellek', 'System · Memory')}</div>
            <div className="dims"><code>{style.id}(_:)</code> · {style.size} pt {style.weight} · {t('harf aralığı', 'tracking')} {style.tracking}{style.uppercase ? ` · ${t('büyük harf', 'uppercase')}` : ''}{style.color ? ` · .${style.color}` : ''} · {t('%160 büyütülmüş', 'shown at 160%')}</div>
            <Doc text={style.doc} />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-end' }}>
            <span className="mono muted">{t.n(style.usage.total, 'kullanım', 'use')}</span>
            <SourceLink file={style.source.file} line={style.source.line} />
            <NoteButton item={style.id} label={t('Not', 'Note')} />
          </div>
        </div>
      ))}

      <h2 className="section">{t('Satır içi yazı tanımları', 'Inline type settings')} <span className="count">{groups.length}</span></h2>
      <p className="section-note">{t(
        `Büyükten küçüğe; her satır bir boyut, kalınlık ve tasarım birleşimi. ${sizes.length} farklı boyut var${variable ? `; ${variable.count} tanım boyutu bir değişkenden alıyor` : ''}. Sayıya tıklayınca yazıldığı yerler açılır.`,
        `Largest first; each row is one size, weight and design. There are ${sizes.length} distinct sizes${variable ? `; ${variable.count} settings take their size from a variable` : ''}. Click a count for the places it's written.`,
      )}</p>
      <div className="panel">
        <table className="table">
          <thead><tr><th>{t('Örnek', 'Sample')}</th><th>{t('Tanım', 'Setting')}</th><th className="num">pt</th><th className="num">{t('Yer', 'Places')}</th><th className="num">{t('Dosya', 'Files')}</th><th>{t('Token', 'Token')}</th></tr></thead>
          <tbody>
            {[...groups].sort((a, b) => b.value! - a.value! || b.count - a.count).map((g) => {
              const [size, weight = 'regular', design] = g.key.split(' · ')
              const name = size.startsWith('.') ? size.slice(1) : null
              const [px, w] = name ? semantic[name] ?? [g.value!, 'regular'] : [Number(size), weight]
              const chosenWeight = name ? (g.key.split(' · ')[1] ?? w) : w
              return (
                <tr key={g.key}>
                  <td style={{ maxWidth: 380 }}>
                    <div className="type-sample" style={{ fontSize: px, fontWeight: weights[chosenWeight] ?? 400, fontFamily: design === 'monospaced' ? 'ui-monospace, SF Mono, monospace' : design === 'rounded' ? 'ui-rounded, -apple-system, system-ui' : undefined }}>
                      {t('Ağ · 12,4 MB/sn · %38', 'Network · 12.4 MB/s · 38%')}
                    </div>
                  </td>
                  <td><code>{name ? `.font(.${name}${g.key.includes(' · ') ? `).weight(.${g.key.split(' · ')[1]}` : ''})` : `.system(size: ${size}${weight !== 'regular' ? `, weight: .${weight}` : ''}${design ? `, design: .${design}` : ''})`}</code></td>
                  <td className="num">{px}</td>
                  <td className="num"><Link to={`/degerler/font?deger=${encodeURIComponent(g.key)}`}>{g.count}</Link></td>
                  <td className="num muted">{g.files}</td>
                  <td>{g.match ? <span className="badge brand" title={g.match.note[t.language]}>{g.match.token}</span> : null}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
