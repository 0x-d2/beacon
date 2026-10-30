// The bench: the catalog's sections on the left (hidden with the top bar's first button or ⌘B, as wide as its edge is
// dragged), the viewer's settings and the search on top, the page in between.
import { useEffect, useRef, useState, type CSSProperties, type PointerEvent, type KeyboardEvent as KeyEvent, type RefObject } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useCatalog, useT, useText, type ThemeMode } from '../data.tsx'
import { SearchPalette } from './Search.tsx'

export function Layout() {
  const { catalog, settings, set } = useCatalog()
  const text = useText()
  const t = useT()
  const [searching, setSearching] = useState(false)
  const { pathname } = useLocation()
  const shell = useRef<HTMLDivElement>(null)

  useEffect(() => { if (!location.hash) window.scrollTo(0, 0) }, [pathname])
  useEffect(() => {
    const key = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault()
        setSearching(true)
      }
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'b') {
        event.preventDefault()
        set({ collapsed: !settings.collapsed })
      }
      if (event.key === '/' && !(event.target instanceof HTMLInputElement)) {
        event.preventDefault()
        setSearching(true)
      }
    }
    window.addEventListener('keydown', key)
    return () => window.removeEventListener('keydown', key)
  }, [settings.collapsed])

  const count = (category: string) => catalog.components.filter((c) => c.category === category).length
  const literalCount = (kind: keyof typeof catalog.literals) => catalog.literals[kind].reduce((n, g) => n + g.count, 0)
  const literalTotal = (Object.keys(catalog.literals) as (keyof typeof catalog.literals)[]).reduce((n, kind) => n + literalCount(kind), 0)

  return (
    <div ref={shell} className={`shell${settings.collapsed ? ' collapsed' : ''}`}
      style={{ '--sidebar': `${sidebarWidth(settings.sidebarWidth)}px` } as CSSProperties}>
      <aside id="sidebar" className="sidebar" inert={settings.collapsed}>
        <div className="sidebar-inner">
          <NavLink to="/" className="brand">
            <span className="brand-mark"><i /></span>
            <span><b>BeaconKit™</b><small><span lang="en">Vorssaint</span> · {t('tasarım sistemi', 'design system')}</small></span>
          </NavLink>
          <nav className="nav">
            <div className="nav-section">
              <div className="nav-title">{t('Başlarken', 'Start here')}</div>
              <NavLink to="/" end>{t('Genel bakış', 'Overview')}</NavLink>
              <NavLink to="/nereden">{t('Neyi nereden değiştiririm', 'What to change where')} <span className="count">{catalog.guide.length}</span></NavLink>
            </div>
            <div className="nav-section">
              <div className="nav-title">{t('Temeller', 'Foundations')}</div>
              <NavLink to="/renkler">{t('Renkler', 'Colours')} <span className="count">{catalog.tokens.colors.length + catalog.tokens.gradients.length}</span></NavLink>
              <NavLink to="/tipografi">{t('Tipografi', 'Typography')} <span className="count">{catalog.literals.font.length}</span></NavLink>
              <NavLink to="/olculer">{t('Ölçüler', 'Metrics')} <span className="count">{catalog.tokens.metrics.length + catalog.tokens.landmarks.length}</span></NavLink>
              <NavLink to="/malzemeler">{t('Malzemeler', 'Materials')} <span className="count">{catalog.literals.material.length}</span></NavLink>
              <NavLink to="/hareket">{t('Hareket', 'Motion')} <span className="count">{catalog.tokens.motions.length}</span></NavLink>
            </div>
            <div className="nav-section">
              <div className="nav-title">{t('Bileşenler', 'Components')}</div>
              <NavLink to="/bilesenler" end>{t('Tümü', 'All')} <span className="count">{catalog.components.length}</span></NavLink>
              {catalog.categories.map((category) => (
                <NavLink key={category.id} to={`/bilesenler/${category.id}`}>
                  {text(category.title)} <span className="count">{count(category.id)}</span>
                </NavLink>
              ))}
            </div>
            <div className="nav-section">
              <div className="nav-title">{t('Yüzeyler', 'Surfaces')}</div>
              {catalog.surfaceGroups.map((group) => (
                <NavLink key={group.id} to={`/yuzeyler/${group.id}`}>
                  {text(group.title)} <span className="count">{catalog.surfaces.filter((s) => s.group === group.id).length}</span>
                </NavLink>
              ))}
            </div>
            {catalog.ios && (
              <div className="nav-section">
                <div className="nav-title">iPhone · Beacon</div>
                <NavLink to="/ios/bilesenler">{t('Bileşenler', 'Components')} <span className="count">{catalog.ios.components.length}</span></NavLink>
                <NavLink to="/ios/ekranlar">{t('Ekranlar', 'Screens')} <span className="count">{catalog.ios.screens.length}</span></NavLink>
                <NavLink to="/ios/renkler">{t('Renkler', 'Colours')} <span className="count">{catalog.ios.colors.length}</span></NavLink>
              </div>
            )}
            <div className="nav-section">
              <div className="nav-title">{t('İnceleme', 'Review')}</div>
              <NavLink to="/degerler">{t('Satır içi değerler', 'Inline values')} <span className="count">{literalTotal.toLocaleString(t.language)}</span></NavLink>
              <NavLink to="/degisiklikler">{t('Değişiklikler', 'Changes')} <span className="count">{catalog.changes.length}</span></NavLink>
            </div>
          </nav>
        </div>
      </aside>
      {!settings.collapsed && <SidebarResizer shell={shell} />}
      <div className="main">
        <header className="topbar">
          <button className="icon-button" aria-controls="sidebar" aria-expanded={!settings.collapsed}
            aria-label={settings.collapsed ? t('Kenar çubuğunu göster', 'Show the sidebar') : t('Kenar çubuğunu gizle', 'Hide the sidebar')}
            title={`${settings.collapsed ? t('Kenar çubuğunu göster', 'Show the sidebar') : t('Kenar çubuğunu gizle', 'Hide the sidebar')} (⌘B)`}
            onClick={() => set({ collapsed: !settings.collapsed })}>
            <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true">
              <rect x="1.5" y="2.5" width="13" height="11" rx="2" fill="none" stroke="currentColor" strokeWidth="1.3" />
              <line x1="6" y1="2.5" x2="6" y2="13.5" stroke="currentColor" strokeWidth="1.3" />
            </svg>
          </button>
          <button className="search-trigger" onClick={() => setSearching(true)}>
            <span className="label">⌕ {t('Bileşen, token, yüzey, değer ara', 'Search components, tokens, surfaces, values')}</span> <kbd>⌘K</kbd>
          </button>
          <span className="spacer" />
          <span className="segmented-label">{t('Tema', 'Theme')}</span>
          <Segmented value={settings.theme} onChange={(theme) => set({ theme })}
            options={[['dark', t('Koyu', 'Dark')], ['split', t('Koyu | Açık', 'Dark | Light')], ['light', t('Açık', 'Light')]] as [ThemeMode, string][]} />
          <span className="segmented-label">{t('Dil', 'Language')}</span>
          <Segmented value={settings.language} onChange={(language) => set({ language })}
            options={catalog.meta.languages.map((l) => [l as 'tr' | 'en', l.toUpperCase()])} />
          <a className="meta-chip" href={`https://github.com/${catalog.meta.repo}/commit/${catalog.meta.sha}`} target="_blank" rel="noreferrer"
            title={`${catalog.meta.branch} · ${t.date(catalog.meta.builtAt, { dateStyle: 'medium', timeStyle: 'short' })}`}>
            <b>{catalog.meta.sha.slice(0, 7)}</b>{catalog.meta.dirty ? t(' +değişiklik', ' +changes') : ''}
          </a>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
      {searching && <SearchPalette onClose={() => setSearching(false)} />}
    </div>
  )
}

