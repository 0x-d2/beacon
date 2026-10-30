import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import type { MotionToken } from '../../collector/schema.ts'
import { useCatalog, useT } from '../data.tsx'
import { Doc, NoteButton, SourceLink, useHashScroll } from '../ui/bits.tsx'

/**
 * Progress over time, the way the app works it out: `NotchMotion.Spring.progress(at:)` (Services/Notch/NotchSupport.swift),
 * SwiftUI's perceptual duration and bounce. `.smooth`, `.snappy` and `.bouncy` are the same spring at bounce 0, 0.15 and 0.3.
 */
function spring(duration: number, bounce: number) {
  const natural = (2 * Math.PI) / duration
  const damping = 1 - bounce
  return (time: number) => {
    if (time <= 0) return 0
    if (damping >= 1) return 1 - Math.exp(-natural * time) * (1 + natural * time)
    const damped = natural * Math.sqrt(1 - damping * damping)
    return 1 - Math.exp(-damping * natural * time) * (Math.cos(damped * time) + ((damping * natural) / damped) * Math.sin(damped * time))
  }
}

/** SwiftUI's timing curves as cubic Béziers. */
const curves: Record<string, [number, number, number, number]> = {
  easeOut: [0, 0, 0.58, 1], easeIn: [0.42, 0, 1, 1], easeInOut: [0.42, 0, 0.58, 1], linear: [0, 0, 1, 1], default: [0.42, 0, 0.58, 1],
}

type Shape = { kind: 'spring'; duration: number; bounce: number } | { kind: 'bezier'; points: [number, number, number, number]; duration: number }

/** An inline animation's key (`.easeOut(duration: 0.15)`, `.spring(response: 0.3, dampingFraction: 0.8)`) as a shape. */
function shapeOf(key: string): Shape | null {
  const name = key.match(/^\.(\w+)/)?.[1] ?? ''
  const number = (label: string) => Number(key.match(new RegExp(`${label}:\\s*([0-9.]+)`))?.[1] ?? NaN)
  if (name in curves) return { kind: 'bezier', points: curves[name], duration: Number.isNaN(number('duration')) ? 0.35 : number('duration') }
  if (name === 'smooth' || name === 'snappy' || name === 'bouncy') {
    const bounce = Number.isNaN(number('extraBounce')) ? 0 : number('extraBounce')
    return { kind: 'spring', duration: Number.isNaN(number('duration')) ? 0.5 : number('duration'), bounce: ({ smooth: 0, snappy: 0.15, bouncy: 0.3 } as Record<string, number>)[name] + bounce }
  }
  if (name === 'spring' || name === 'interactiveSpring') {
    if (!Number.isNaN(number('response'))) return { kind: 'spring', duration: number('response'), bounce: 1 - (Number.isNaN(number('dampingFraction')) ? 0.825 : number('dampingFraction')) }
    return { kind: 'spring', duration: Number.isNaN(number('duration')) ? 0.5 : number('duration'), bounce: Number.isNaN(number('bounce')) ? 0 : number('bounce') }
  }
  return null
}

function samples(shape: Shape): [number, number][] {
  if (shape.kind === 'bezier') {
    const [x1, y1, x2, y2] = shape.points
    return Array.from({ length: 41 }, (_, i) => {
      const s = i / 40
      const b = (p1: number, p2: number) => 3 * (1 - s) ** 2 * s * p1 + 3 * (1 - s) * s ** 2 * p2 + s ** 3
      return [b(x1, x2), b(y1, y2)]
    })
  }
  const x = spring(shape.duration, shape.bounce)
  const end = settle(x)
  return Array.from({ length: 61 }, (_, i) => [i / 60, x((i / 60) * end)])
}

function settle(x: (t: number) => number): number {
  for (let t = 0.05; t < 4; t += 0.01) {
    let still = true
    for (let s = t; s < t + 0.3; s += 0.02) if (Math.abs(1 - x(s)) > 0.002) { still = false; break }
    if (still) return t
  }
  return 4
}

const seconds = (shape: Shape) => (shape.kind === 'bezier' ? shape.duration : settle(spring(shape.duration, shape.bounce)))

function Curve({ shape }: { shape: Shape | null }) {
  if (!shape) return <svg className="curve" viewBox="0 0 120 120"><rect className="frame empty" x="0.5" y="0.5" width="119" height="119" rx="10" /></svg>
  const points = samples(shape)
  const min = Math.min(0, ...points.map((p) => p[1])), max = Math.max(1, ...points.map((p) => p[1]))
  const y = (v: number) => 108 - ((v - min) / (max - min)) * 96
  const path = points.map(([px, py], i) => `${i ? 'L' : 'M'}${(12 + px * 96).toFixed(1)},${y(py).toFixed(1)}`).join(' ')
  return (
    <svg className="curve" viewBox="0 0 120 120">
      <rect className="frame" x="0.5" y="0.5" width="119" height="119" rx="10" />
      <line className="guide" x1="12" y1={y(1)} x2="108" y2={y(1)} strokeDasharray="2 3" />
      <line className="guide" x1="12" y1={y(0)} x2="108" y2={y(0)} />
      <path className="path" d={path} strokeWidth="2" strokeLinecap="round" />
    </svg>
  )
}

