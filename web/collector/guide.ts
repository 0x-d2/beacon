// "Neyi nereden değiştiririm" (docs/beaconkit.md › Guide): the owner's map from a look to the line that sets it. Each
// entry names a file and what to find in it, not a line number: the collector looks the line up on every run, so the
// map follows the code, and an entry whose text has gone away is reported (`npm run collect` warns) rather than
// pointing at the wrong line. The landmarks are the layout numbers the site lists beside the tokens (Ölçüler).
import type { Localized } from './strings.ts'
import type { SourceFile } from './swift.ts'

export type GuideEntry = {
  id: string
  area: Localized
  what: Localized
  how: Localized
  file: string
  line: number | null
  code: string | null
  /** The token or component the entry is about, for a link to its page. */
  link: string | null
}

type Entry = Omit<GuideEntry, 'line' | 'code'> & { find: RegExp }

const ui = 'Sources/Vorssaint/UI'
const entries: Entry[] = [
  {
    id: 'panel-card', area: { tr: 'Menü paneli', en: 'Menu panel' },
    what: { tr: 'Kartların zemini, kenar çizgisi, köşesi ve iç boşluğu', en: 'The cards\' fill, outline, corner and padding' },
    how: { tr: 'Zemin ve çizgi PanelSurface.cardFill / border\'da; köşe (10) ve boşluk (10, adada 12) PanelCardModifier\'da.', en: 'Fill and outline in PanelSurface.cardFill / border; the corner (10) and padding (10, 12 in the island) in PanelCardModifier.' },
    file: `${ui}/Theme.swift`, find: /private struct PanelCardModifier/, link: '.panelCard()',
  },
  {
    id: 'metric-colors', area: { tr: 'Menü paneli', en: 'Menu panel' },
    what: { tr: 'Grafik ve ölçü renkleri (CPU yeşil, ağ camgöbeği…)', en: 'Chart and meter colours (CPU green, network cyan…)' },
    how: { tr: 'Açık temada koyulaştırılmış RGB, koyu temada sistem rengi; her biri bir satır.', en: 'A darkened RGB in light mode, the system colour in dark mode; one line each.' },
    file: `${ui}/Theme.swift`, find: /^enum PanelMetricColor/, link: 'PanelMetricColor',
  },
  {
    id: 'section-title', area: { tr: 'Menü paneli', en: 'Menu panel' },
    what: { tr: 'BÜYÜK HARFLİ bölüm başlıkları', en: 'The UPPERCASE section titles' },
    how: { tr: '10 pt semibold, 0.5 harf aralığı, ikincil renk.', en: '10 pt semibold, 0.5 tracking, secondary colour.' },
    file: `${ui}/Theme.swift`, find: /^func sectionTitle/, link: 'sectionTitle',
  },
  {
    id: 'panel-size', area: { tr: 'Menü paneli', en: 'Menu panel' },
    what: { tr: 'Panelin genişliği (332) ve içerik genişliği (308)', en: 'The panel\'s width (332) and content width (308)' },
    how: { tr: 'navigablePanel\'deki .frame(width:) değerleri; ikisi birlikte değişmeli (12 + 308 + 12).', en: 'The .frame(width:) values in navigablePanel; change them together (12 + 308 + 12).' },
    file: `${ui}/MenuPanel/MenuPanelView.swift`, find: /\.frame\(width: 332/, link: null,
  },
  {
    id: 'panel-glass', area: { tr: 'Menü paneli', en: 'Menu panel' },
    what: { tr: 'Panelin camı: Liquid Glass ya da materyal', en: 'The panel\'s glass: Liquid Glass or material' },
    how: { tr: 'macOS 26\'da ve ayar açıkken .glassEffect, yoksa .regularMaterial + baseFill.', en: 'On macOS 26 with the setting on, .glassEffect; otherwise .regularMaterial + baseFill.' },
    file: `${ui}/Theme.swift`, find: /private struct PanelGlassSurface/, link: '.panelGlassSurface()',
  },
  {
    id: 'panel-rows', area: { tr: 'Menü paneli', en: 'Menu panel' },
    what: { tr: 'Liste satırlarının ikon genişliği, boşlukları, ayraç girintisi', en: 'List rows\' icon width, spacing and separator inset' },
    how: { tr: 'PanelRowMetrics: ikon 22, boşluk 9, yatay girinti 10 (adada 12).', en: 'PanelRowMetrics: icon 22, spacing 9, horizontal inset 10 (12 in the island).' },
    file: `${ui}/MenuPanel/MenuPanelView.swift`, find: /^enum PanelRowMetrics/, link: 'PanelRowMetrics',
  },
  {
    id: 'panel-tabs', area: { tr: 'Menü paneli', en: 'Menu panel' },
    what: { tr: 'Sekmeler: sırası, ikonları, adları', en: 'The tabs: their order, icons and names' },
    how: { tr: 'PanelSectionID\'nin case\'leri ve symbolName; her sekmenin view\'ı MenuPanelView.section(for:)\'da.', en: 'PanelSectionID\'s cases and symbolName; each tab\'s view in MenuPanelView.section(for:).' },
    file: `${ui}/MenuPanel/PanelLayout.swift`, find: /^enum PanelSectionID/, link: null,
  },
  {
    id: 'sparkline', area: { tr: 'Grafikler', en: 'Charts' },
    what: { tr: 'Alan grafiklerinin çizimi (çizgi, dolgu, tavan etiketi)', en: 'How the area graphs draw (line, fill, ceiling label)' },
    how: { tr: 'Sparkline\'ın body\'si; renk her kullanımda PanelMetricColor\'dan verilir.', en: 'Sparkline\'s body; each use passes its colour from PanelMetricColor.' },
    file: `${ui}/MenuPanel/Sparkline.swift`, find: /^struct Sparkline/, link: 'Sparkline',
  },
  {
    id: 'usage-bar', area: { tr: 'Grafikler', en: 'Charts' },
    what: { tr: 'Doluluk çubukları ve bellek basıncı göstergesi', en: 'Capacity bars and the memory pressure pill' },
    how: { tr: 'UsageBar ve PressureIndicator, Sistem sekmesinin dosyasında.', en: 'UsageBar and PressureIndicator, in the System tab\'s file.' },
    file: `${ui}/MenuPanel/SystemSection.swift`, find: /^struct UsageBar/, link: 'UsageBar',
  },
  {
    id: 'settings-card', area: { tr: 'Ayarlar', en: 'Settings' },
    what: { tr: 'Ayarlar kartları ve satırları (ikon kutusu, başlık, açıklama)', en: 'Settings cards and rows (icon tile, title, description)' },
    how: { tr: 'SettingsCard, SettingsRow ve kardeşleri; metin girintisi settingsRowTextInset (38).', en: 'SettingsCard, SettingsRow and siblings; the text inset is settingsRowTextInset (38).' },
    file: `${ui}/Settings/SettingsCard.swift`, find: /^struct SettingsCard/, link: 'SettingsCard',
  },
  {
    id: 'settings-window', area: { tr: 'Ayarlar', en: 'Settings' },
    what: { tr: 'Ayarlar penceresinin en küçük boyutu (772 × 528)', en: 'The Settings window\'s minimum size (772 × 528)' },
    how: { tr: 'SettingsView\'daki .frame(minWidth:minHeight:).', en: '.frame(minWidth:minHeight:) in SettingsView.' },
    file: `${ui}/Settings/SettingsView.swift`, find: /\.frame\(minWidth: 772/, link: null,
  },
  {
    id: 'settings-sidebar', area: { tr: 'Ayarlar', en: 'Settings' },
    what: { tr: 'Kenar çubuğundaki sayfalar, adları ve ikonları', en: 'The sidebar\'s pages, their names and icons' },
    how: { tr: 'SettingsDirectoryItem(page:title:icon:) satırları.', en: 'The SettingsDirectoryItem(page:title:icon:) lines.' },
    file: `${ui}/Settings/SettingsDirectory.swift`, find: /SettingsDirectoryItem\(page: \.general/, link: null,
  },
  {
    id: 'hud', area: { tr: 'Yüzen araçlar', en: 'Floating tools' },
    what: { tr: 'Yüzen panellerin arka planı (HUD materyali, yüksek kontrast plakası)', en: 'The floating panels\' backdrop (HUD material, high-contrast plate)' },
    how: { tr: 'HUDBackdrop; NSVisualEffectView .hudWindow ile.', en: 'HUDBackdrop, with an NSVisualEffectView .hudWindow.' },
    file: `${ui}/SharedUI.swift`, find: /^struct HUDBackdrop\b/, link: 'HUDBackdrop',
  },
  {
    id: 'keycaps', area: { tr: 'Ortak', en: 'Shared' },
    what: { tr: 'Kısayol tuş kapakları (⌘ ⌥ …)', en: 'Shortcut keycaps (⌘ ⌥ …)' },
    how: { tr: 'KeyCap ve ShortcutCaps.', en: 'KeyCap and ShortcutCaps.' },
    file: `${ui}/SharedUI.swift`, find: /^struct KeyCap/, link: 'KeyCap',
  },
  {
    id: 'notch-motion', area: { tr: 'Dynamic Island', en: 'Dynamic Island' },
    what: { tr: 'Adanın büyüme / küçülme yayları', en: 'The island\'s growing and shrinking springs' },
    how: { tr: 'NotchMotion: süre ve sekme (bounce); büyürken taşar, küçülürken taşmaz.', en: 'NotchMotion: duration and bounce; it overshoots growing, never shrinking.' },
    file: 'Sources/Vorssaint/Services/Notch/NotchSupport.swift', find: /^enum NotchMotion/, link: 'NotchMotion',
  },
  {
    id: 'notch-components', area: { tr: 'Dynamic Island', en: 'Dynamic Island' },
    what: { tr: 'Adanın düğmeleri, hapları, şeritleri, yüzeyi', en: 'The island\'s buttons, pills, rails and surface' },
    how: { tr: 'NotchComponents.swift: NotchButtonStyle, NotchIconButton, NotchPillButton, NotchControlSurface…', en: 'NotchComponents.swift: NotchButtonStyle, NotchIconButton, NotchPillButton, NotchControlSurface…' },
    file: `${ui}/Notch/NotchComponents.swift`, find: /^struct NotchButtonStyle/, link: 'NotchButtonStyle',
  },
  {
    id: 'appearance', area: { tr: 'Uygulama geneli', en: 'App-wide' },
    what: { tr: 'Açık / koyu / sistem görünümü', en: 'Light / dark / system appearance' },
    how: { tr: 'AppAppearance seçimi, NSApp.appearance\'a AppAppearanceController uygular. Ada her zaman koyu.', en: 'The AppAppearance choice; AppAppearanceController applies it to NSApp.appearance. The island is always dark.' },
    file: 'Sources/Vorssaint/Core/AppAppearance.swift', find: /^enum AppAppearance/, link: null,
  },
  {
    id: 'accent', area: { tr: 'Uygulama geneli', en: 'App-wide' },
    what: { tr: 'Vurgu rengi', en: 'The accent colour' },
    how: { tr: 'Uygulamanın kendi vurgu rengi yok: Color.accentColor (sistemin, Sistem Ayarları › Görünüm) her yerde kullanılır.', en: 'The app has no accent of its own: Color.accentColor (the system\'s, System Settings › Appearance) everywhere.' },
    file: `${ui}/Theme.swift`, find: /^enum PanelSurface/, link: null,
  },
  {
    id: 'liquid-glass', area: { tr: 'Uygulama geneli', en: 'App-wide' },
    what: { tr: 'Liquid Glass ne zaman açık', en: 'When Liquid Glass is on' },
    how: { tr: 'LiquidGlassSupport: macOS 26 ve ayarlar (liquidGlassEnabled, notchLiquidGlassEnabled).', en: 'LiquidGlassSupport: macOS 26 and the settings (liquidGlassEnabled, notchLiquidGlassEnabled).' },
    file: 'Sources/Vorssaint/Core/LiquidGlassSupport.swift', find: /^enum LiquidGlassSupport|^struct LiquidGlassSupport/, link: null,
  },
  {
    id: 'copy-tr', area: { tr: 'Metinler', en: 'Copy' },
    what: { tr: 'Türkçe metinler', en: 'The Turkish copy' },
    how: { tr: 'Strings.tr; özelliklerin kendi tabloları Core/*Strings.swift\'te (ör. PortManagerStrings).', en: 'Strings.tr; features keep their own tables in Core/*Strings.swift (e.g. PortManagerStrings).' },
    file: 'Sources/Vorssaint/Core/Localizations/Strings+Turkish.swift', find: /static let tr = Strings\(/, link: null,
  },
  {
    id: 'copy-en', area: { tr: 'Metinler', en: 'Copy' },
    what: { tr: 'İngilizce metinler', en: 'The English copy' },
    how: { tr: 'Strings.enUS, Localization.swift\'te; her yeni anahtar 15 dilde de yazılmalı.', en: 'Strings.enUS, in Localization.swift; every new key is written in all 15 languages.' },
    file: 'Sources/Vorssaint/Core/Localization.swift', find: /static let enUS = Strings\(/, link: null,
  },
  {
    id: 'menu-bar', area: { tr: 'Menü çubuğu', en: 'Menu bar' },
    what: { tr: 'Menü çubuğundaki ölçü yazılarının boyutları', en: 'The sizes of the menu bar\'s readings' },
    how: { tr: 'MenuBarRenderer\'ın yazı tipi boyutları (9.4 / 11.6 / 13).', en: 'MenuBarRenderer\'s font sizes (9.4 / 11.6 / 13).' },
    file: 'Sources/Vorssaint/App/MenuBarRenderer.swift', find: /9\.4/, link: null,
  },
  {
    id: 'brand', area: { tr: 'Marka', en: 'Brand' },
    what: { tr: 'Logo ve uygulama rozeti', en: 'The logo and the app badge' },
    how: { tr: 'BrandMark Resources/Brand/logo.png\'yi şablon olarak boyar; BrandBadge onu spaceGradient üstüne koyar.', en: 'BrandMark tints Resources/Brand/logo.png as a template; BrandBadge sets it on spaceGradient.' },
    file: `${ui}/Theme.swift`, find: /^struct BrandMark/, link: 'BrandMark',
  },
]

export function resolveGuide(files: SourceFile[]): { entries: GuideEntry[]; missing: string[] } {
  const byPath = new Map(files.map((f) => [f.path, f]))
  const missing: string[] = []
  const out = entries.map(({ find, ...entry }) => {
    const file = byPath.get(entry.file)
    const index = file ? file.lines.findIndex((l) => find.test(l)) : -1
    if (index < 0) missing.push(`${entry.id} (${entry.file}: ${find})`)
    return { ...entry, line: index >= 0 ? index + 1 : null, code: index >= 0 ? file!.lines[index].trim() : null }
  })
  return { entries: out, missing }
}

/** The layout numbers that aren't tokens but set a whole surface's size: found by the same rule, value read off the line. */
const landmarks: { id: string; title: Localized; file: string; find: RegExp }[] = [
  { id: 'panel.width', title: { tr: 'Panel genişliği', en: 'Panel width' }, file: `${ui}/MenuPanel/MenuPanelView.swift`, find: /\.frame\(width: (332)/ },
  { id: 'panel.contentWidth', title: { tr: 'Panel içerik genişliği', en: 'Panel content width' }, file: `${ui}/MenuPanel/MenuPanelView.swift`, find: /\.frame\(width: (308)\)/ },
  { id: 'settings.minWidth', title: { tr: 'Ayarlar en az genişlik', en: 'Settings minimum width' }, file: `${ui}/Settings/SettingsView.swift`, find: /minWidth: (772)/ },
  { id: 'settings.minHeight', title: { tr: 'Ayarlar en az yükseklik', en: 'Settings minimum height' }, file: `${ui}/Settings/SettingsView.swift`, find: /minHeight: (528)/ },
  { id: 'settings.rowTextInset', title: { tr: 'Ayar satırı metin girintisi', en: 'Settings row text inset' }, file: `${ui}/Settings/SettingsCard.swift`, find: /settingsRowTextInset[^=]*=\s*([0-9.+ ]+?)\s*$/ },
  { id: 'panelCard.cornerRadius', title: { tr: 'Panel kartı köşesi', en: 'Panel card corner' }, file: `${ui}/Theme.swift`, find: /RoundedRectangle\(cornerRadius: ([0-9.]+), style: \.continuous\)/ },
  { id: 'panelCard.padding', title: { tr: 'Panel kartı iç boşluğu', en: 'Panel card padding' }, file: `${ui}/Theme.swift`, find: /\.padding\(padded \? ([0-9.]+) : 0\)$/ },
  { id: 'panelCard.borderWidth', title: { tr: 'Panel kartı çizgi kalınlığı', en: 'Panel card outline width' }, file: `${ui}/Theme.swift`, find: /lineWidth: ([0-9.]+)\)/ },
]

export function resolveLandmarks(files: SourceFile[]) {
  const byPath = new Map(files.map((f) => [f.path, f]))
  return landmarks.flatMap(({ find, ...landmark }) => {
    const file = byPath.get(landmark.file)
    const index = file ? file.lines.findIndex((l) => find.test(l)) : -1
    if (index < 0) return []
    // A sum as written (`26 + 12`) is worked out; anything else stays out of the number.
    const written = file!.lines[index].match(find)![1]
    const value = written.split('+').reduce((sum, part) => sum + Number(part.trim()), 0)
    return [{ ...landmark, value, expression: written.trim(), source: { file: landmark.file, line: index + 1 }, code: file!.lines[index].trim() }]
  })
}
