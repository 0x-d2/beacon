// The surfaces (docs/beaconkit.md › Surfaces): the places the app draws whole, each with the view and file that draw it,
// so "the System tab looks off" leads straight to SystemSection.swift and to the components and inline values in it.
// Read from the app's own switches: the menu panel's tabs (MenuPanelView's `section(for:)`), the Settings pages
// (SettingsView's `detail`), the Dynamic Island's modules (NotchView's `switch service.selected`), and the windows and
// floating tools listed below. Titles are the app's own copy where the source names a `Strings` key.
import { literalCounts, type LiteralKind } from './literals.ts'
import type { Localized } from './strings.ts'
import { blockEnd, codeLines, declarations, docAbove, withoutStrings, withPrivateHelpers, type SourceFile } from './swift.ts'

export type Surface = {
  id: string
  group: 'panel' | 'settings' | 'notch' | 'window'
  case: string
  title: Localized
  symbol: string | null
  view: string
  source: { file: string; line: number }
  doc: string
  components: Record<string, number>
  tokens: Record<string, number>
  literals: Partial<Record<LiteralKind, number>>
}

export const surfaceGroups = [
  { id: 'panel', title: { tr: 'Menü paneli sekmeleri', en: 'Menu panel tabs' } },
  { id: 'settings', title: { tr: 'Ayarlar sayfaları', en: 'Settings pages' } },
  { id: 'notch', title: { tr: 'Dynamic Island modülleri', en: 'Dynamic Island modules' } },
  { id: 'window', title: { tr: 'Pencereler ve yüzen araçlar', en: 'Windows and floating tools' } },
]

/** The windows and floating tools, by the view that draws each. */
const windows: { view: string; title: Localized }[] = [
  { view: 'MenuPanelView', title: { tr: 'Menü paneli', en: 'Menu panel' } },
  { view: 'SettingsView', title: { tr: 'Ayarlar penceresi', en: 'Settings window' } },
  { view: 'OnboardingView', title: { tr: 'Karşılama', en: 'Onboarding' } },
  { view: 'WhatsNewView', title: { tr: 'Yenilikler', en: 'What\'s new' } },
  { view: 'UpdateHighlightsView', title: { tr: 'Güncelleme öne çıkanları', en: 'Update highlights' } },
  { view: 'NotchView', title: { tr: 'Dynamic Island', en: 'Dynamic Island' } },
  { view: 'CommandBarView', title: { tr: 'Komut çubuğu', en: 'Command bar' } },
  { view: 'SwitcherView', title: { tr: 'Uygulama değiştirici', en: 'App switcher' } },
  { view: 'DockPreviewPanelView', title: { tr: 'Dock önizlemesi', en: 'Dock preview' } },
  { view: 'ShelfView', title: { tr: 'Raf', en: 'Shelf' } },
  { view: 'RadialMenuView', title: { tr: 'Dairesel menü', en: 'Radial menu' } },
  { view: 'QuitProtectionHUD', title: { tr: 'Çıkış koruması', en: 'Quit protection' } },
  { view: 'ScreenshotEditorView', title: { tr: 'Ekran görüntüsü düzenleyici', en: 'Screenshot editor' } },
  { view: 'RecorderEditorView', title: { tr: 'Kayıt düzenleyici', en: 'Recording editor' } },
  { view: 'PermissionGuideOverlay', title: { tr: 'İzin rehberi', en: 'Permission guide' } },
]