/** A dot crossing its track and back on the shape's own timing (a Bézier as cubic-bezier, a spring as `linear()`). */
function Demo({ shape }: { shape: Shape }) {
  const [on, setOn] = useState(false)
  const duration = seconds(shape)
  useEffect(() => {
    const id = setInterval(() => setOn((v) => !v), Math.max(1100, duration * 1000 + 700))
    return () => clearInterval(id)
  }, [duration])
  const easing = shape.kind === 'bezier' ? `cubic-bezier(${shape.points.join(',')})` : `linear(${samples(shape).map(([, v]) => v.toFixed(3)).join(', ')})`
  return (
    <div className="track-demo">
      <i style={{ transform: `translateX(${on ? 'calc(100cqw - 22px)' : '0'})`, transition: `transform ${duration}s ${easing}` }} />
    </div>
  )
}

export function Motion() {
  const { catalog } = useCatalog()
  const t = useT()
  useHashScroll()
  const groups = [...new Set(catalog.tokens.motions.map((m) => m.group))]
  const inline = catalog.literals.animation

  return (
    <div className="page">
      <div className="eyebrow">{t('Temeller', 'Foundations')}</div>
      <h1 className="title">{t('Hareket', 'Motion')}</h1>
      <p className="lede">{t(
        'Hareket token\'ları Dynamic Island\'da: NotchMotion\'ın yayları ada büyürken hafifçe taşar, küçülürken taşmaz. Uygulamanın geri kalanı animasyonları satır içinde yazar; en çok .easeOut(duration: 0.15). Eğriler uygulamanın kendi formülüyle çizilir; nokta aynı eğriyle oynar.',
        'The motion tokens are the Dynamic Island\'s: NotchMotion\'s springs overshoot a little as the island grows and never as it shrinks. The rest of the app writes its animations inline, most often .easeOut(duration: 0.15). The curves are drawn with the app\'s own formula; the dot plays the same curve.',
      )}</p>
      {groups.map((group) => {
        const tokens = catalog.tokens.motions.filter((m) => m.group === group)
        return (
          <div key={group}>
            <h2 className="section" id={group}>{group} <span className="count">{tokens.length}</span></h2>
            <div className="grid cols-2">
              {tokens.map((token) => <MotionCard key={token.id} token={token} />)}
            </div>
          </div>
        )
      })}

      <h2 className="section">{t('Satır içi animasyonlar', 'Inline animations')} <span className="count">{inline.length}</span></h2>
      <p className="section-note">{t('Her biri yazıldığı haliyle; sayıya tıklayınca yerleri açılır.', 'Each as it\'s written; click a count for its places.')}</p>
      <div className="panel">
        <table className="table">
          <thead><tr><th>{t('Eğri', 'Curve')}</th><th>{t('Animasyon', 'Animation')}</th><th>{t('Oynat', 'Play')}</th><th className="num">{t('Yer', 'Places')}</th><th className="num">{t('Dosya', 'Files')}</th></tr></thead>
          <tbody>
            {inline.map((g) => {
              const shape = shapeOf(g.key)
              return (
                <tr key={g.key}>
                  <td style={{ width: 64 }}><div style={{ width: 48, height: 48 }}><Curve shape={shape} /></div></td>
                  <td><code>{g.key}</code></td>
                  <td style={{ width: 200 }}>{shape && <Demo shape={shape} />}</td>
                  <td className="num"><Link to={`/degerler/animation?deger=${encodeURIComponent(g.key)}`}>{g.count}</Link></td>
                  <td className="num muted">{g.files}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function MotionCard({ token }: { token: MotionToken }) {
  const t = useT()
  const shape: Shape | null = token.kind === 'spring' && token.duration !== null && token.bounce !== null ? { kind: 'spring', duration: token.duration, bounce: token.bounce } : null
  const summary = token.kind === 'spring' ? `${t('yay', 'spring')} · duration ${token.duration} · bounce ${token.bounce}` : token.kind === 'seconds' ? `${token.value} s` : `${token.value}`
  return (
    <div className="panel padded" id={token.id} style={{ display: 'grid', gridTemplateColumns: shape ? '120px 1fr' : '1fr', gap: 16 }}>
      {shape && <Curve shape={shape} />}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, minWidth: 0 }}>
        <div className="variant-head">
          <code>{token.id.split('.').pop()}</code>
          <span className="actions"><SourceLink file={token.source.file} line={token.source.line}>{t('kaynak', 'source')}</SourceLink></span>
        </div>
        <div className="mono muted">{summary}</div>
        <Doc text={token.doc} />
        {shape && <Demo shape={shape} />}
        <div className="variant-head">
          <span className="mono muted">{t.n(token.usage.total, 'kullanım', 'use')}</span>
          <span className="actions"><NoteButton item={token.id} label={t('Not', 'Note')} /></span>
        </div>
      </div>
    </div>
  )
}
