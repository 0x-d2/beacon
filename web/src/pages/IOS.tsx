// Beacon, the iPhone app (collector/ios.ts): its components with every variant, its screens on the demo Mac, its
// colours beside the Mac tokens they keep the meaning of.
import { Link } from 'react-router-dom'
import { useCatalog, useT, useText } from '../data.tsx'
import { Doc, NoteButton, RenderStamp, rgba, SourceLink, Swatch, useHashScroll } from '../ui/bits.tsx'
import { Stage } from '../ui/Stage.tsx'

const categoryTitles: Record<string, { tr: string; en: string }> = {
  tiles: { tr: 'Kutucuklar', en: 'Tiles' },
  instruments: { tr: 'Göstergeler', en: 'Instruments' },
  badges: { tr: 'Rozetler', en: 'Badges' },
  rows: { tr: 'Satırlar ve durumlar', en: 'Rows and states' },
}

function Missing() {
  const t = useT()
  return (
    <div className="page">
      <h1 className="title">iPhone · Beacon</h1>
      <p className="lede">{t('Bu derlemede iOS/ klasörü yok.', 'This build has no iOS/ folder.')}</p>
    </div>
  )
}

function Header({ title, lede }: { title: string; lede: string }) {
  const { catalog } = useCatalog()
  const t = useT()
  return (
    <>
      <div className="eyebrow">iPhone · Beacon · <Link to="/ios/bilesenler">{t('Bileşenler', 'Components')}</Link> · <Link to="/ios/ekranlar">{t('Ekranlar', 'Screens')}</Link> · <Link to="/ios/renkler">{t('Renkler', 'Colours')}</Link></div>
      <h1 className="title">{title}</h1>
      <p className="lede">{lede}</p>
      <div className="stamps"><RenderStamp label={t('iOS görüntüleri', 'iOS images')} render={catalog.ios?.rendered ?? null} /></div>
    </>
  )
}

export function IOSComponents() {
  const { catalog } = useCatalog()
  const t = useT()
  const text = useText()
  useHashScroll()
  const ios = catalog.ios
  if (!ios) return <Missing />
  const categories = [...new Set(ios.components.map((c) => c.category))]
  return (
    <div className="page">
      <Header title={t('iPhone bileşenleri', 'iPhone components')} lede={t(
        'Beacon\'ın tasarım sistemi baştan token\'lı: her bileşen kendi dosyasında bir KitSpecimen tanımlar; Xcode önizlemeleri, uygulamadaki Tasarım kataloğu ve bu sayfa aynı tanımı çizer. Görüntüler uygulamanın kendisinin ImageRenderer ile @3x çizdiği gibi.',
        'Beacon\'s design system is tokens from the start: each component declares a KitSpecimen in its own file; the Xcode previews, the in-app Design catalog and this page draw that one declaration. The images are as the app itself draws them with ImageRenderer at @3x.',
      )} />
      {categories.map((category) => (
        <div key={category}>
          <h2 className="section">{text(categoryTitles[category] ?? { tr: category, en: category })}</h2>
          {ios.components.filter((c) => c.category === category).map((c) => (
            <div className="panel padded" key={c.id} id={c.id} style={{ marginBottom: 14 }}>
              <div className="variant-head">
                <code style={{ fontSize: 15 }}>{c.id}</code>
                <span className="actions"><SourceLink file={c.source.file} line={c.source.line} /> <NoteButton item={`ios.${c.id}`} label={t('Not', 'Note')} /></span>
              </div>
              <Doc text={c.doc} style={{ marginTop: 6 }} />
              {c.variants.map((v) => (
                <div className="variant" key={v.id} id={`${c.id}.${v.id}`}>
                  <div className="variant-head"><code>{v.title}</code><span className="id mono">{v.id}</span></div>
                  <Stage images={v.images} title={v.title} scale={0.85} />
                </div>
              ))}
            </div>
          ))}
        </div>
      ))}
    </div>
  )
}

export function IOSScreens() {
  const { catalog } = useCatalog()
  const t = useT()
  const text = useText()
  const ios = catalog.ios
  if (!ios) return <Missing />
  return (
    <div className="page">
      <Header title={t('iPhone ekranları', 'iPhone screens')} lede={t(
        'Uygulamanın ekranları demo Mac\'le, simülatörde (iPhone 18 Pro), her iki temada. Koyu | Açık seçiliyken tutamacı sürükleyerek iki temayı karşılaştır.',
        'The app\'s screens with the demo Mac, on the simulator (iPhone 18 Pro), in both themes. With Dark | Light on, drag the handle to compare them.',
      )} />
      <div className="grid cols-3" style={{ marginTop: 28 }}>
        {ios.screens.map((screen) => (
          <div key={screen.id} id={screen.id}>
            <div className="variant-head" style={{ marginBottom: 6 }}>
              <b style={{ fontWeight: 600 }}>{text(screen.title)}</b>
              <span className="actions"><NoteButton item={`ios.screen.${screen.id}`} label={t('Not', 'Note')} /></span>
            </div>
            <Stage images={screen.images} title={text(screen.title)} scale={0.6} />
          </div>
        ))}
      </div>
    </div>
  )
}

export function IOSColors() {
  const { catalog } = useCatalog()
  const t = useT()
  useHashScroll()
  const ios = catalog.ios
  if (!ios) return <Missing />
  return (
    <div className="page">
      <Header title={t('iPhone renkleri', 'iPhone colours')} lede={t(
        'BeaconColor: her ölçü Mac panelindeki rengini korur (koyu temada sistem rengi, açık temada okunabilsin diye koyulaştırılmışı), böylece bir okuma iki ekranda da kendisi gibi görünür. Sağ sütun her rengin Mac\'teki token\'ı.',
        'BeaconColor: each reading keeps its Mac panel colour (the system colour in dark mode, darkened in light mode so it reads), so a reading looks like itself on both screens. The right column is each colour\'s Mac token.',
      )} />
      <div className="panel" style={{ marginTop: 28 }}>
        <table className="table">
          <thead><tr><th>Token</th><th>{t('Açık', 'Light')}</th><th>{t('Koyu', 'Dark')}</th><th>{t('Mac\'teki karşılığı', 'On the Mac')}</th><th /></tr></thead>
          <tbody>
            {ios.colors.map((color) => {
              const mac = color.mac ? catalog.tokens.colors.find((c) => c.id === color.mac) : undefined
              return (
                <tr key={color.id} id={color.id}>
                  <td style={{ maxWidth: 320 }}><code>BeaconColor.{color.id}</code><Doc text={color.doc} style={{ fontSize: 12, marginTop: 2 }} /></td>
                  {(['light', 'dark'] as const).map((appearance) => (
                    <td key={appearance}>
                      {color[appearance]
                        ? <span className="pair"><Swatch {...color[appearance]!} light={appearance === 'light'} /><span className="hex">{color[appearance]!.hex}{color[appearance]!.alpha < 1 ? ` · ${Math.round(color[appearance]!.alpha * 100)}%` : ''}</span></span>
                        : <span className="muted mono">—</span>}
                    </td>
                  ))}
                  <td>
                    {mac ? (
                      <Link className="chip" to={`/renkler#${mac.id}`}>
                        <i style={{ background: rgba(mac.values.dark) }} />{mac.id}
                      </Link>
                    ) : <span className="muted mono">—</span>}
                  </td>
                  <td style={{ textAlign: 'right' }}><SourceLink file={color.source.file} line={color.source.line}>{t('kaynak', 'source')}</SourceLink></td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