export function Segmented<T extends string>({ value, options, onChange }: {
  value: T; options: [T, string][]; onChange: (value: T) => void
}) {
  return (
    <div className="segmented" role="radiogroup">
      {options.map(([key, label]) => (
        <button key={key} role="radio" aria-checked={value === key} className={value === key ? 'on' : ''} onClick={() => onChange(key)}>
          {label}
        </button>
      ))}
    </div>
  )
}

// MARK: The sidebar's edge

const widths = { min: 200, max: 480, initial: 280 }
const sidebarWidth = (width: number) => Math.round(Math.min(widths.max, Math.max(widths.min, Number(width) || widths.initial)))

/**
 * The sidebar's right edge: a hairline that shows a pill on hover and drags the sidebar's width. While dragging only
 * the shell's `--sidebar` changes; the width is kept on release. Arrows step it, a double click goes back to 280.
 */
function SidebarResizer({ shell }: { shell: RefObject<HTMLDivElement | null> }) {
  const { settings, set } = useCatalog()
  const t = useT()
  const width = sidebarWidth(settings.sidebarWidth)
  const drag = useRef<{ x: number; width: number; now: number } | null>(null)

  const start = (event: PointerEvent<HTMLDivElement>) => {
    if (event.button !== 0) return
    event.preventDefault()
    event.currentTarget.setPointerCapture(event.pointerId)
    drag.current = { x: event.clientX, width, now: width }
    shell.current?.classList.add('resizing')
  }
  const move = (event: PointerEvent<HTMLDivElement>) => {
    if (!drag.current) return
    drag.current.now = sidebarWidth(drag.current.width + event.clientX - drag.current.x)
    shell.current?.style.setProperty('--sidebar', `${drag.current.now}px`)
  }
  const end = () => {
    if (!drag.current) return
    shell.current?.classList.remove('resizing')
    set({ sidebarWidth: drag.current.now })
    drag.current = null
  }
  const onKey = (event: KeyEvent) => {
    const next = ({ ArrowLeft: width - 10, ArrowRight: width + 10, Home: widths.min, End: widths.max } as Record<string, number>)[event.key]
    if (next === undefined) return
    event.preventDefault()
    set({ sidebarWidth: sidebarWidth(next) })
  }

  return (
    <div className="sidebar-resize" role="separator" aria-orientation="vertical" aria-controls="sidebar" tabIndex={0}
      aria-label={t('Kenar çubuğunun genişliği', 'Sidebar width')} aria-valuenow={width} aria-valuemin={widths.min} aria-valuemax={widths.max}
      title={t('Sürükleyerek genişliğini değiştirin; çift tıklayınca varsayılana döner', 'Drag to resize; a double click goes back to the default')}
      onPointerDown={start} onPointerMove={move} onPointerUp={end} onPointerCancel={end} onKeyDown={onKey}
      onDoubleClick={() => set({ sidebarWidth: widths.initial })} />
  )
}
