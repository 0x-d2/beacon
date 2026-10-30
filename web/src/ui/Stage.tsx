// A render on the bench: at the app's size (1 pt = 1 CSS px; surfaces at a scale), in the chosen theme, or both themes
// split by a handle the viewer drags across, the way two prints are laid one over the other.
import { useRef, useState, type PointerEvent } from 'react'
import { useCatalog, useT } from '../data.tsx'

type Shot = { src: string; width: number; height: number; mode?: string }

export function Stage({ images, title, scale = 1 }: { images: Record<string, Shot>; title: string; scale?: number }) {
  const { settings } = useCatalog()
  const t = useT()
  const language = settings.language
  const dark = images[`${language}-dark`] ?? images['tr-dark'] ?? images['en-dark']
  const light = images[`${language}-light`] ?? images['tr-light'] ?? images['en-light']
  const fellBack = !images[`${language}-dark`] && !images[`${language}-light`]

  if (!dark && !light) {
    return <div className="missing">{t('Bunun henüz görüntüsü yok.', 'This has no image yet.')}<br />{t('docs/scripts/kit.sh çalıştırın (ya da 0x-d2/beacon-kit-runner › Actions › BeaconKit™).', 'Run docs/scripts/kit.sh (or 0x-d2/beacon-kit-runner › Actions › BeaconKit™).')}</div>
  }
  const mode = settings.theme === 'split' && dark && light ? 'split' : settings.theme === 'light' && light ? 'light' : dark ? 'dark' : 'light'
  const shot = (mode === 'light' ? light : dark) as Shot
  const width = shot.width * scale
  const height = shot.height * scale

  return (
    <div>
      <div className="specimen">
        {mode === 'split'
          ? <Split dark={dark as Shot} light={light as Shot} width={width} height={height} />
          : (
            <div className="stage" style={{ width, height }}>
              <img src={`/${shot.src}`} width={width} height={height} alt={title} loading="lazy" />
            </div>
          )}
      </div>
      <div className="dims">
        <span>{round(shot.width)} × {round(shot.height)} pt</span>
        {scale !== 1 && <span>· {t(`${t.percent(Math.round(scale * 100))} ölçek`, `${t.percent(Math.round(scale * 100))} scale`)}</span>}
        {fellBack && <span className="badge warn">{t(`${language.toUpperCase()} görüntüsü yok`, `no ${language.toUpperCase()} image`)}</span>}
        {shot.mode === 'window' && (
          <span className="badge" title={t('Ekran Kaydı izni olmadan çekildi: renderer yalnız kendi pencerelerini görür, malzemeler arkalarını bulanıklaştırmaz', 'Taken without Screen Recording permission: the renderer sees only its own windows, so materials don\'t blur what\'s behind')}>
            {t('malzeme düz', 'flat material')}
          </span>
        )}
        {shot.mode === 'imageRenderer' && <span className="badge" title={t('ImageRenderer ile çizildi: malzemeler ve AppKit kontrolleri yok', 'Drawn with ImageRenderer: no materials or AppKit controls')}>ImageRenderer</span>}
      </div>
    </div>
  )
}

function Split({ dark, light, width, height }: { dark: Shot; light: Shot; width: number; height: number }) {
  const t = useT()
  const [at, setAt] = useState(50)
  const box = useRef<HTMLDivElement>(null)
  const move = (event: PointerEvent) => {
    if (event.buttons === 0 && event.type !== 'pointerdown') return
    const rect = box.current!.getBoundingClientRect()
    setAt(Math.min(100, Math.max(0, ((event.clientX - rect.left) / rect.width) * 100)))
  }
  return (
    <div ref={box} className="stage split" style={{ width, height }}
      onPointerDown={(e) => { (e.target as Element).setPointerCapture?.(e.pointerId); move(e) }} onPointerMove={move}>
      <div className="layer"><img src={`/${dark.src}`} alt="" loading="lazy" draggable={false} /></div>
      <div className="layer" style={{ clipPath: `inset(0 0 0 ${at}%)` }}><img src={`/${light.src}`} alt="" loading="lazy" draggable={false} /></div>
      <div className="divider" style={{ left: `${at}%` }} />
      <span className="tag left">{t('Koyu', 'Dark')}</span>
      <span className="tag right">{t('Açık', 'Light')}</span>
    </div>
  )
}

const round = (n: number) => Math.round(n * 10) / 10

/** A card's thumbnail: the first render in the theme on screen, else the name on the app's window background. */
export function Thumb({ images, title, subtitle }: { images: Record<string, Shot> | undefined; title: string; subtitle?: string }) {
  const { settings } = useCatalog()
  const theme = settings.theme === 'light' ? 'light' : 'dark'
  const shot = images?.[`${settings.language}-${theme}`] ?? images?.[`tr-${theme}`]
  return (
    <div className={`thumb${theme === 'light' ? ' light' : ''}`}>
      {shot ? <img src={`/${shot.src}`} alt="" loading="lazy" /> : <div className="placeholder">{title}{subtitle && <small>{subtitle}</small>}</div>}
    </div>
  )
}
