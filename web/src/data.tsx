// The catalog and the viewer's settings, for every page: which theme the renders show and the site takes (Tema: Koyu,
// Koyu | Açık, Açık; Açık makes the whole site light), the language of the renders and of the site's
// own copy (Dil: TR · EN), the components as a grid or a list, and the sidebar hidden and its width. Settings stay in
// localStorage.
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Catalog, Component, Surface } from '../collector/schema.ts'

export type ThemeMode = 'dark' | 'light' | 'split'
export type Language = 'tr' | 'en'

export type Settings = {
  theme: ThemeMode
  language: Language
  componentView: 'grid' | 'list'
  collapsed: boolean
  sidebarWidth: number
}

type Context = {
  catalog: Catalog
  settings: Settings
  set: (change: Partial<Settings>) => void
  component: (id: string) => Component | undefined
  surface: (id: string) => Surface | undefined
}

const CatalogContext = createContext<Context | null>(null)
const key = 'beacon-kit'
const initial: Settings = { theme: 'split', language: 'tr', componentView: 'grid', collapsed: false, sidebarWidth: 280 }

const stored = (): Settings => {
  try {
    return { ...initial, ...JSON.parse(localStorage.getItem(key) ?? '{}') }
  } catch {
    return initial
  }
}

export function CatalogProvider({ children }: { children: ReactNode }) {
  const [catalog, setCatalog] = useState<Catalog | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [settings, setSettings] = useState<Settings>(stored)

  useEffect(() => {
    fetch('/data/catalog.json')
      .then((response) => (response.ok ? response.json() : Promise.reject(new Error(`${response.status}`))))
      .then(setCatalog)
      .catch((e: Error) => setError(e.message))
  }, [])

  useEffect(() => { localStorage.setItem(key, JSON.stringify(settings)) }, [settings])
  useEffect(() => { document.documentElement.lang = settings.language }, [settings.language])
  useEffect(() => {
    // index.html replays it before the first paint.
    const appearance = settings.theme === 'light' ? 'light' : 'dark'
    document.documentElement.dataset.appearance = appearance
    localStorage.setItem(`${key}-appearance`, appearance)
  }, [settings.theme])

  const value = useMemo<Context | null>(() => catalog && {
    catalog,
    settings,
    set: (change) => setSettings((current) => ({ ...current, ...change })),
    component: (id) => catalog.components.find((c) => c.id === id),
    surface: (id) => catalog.surfaces.find((s) => s.id === id),
  }, [catalog, settings])

  const t = translate(settings.language)
  if (error) return <div className="boot">{t('Katalog yüklenemedi', 'The catalog didn\'t load')} ({error}). {t('Çalıştı mı:', 'Has it run:')} <code>npm run collect</code>?</div>
  if (!value) return <div className="boot"><span className="boot-mark" />{t('BeaconKit™ yükleniyor…', 'Loading BeaconKit™…')}</div>
  return <CatalogContext.Provider value={value}>{children}</CatalogContext.Provider>
}

export function useCatalog(): Context {
  const context = useContext(CatalogContext)
  if (!context) throw new Error('useCatalog outside CatalogProvider')
  return context
}

/** The text of a `{ tr, en }` in the viewer's language. */
export function useText() {
  const { settings } = useCatalog()
  return (text: { tr: string; en: string } | null | undefined, fallback = '') => (text ? text[settings.language] : fallback)
}

/**
 * The site's own copy in the viewer's language, written in both where it's used: `t('Renkler', 'Colours')`. Its helpers
 * write a count with its noun, a percentage, a date and how long ago.
 */
export type Translate = ((tr: string, en: string) => string) & {
  language: Language
  /** "3 kullanım" / "3 uses", "1 use": English pluralises, Turkish doesn't after a number. */
  n: (count: number, tr: string, one: string, many?: string) => string
  percent: (value: number) => string
  date: (iso: string, options?: Intl.DateTimeFormatOptions) => string
  since: (iso: string | null) => string
  number: (value: number) => string
}

export function translate(language: Language): Translate {
  const t = (tr: string, en: string) => (language === 'en' ? en : tr)
  const locale = language === 'en' ? 'en-GB' : 'tr-TR'
  const n = (count: number, tr: string, one: string, many = `${one}s`) => `${count.toLocaleString(locale)} ${language === 'en' ? (count === 1 ? one : many) : tr}`
  return Object.assign(t, {
    language,
    n,
    percent: (value: number) => (language === 'en' ? `${value}%` : `%${value}`),
    date: (iso: string, options: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short', year: 'numeric' }) =>
      new Date(iso).toLocaleString(locale, options),
    since: (iso: string | null) => {
      if (!iso) return t('commit edilmedi', 'not committed')
      const days = Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000)
      if (days <= 0) return t('bugün', 'today')
      if (days === 1) return t('dün', 'yesterday')
      if (days < 14) return t(`${days} gün önce`, `${days} days ago`)
      return new Date(iso).toLocaleDateString(locale, { day: 'numeric', month: 'short', year: 'numeric' })
    },
    /** Numbers as the source writes them (`0.5`, never the locale's `0,5`): they're code. */
    number: (value: number) => String(value),
  })
}

export function useT(): Translate {
  const { settings } = useCatalog()
  return useMemo(() => translate(settings.language), [settings.language])
}

/** Where an item is used, by area: the catalog's titles (swift.ts › areaTitles). */
export function useAreaTitle() {
  const { catalog, settings } = useCatalog()
  return (id: string) => catalog.areas[id]?.[settings.language] ?? id
}

/** The page a token, component or surface id opens. */
export function routeFor(catalog: Catalog, id: string): string {
  if (catalog.components.some((c) => c.id === id)) return `/bilesen/${encodeURIComponent(id)}`
  if (catalog.surfaces.some((s) => s.id === id)) return `/yuzey/${encodeURIComponent(id)}`
  const group = id.split('.')[0]
  if (catalog.tokens.colors.some((c) => c.id === id || c.group === id) || catalog.tokens.gradients.some((g) => g.id === id)) return `/renkler#${id}`
  if (catalog.tokens.textStyles.some((s) => s.id === id)) return `/tipografi#${id}`
  if (catalog.tokens.metrics.some((m) => m.id === id || m.group === id)) return `/olculer#${id}`
  if (catalog.tokens.motions.some((m) => m.id === id || m.group === id)) return `/hareket#${id}`
  if (catalog.tokens.palettes.some((p) => p.group === group)) return `/renkler#${id}`
  return '/'
}