/** Titles the source builds with a function (`FeatureStrings.brightness(language).pageTitle`), written here once. */
const fallbackTitles: Record<string, Localized> = {
  'panel.brightness': { tr: 'Parlaklık', en: 'Brightness' },
  'panel.fanControl': { tr: 'Fan kontrolü', en: 'Fan control' },
  'panel.toggles': { tr: 'Hızlı anahtarlar', en: 'Quick toggles' },
  'panel.wallpaper': { tr: 'Duvar kâğıdı', en: 'Wallpaper' },
  'settings.features': { tr: 'Özellikler', en: 'Features' },
  'settings.dock': { tr: 'Dock', en: 'Dock' },
  'settings.windowLayout': { tr: 'Pencere yerleşimi', en: 'Window layout' },
  'settings.quitProtection': { tr: 'Çıkış koruması', en: 'Quit protection' },
  'settings.clipboard': { tr: 'Pano', en: 'Clipboard' },
  'settings.cutPaste': { tr: 'Kes ve yapıştır', en: 'Cut and paste' },
  'settings.appUpdates': { tr: 'Uygulama güncellemeleri', en: 'App updates' },
  'settings.killProcess': { tr: 'İşlem sonlandırma', en: 'Kill process' },
  'settings.portManager': { tr: 'Port yöneticisi', en: 'Port manager' },
  'settings.notch': { tr: 'Dynamic Island', en: 'Dynamic Island' },
  'settings.notchMascot': { tr: 'Ada maskotu', en: 'Island mascot' },
  'settings.commandBar': { tr: 'Komut çubuğu', en: 'Command bar' },
  'settings.screenshot': { tr: 'Ekran görüntüsü', en: 'Screenshot' },
  'settings.superKey': { tr: 'Süper tuş', en: 'Super key' },
  'settings.textSnippets': { tr: 'Metin parçacıkları', en: 'Text snippets' },
  'settings.radialMenu': { tr: 'Dairesel menü', en: 'Radial menu' },
}

/**
 * The cases of the first `switch` after `anchor` and the view each draws: the first type called in the case
 * (`case .monitor: MonitorSettings()`), else the first one inside the private function it calls
 * (`mixerOrPrioritySection(…)` → `MixerSection`).
 */
