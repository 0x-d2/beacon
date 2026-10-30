import { Link } from 'react-router-dom'
import type { LiteralKind } from '../../collector/schema.ts'
import { useCatalog, useT, useText } from '../data.tsx'
import { literalTitles, RenderStamp, shortPath } from '../ui/bits.tsx'
import { Thumb } from '../ui/Stage.tsx'

export function Overview() {
  const { catalog, settings } = useCatalog()
  const text = useText()
  const t = useT()
  const tokens = catalog.tokens
  const tokenCount = tokens.colors.length + tokens.gradients.length + tokens.textStyles.length + tokens.metrics.length + tokens.motions.length
  const literalTotal = Object.values(catalog.literals).reduce((n, groups) => n + groups.reduce((m, g) => m + g.count, 0), 0)
  const top = (kind: LiteralKind) => catalog.literals[kind].filter((g) => !g.key.includes('(değişken)'))[0]
  const variants = catalog.components.reduce((n, c) => n + c.variants.length, 0)
  const recent = [...catalog.components].filter((c) => c.lastChange).sort((a, b) => (b.lastChange! > a.lastChange! ? 1 : -1)).slice(0, 8)
  const accent = catalog.systemColors.find((c) => c.id === 'accentColor')

  return (
    <div className="page">
      <div className="eyebrow"><span lang="en">Vorssaint</span> · macOS 14+ · {t('menü çubuğu uygulaması', 'menu bar app')}</div>
      <h1 className="title">BeaconKit™</h1>
      <p className="lede">{t(
        'Uygulamanın tasarım sistemi, kodda nasılsa öyle: az sayıda token, onları kullanan bileşenler, bileşenlerden kurulan yüzeyler ve görünümün büyük kısmını taşıyan satır içi değerler. Bu site kaynak koddan üretilir; her öğe tanımlandığı satıra bağlanır, böylece neyi nereden değiştireceğinizi buradan bulursunuz.',
        'The app\'s design system as the code has it: a few tokens, the components that use them, the surfaces built from those components, and the inline values that carry most of the look. This site is generated from the source; every item links to the line that declares it, so this is where you find what to change where.',
      )}</p>
      <div className="stamps">
        <RenderStamp label={t('Bileşen görüntüleri', 'Component images')} render={catalog.meta.renders.components} />
        <RenderStamp label={t('Yüzey görüntüleri', 'Surface images')} render={catalog.meta.renders.surfaces} />
        <span className="stamp">{t('Sistem renkleri: macOS', 'System colours: macOS')} {catalog.meta.systemColors}</span>
      </div>
      <div className="stats">
        <Link className="stat" to="/bilesenler"><b>{catalog.components.length}</b><span>{t('Bileşen', 'Components')}</span></Link>
        <Link className="stat" to="/yuzeyler/panel"><b>{catalog.surfaces.length}</b><span>{t('Yüzey', 'Surfaces')}</span></Link>
        <Link className="stat" to="/renkler"><b>{tokenCount}</b><span>{t('Token', 'Tokens')}</span></Link>
        <Link className="stat" to="/degerler"><b>{literalTotal.toLocaleString(t.language)}</b><span>{t('Satır içi değer', 'Inline values')}</span></Link>
        <div className="stat"><b>{variants}</b><span>{t('Görüntülü hâl', 'Rendered variants')}</span></div>
        <div className="stat"><b>{catalog.issues.length}</b><span>{t('Açık not', 'Open notes')}</span></div>
      </div>

      <h2 className="section">{t('Bir bakışta', 'At a glance')}</h2>
      <p className="section-note">{t('Görünümün nerede yaşadığı, kodun kendi sayılarıyla.', 'Where the look lives, in the code\'s own numbers.')}</p>
      <div className="grid cols-3">
        <Fact to="/renkler" title={t('Token\'lar tek dosyada', 'The tokens live in one file')}
          body={t(
            `UI/Theme.swift: ${tokens.colors.filter((c) => c.group === 'PanelMetricColor').length} metrik rengi, ${tokens.colors.filter((c) => c.group === 'PanelSurface').length} yüzey rengi, bölüm başlığı ve .panelCard(). Hepsi açık ve koyu tema için ayrı değer verir.`,
            `UI/Theme.swift: ${tokens.colors.filter((c) => c.group === 'PanelMetricColor').length} metric colours, ${tokens.colors.filter((c) => c.group === 'PanelSurface').length} surface colours, the section title and .panelCard(). Each gives a light and a dark value.`,
          )} />
        <Fact to="/renkler#system" title={t('Vurgu rengi sistemin', 'The accent is the system\'s')}
          body={t(
            `Uygulamanın kendi vurgu rengi yok: Color.accentColor ${accent?.count ?? 0} yerde. Kullanıcının Sistem Ayarları'ndaki rengi neyse o.`,
            `The app has no accent of its own: Color.accentColor in ${accent?.count ?? 0} places, whatever the user picked in System Settings.`,
          )} />
        <Fact to="/degerler" title={t('Gerisi satır içinde', 'The rest is inline')}
          body={t(
            `${literalTotal.toLocaleString('tr-TR')} değer view'lara doğrudan yazılmış. En çok: köşe ${top('radius')?.key} (${top('radius')?.count}), yazı ${top('font')?.key} (${top('font')?.count}), animasyon ${top('animation')?.key} (${top('animation')?.count}).`,
            `${literalTotal.toLocaleString('en-GB')} values are typed into the views. Most common: corner ${top('radius')?.key} (${top('radius')?.count}), type ${top('font')?.key} (${top('font')?.count}), animation ${top('animation')?.key} (${top('animation')?.count}).`,
          )} />
      </div>

      <h2 className="section">{t('Nereden başlamalı', 'Where to start')}</h2>
      <div className="grid cols-4">
        <Start to="/nereden" title={t('Neyi nereden değiştiririm', 'What to change where')} body={t(`${catalog.guide.length} madde: görünümün bir parçası → onu belirleyen satır.`, `${catalog.guide.length} entries: a part of the look → the line that sets it.`)} />
        <Start to="/yuzeyler/panel" title={t('Menü paneli', 'The menu panel')} body={t('12 sekme; her biri hangi dosyada, hangi bileşenlerle.', '12 tabs; each one\'s file and components.')} />
        <Start to="/bilesenler" title={t('Bileşenler', 'Components')} body={t('Birden çok yerde kullanılan view\'lar, modifier\'lar ve stiller.', 'The views, modifiers and styles used in more than one place.')} />
        <Start to="/degerler/radius" title={t('Satır içi değerler', 'Inline values')} body={t('Her köşe, yazı boyutu, boşluk ve animasyon, yazıldığı yerle.', 'Every corner, font size, spacing and animation, with where it\'s written.')} />
      </div>

      <h2 className="section">{t('Kategoriler', 'Categories')}</h2>
      <div className="grid cols-3">
        {catalog.categories.map((category) => {
          const items = catalog.components.filter((c) => c.category === category.id)
          const owner = items.find((c) => c.variants.some((v) => Object.keys(v.images).length)) ?? items[0]
          return (
            <Link key={category.id} to={`/bilesenler/${category.id}`} className="card">
              <Thumb images={owner?.variants[0]?.images} title={owner?.id ?? ''} subtitle={owner ? shortPath(owner.source.file) : undefined} />
              <div className="body"><b>{text(category.title)}</b><span>{t.n(items.length, 'bileşen', 'component')}</span></div>
            </Link>
          )
        })}
      </div>

      <div className="grid cols-2" style={{ marginTop: 48 }}>
        <div>
          <h3 className="sub">{t('Son değişen bileşenler', 'Recently changed components')}</h3>
          <div className="panel">
            <table className="table">
              <tbody>
                {recent.map((c) => (
                  <tr key={c.id}><td><Link to={`/bilesen/${encodeURIComponent(c.id)}`}>{c.id}</Link></td><td className="num muted">{t.since(c.lastChange)}</td></tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
        <div>
          <h3 className="sub">{t('Satır içi değerler, türe göre', 'Inline values by kind')}</h3>
          <div className="panel">
            <table className="table">
              <tbody>
                {(Object.keys(catalog.literals) as LiteralKind[]).map((kind) => (
                  <tr key={kind}>
                    <td><Link to={`/degerler/${kind}`}>{literalTitles[kind][settings.language]}</Link></td>
                    <td className="num">{catalog.literals[kind].reduce((n, g) => n + g.count, 0)}</td>
                    <td className="num muted">{t.n(catalog.literals[kind].length, 'farklı değer', 'distinct value')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}

function Fact({ to, title, body }: { to: string; title: string; body: string }) {
  return (
    <Link to={to} className="card">
      <div className="body"><b>{title}</b><div className="doc">{body}</div></div>
    </Link>
  )
}

function Start({ to, title, body }: { to: string; title: string; body: string }) {
  return (
    <Link to={to} className="card">
      <div className="body"><b>{title} →</b><div className="doc">{body}</div></div>
    </Link>
  )
}
