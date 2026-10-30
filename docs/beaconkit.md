# BeaconKit™ catalog

BeaconKit™ is the app's design system as a website, generated from the source: the tokens, the components that use
them, the surfaces built from those components, and the inline values that carry most of the look. Every item links
to the line that declares it, so the site answers "what sets this, and where". It is published to the owner's tailnet
from the Mac mini at home (Hosting, below); `docs/beaconkit-mac-mini.md` is the mini's setup, in Turkish.

## What the app's design system is

The app keeps few tokens, all in plain Swift:

| | |
|---|---|
| `PanelMetricColor` (`UI/Theme.swift`) | Seven chart and status colours, each `static func x(for scheme: ColorScheme) -> Color`: the system colour in dark mode, a darkened RGB in light mode |
| `PanelSurface` (`UI/Theme.swift`) | The panel's translucent layers (base, card, control, border, raised…); `border` and `raisedBorder` answer Increase Contrast |
| `Theme.spaceGradient`, `PanelSurface.rimHighlight` | The gradients |
| `sectionTitle(_:)`, `.panelCard()`, `.panelGlassSurface()` | The section title, the panel card, the panel's glass |
| `PanelRowMetrics` (`UI/MenuPanel/MenuPanelView.swift`) | The panel rows' icon width, spacing and insets, with the Dynamic Island's own |
| `NotchMotion`, `NotchMascotMotion` | The island's springs (duration, bounce) and timings |

Everything else is written inline in the views: corner radii, font sizes, paddings, spacings, shadows, animation
curves, colours and materials. The accent is the system's (`Color.accentColor`). There are no asset catalogs and no
`#Preview`s.

## Collector (`web/collector/`)

`npm run collect` reads `Sources/Vorssaint/**/*.swift` line by line (the files follow one style, so a declaration's
first line and the `///` block above it are enough) and writes `web/public/data/catalog.json`, checked against one
zod schema (`collector/schema.ts`) the site shares; a mismatch fails the collect.

- **Tokens** (`tokens.ts`): the enums above. A colour function's value is worked out per appearance by picking the
  `scheme == .light ? a : b` branch (at any depth, `raised ? …` for Increase Contrast) and parsing the colour
  expression (`colors.ts`). System colours (`.green`, `.secondary`) come from `system-colors.json`, written on a Mac by
  `swift docs/scripts/kit-system-colors.swift > web/collector/system-colors.json` (rerun after a macOS update).
  Palettes are any enum that switches over its cases for a colour (`NotchMascotPalette.light`).
- **Inline values** (`literals.ts`): every `cornerRadius:`, `.font(.system(size:…))` and text style, `.padding(`,
  `spacing:`, `.frame(width:…)`, `.shadow(`, animation curve, colour literal and material in `UI/`, `App/` and
  `Services/Notch/`, grouped by value with every place (file, line, code). A group equal to a token (a 10 pt corner as
  the panel card's, a colour within ΔE2000 2 of a token's) names it.
- **Components** (`components.ts`): there is no component library, so the collector finds them: a top-level,
  non-private `View`, `ViewModifier`, style, shape or representable in `UI/` that code in two other files names, or that
  a shared file (`Theme.swift`, `SharedUI.swift`, `SettingsCard.swift`, `PanelLayout.swift`, `Sparkline.swift`,
  `NotchComponents.swift`) declares and anything uses; and `extension View` modifiers (`.panelCard()`). A modifier's
  private type (`PanelCardModifier`) counts as its body. Surfaces are left out.
- **Surfaces** (`surfaces.ts`): read from the app's own switches: the menu panel's tabs (`MenuPanelView.section(for:)`),
  the Settings pages (`SettingsView.detail`, titles from `SettingsDirectory.swift`), the island's modules (`NotchView`'s
  `switch service.selected`), and a list of windows and floating tools. Titles are the app's own Turkish and English
  copy (`strings.ts`) where the source names a `Strings` key.
- **Guide** (`guide.ts`): "Neyi nereden değiştiririm", the owner's map from a look to the line that sets it. Each entry
  names a file and a pattern, never a line number; the collector looks the line up every run and warns when a pattern
  no longer matches. Add an entry there when a question comes up twice.
- **Git and notes** (`git.ts`): the commit, each file's last change, the latest commits under `UI/`, the open
  `kit-revize` issues (with `gh` signed in).

## Site (`web/`, Vite + React + TypeScript)

```sh
cd web && npm install      # once
npm run collect            # the sources → web/public/data/catalog.json
npm run dev                # http://localhost:5180
npm run build              # tsc + vite → web/dist (what the Mac mini serves)
```

Pages: Genel bakış, Neyi nereden değiştiririm, Renkler, Tipografi (samples in SF Pro where the browser has it),
Ölçüler, Malzemeler, Hareket (curves and a dot on the app's own spring formula), Bileşenler (by category, grid or
list), a page per component and per surface, Satır içi değerler (by kind, with a histogram), Değişiklikler. ⌘K searches
everything. The top bar's Tema (Koyu · Koyu | Açık · Açık) is the renders' theme and the site's appearance; Dil
(TR · EN) is the renders' language and the site's own copy, every string written in both (`t('Renkler', 'Colours')`).
The layout follows AtaKit™'s (0x-d2/Ata-Online `web/`).

`web/public/{data,renders}`, `node_modules` and `dist` are never committed.

## Notes

"Not bırak" opens GitHub's new issue on `.github/ISSUE_TEMPLATE/kit-revize.yml` (Turkish), filled with the item, the
theme and language, the commit and a link back; the viewer's own account sends it, the site holds no token. The next
collect shows it on the item. Work through them with `gh issue list --label kit-revize`; a fix closes its issue. The
`kit-revize` label must exist in the repo (`gh label create kit-revize`).

## Hosting (`.github/workflows/kit.yml`)

- **Manual only:** Actions › BeaconKit™ › Run workflow, or `gh workflow run kit.yml -f scope=site`. Pushes and pull
  requests never trigger it. The job runs only when the repo's owner starts it (`github.triggering_actor`), since the
  repo is public and the runner is the owner's Mac.
- **The runner:** the Mac mini `brain`, a runner of this repo's own (`~/actions-runner/beacon`, label `beacon-kit`,
  beside Ata-Online's `ata-kit`), a LaunchAgent in the mini's GUI session.
- **Publish:** `web/dist` → `~/BeaconKit/site/releases/<run>`, the `current` link moved to it in one rename (the newest
  two stay). Caddy serves `current` on 127.0.0.1:8789; `tailscale serve --bg --https=8445 http://127.0.0.1:8789` brings
  it to the tailnet only: `https://brain.<tailnet>.ts.net:8445`. The repo never writes the mini's user or the tailnet's
  name.