function switchViews(file: SourceFile, anchor: (lines: string[], index: number) => boolean, types: Set<string>): { cases: string[]; view: string; line: number }[] {
  const at = file.lines.findIndex((_, i) => anchor(file.lines, i))
  if (at < 0) return []
  const open = file.lines.findIndex((l, i) => i >= at && /\bswitch\b.*\{\s*$/.test(l))
  const end = blockEnd(file.lines, open)
  const out: { cases: string[]; view: string; line: number }[] = []
  const caseLines: number[] = []
  for (let i = open + 1; i < end; i++) if (/^\s+case \.[\w, .]+:/.test(file.lines[i]) && file.lines[i].search(/\S/) === file.lines[open].search(/\S/)) caseLines.push(i)
  for (let n = 0; n < caseLines.length; n++) {
    const from = caseLines[n]
    const to = n + 1 < caseLines.length ? caseLines[n + 1] : end
    const cases = [...file.lines[from].matchAll(/\.(\w+)/g)].map((m) => m[1]).slice(0, file.lines[from].split(':')[0].split(',').length)
    // `if … { A } else { B }`: B is the page (`.general`'s GeneralSettings), A the case's detour.
    const whole = file.lines.slice(from, to).map((l) => withoutStrings(l.replace(/^\s+case [^:]+:/, ''))).join('\n')
    const text = /\}\s*else\s*\{/.test(whole) ? whole.slice(whole.search(/\}\s*else\s*\{/)) : whole
    let view = [...text.matchAll(/(?<![.\w])([A-Z]\w+)\(/g)].map((m) => m[1]).find((name) => types.has(name))
    if (!view) {
      const helper = text.match(/(?<![.\w])([a-z]\w+)\(/)?.[1]
      const helperLine = helper ? file.lines.findIndex((l) => new RegExp(`func ${helper}\\(`).test(l)) : -1
      if (helperLine >= 0) {
        const body = file.lines.slice(helperLine, blockEnd(file.lines, helperLine) + 1).join('\n')
        view = [...body.matchAll(/(?<![.\w])([A-Z]\w+)\(/g)].map((m) => m[1]).find((name) => types.has(name))
      }
    }
    if (view) out.push({ cases, view, line: from + 1 })
  }
  return out
}

/** `case .x: return "symbol"` and `case .x: return s.key` of a property or function of an enum. */
function caseValues(file: SourceFile, owner: string, member: RegExp): Map<string, string> {
  const out = new Map<string, string>()
  const start = file.lines.findIndex((l) => new RegExp(`^enum ${owner}\\b`).test(l))
  if (start < 0) return out
  const end = blockEnd(file.lines, start)
  const at = file.lines.findIndex((l, i) => i > start && i < end && member.test(l))
  if (at < 0) return out
  const stop = blockEnd(file.lines, at)
  for (let i = at; i < stop; i++) {
    const match = file.lines[i].match(/^\s+case ([.\w, ]+):\s*return (.+?)\s*$/)
    if (match) for (const name of match[1].split(',').map((c) => c.trim().replace(/^\./, ''))) out.set(name, match[2])
  }
  return out
}

export function findSurfaces(
  files: SourceFile[],
  strings: (key: string) => Localized | null,
  componentNames: Set<string>,
  tokenNames: Set<string>,
): { surfaces: Surface[]; views: Set<string> } {
  const byPath = new Map(files.map((f) => [f.path, f]))
  const where = new Map<string, { file: SourceFile; line: number }>()
  for (const file of files) {
    for (const d of declarations(file)) if (!where.has(d.name)) where.set(d.name, { file, line: d.line })
  }
  const types = new Set(where.keys())
  const out: Surface[] = []
  const title = (id: string, expression: string | undefined): Localized => {
    const key = expression?.match(/^(?:s|strings|l10n\.s)\.(\w+)$/)?.[1]
    return (key && strings(key)) || fallbackTitles[id] || { tr: id.split('.').pop()!, en: id.split('.').pop()! }
  }
  const add = (group: Surface['group'], name: string, view: string, surfaceTitle: Localized, symbol: string | null) => {
    const place = where.get(view)
    if (!place) return
    // The view's own declaration and the private types it reaches in its file: several surfaces share a file
    // (MenuPanelView.swift draws three tabs, SettingsView.swift three pages).
    const start = place.line - 1
    const lines = withPrivateHelpers(place.file, [start, blockEnd(place.file.lines, start)])
      .flatMap(([from, to]) => codeLines({ path: place.file.path, lines: place.file.lines.slice(from, to + 1) }))
    const declared = new Set(declarations(place.file).map((d) => d.name))
    const components: Record<string, number> = {}
    const tokens: Record<string, number> = {}
    for (const { text } of lines) {
      const code = withoutStrings(text)
      for (const m of code.matchAll(/(?<![.\w])([A-Z]\w+)\b/g)) if (componentNames.has(m[1]) && !declared.has(m[1])) components[m[1]] = (components[m[1]] ?? 0) + 1
      for (const m of code.matchAll(/\.(\w+)\(/g)) if (componentNames.has(`.${m[1]}()`)) components[`.${m[1]}()`] = (components[`.${m[1]}()`] ?? 0) + 1
      for (const m of code.matchAll(/\b(PanelMetricColor|PanelSurface|PanelRowMetrics|NotchMotion|Theme)\.(\w+)/g)) {
        const id = `${m[1]}.${m[2]}`
        if (tokenNames.has(id)) tokens[id] = (tokens[id] ?? 0) + 1
      }
      if (/\bsectionTitle\(/.test(code)) tokens.sectionTitle = (tokens.sectionTitle ?? 0) + 1
    }
    out.push({
      id: `${group}.${name}`, group, case: name, title: surfaceTitle, symbol, view,
      source: { file: place.file.path, line: place.line }, doc: docAbove(place.file.lines, place.line - 1),
      components, tokens, literals: literalCounts(lines),
    })
  }

  const panelLayout = byPath.get('Sources/Vorssaint/UI/MenuPanel/PanelLayout.swift')
  const panelTitles = panelLayout ? caseValues(panelLayout, 'PanelSectionID', /func title\(/) : new Map()
  const panelSymbols = panelLayout ? caseValues(panelLayout, 'PanelSectionID', /var symbolName/) : new Map()
  const menuPanel = byPath.get('Sources/Vorssaint/UI/MenuPanel/MenuPanelView.swift')
  for (const entry of menuPanel ? switchViews(menuPanel, (lines, i) => /func section\(for id: PanelSectionID/.test(lines[i]), types) : []) {
    for (const name of entry.cases) add('panel', name, entry.view, title(`panel.${name}`, panelTitles.get(name)), panelSymbols.get(name)?.replace(/"/g, '') ?? null)
  }

  const directory = byPath.get('Sources/Vorssaint/UI/Settings/SettingsDirectory.swift')
  const settingsTitles = new Map<string, { title: string; icon: string | null }>()
  if (directory) {
    const text = directory.lines.join('\n')
    for (const m of text.matchAll(/SettingsDirectoryItem\(page: \.(\w+),\s*title:\s*([^,]+),\s*icon:\s*"([^"]+)"/g)) {
      if (!settingsTitles.has(m[1])) settingsTitles.set(m[1], { title: m[2].trim(), icon: m[3] })
    }
  }
  const settings = byPath.get('Sources/Vorssaint/UI/Settings/SettingsView.swift')
  for (const entry of settings ? switchViews(settings, (lines, i) => /private var detail: some View/.test(lines[i]), types) : []) {
    for (const name of entry.cases) {
      const item = settingsTitles.get(name)
      add('settings', name, entry.view, title(`settings.${name}`, item?.title), item?.icon ?? null)
    }
  }

  const notchSupport = byPath.get('Sources/Vorssaint/Services/Notch/NotchSupport.swift')
  const notchSymbols = notchSupport ? caseValues(notchSupport, 'NotchModule', /var symbol:/) : new Map()
  const notch = byPath.get('Sources/Vorssaint/UI/Notch/NotchView.swift')
  for (const entry of notch ? switchViews(notch, (lines, i) => /switch service\.selected \{/.test(lines[i]) && /NotchTimerView/.test(lines[i + 1] ?? ''), types) : []) {
    for (const name of entry.cases) {
      const symbol = notchSymbols.get(name)
      add('notch', name, entry.view, notchTitles[name] ?? { tr: name, en: name }, symbol?.startsWith('"') ? symbol.replace(/"/g, '') : null)
    }
  }

  for (const window of windows) add('window', window.view, window.view, window.title, null)
  return { surfaces: out, views: new Set(out.map((s) => s.view)) }
}

const notchTitles: Record<string, Localized> = {
  controls: { tr: 'Denetimler', en: 'Controls' }, mixer: { tr: 'Ses mikseri', en: 'Mixer' }, music: { tr: 'Müzik', en: 'Music' },
  clipboard: { tr: 'Pano', en: 'Clipboard' }, captures: { tr: 'Çekimler', en: 'Captures' }, files: { tr: 'Dosyalar', en: 'Files' },
  system: { tr: 'Sistem', en: 'System' }, tools: { tr: 'Araçlar', en: 'Tools' }, calendar: { tr: 'Takvim', en: 'Calendar' },
  notifications: { tr: 'Bildirimler', en: 'Notifications' }, timer: { tr: 'Zamanlayıcı', en: 'Timer' }, camera: { tr: 'Kamera', en: 'Camera' },
  downloads: { tr: 'İndirmeler', en: 'Downloads' }, scratchpad: { tr: 'Not defteri', en: 'Scratchpad' }, agents: { tr: 'Ajanlar', en: 'Agents' },
  watch: { tr: 'İzleme', en: 'Watch' },
}
