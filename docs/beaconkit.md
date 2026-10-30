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

## Renders (`Sources/Vorssaint/Kit/`, `docs/scripts/kit.sh`)

The site shows the app's own pixels: every specimen variant and some whole surfaces, photographed in Turkish and
English, dark and light. All of `Kit/` is `#if VORSSAINT_DEVELOPMENT`, so a release never carries it, and it lives apart
from the components so the upstream files stay untouched.

| | |
|---|---|
| `KitSpecimen`, `KitVariant` (`Kit/KitSpecimen.swift`) | A component by its catalog id (`SettingsCard`, `.panelCard()`), its category, its variants: `id`, `title` (the API that makes it), `width` (308 is the panel's content width), `backdrop` (`.panel`: the panel's glass over a desktop; `.window`; `.notch`: black and dark; `.desktop`), `capture` (`.screen`, or `.imageRenderer` for plain shapes only) |
| `Kit/Specimens/*.swift` | The specimens, a file per category. Copy the app itself shows comes from `L10n`; sample copy the tables don't have is `kitText("…", "…")` |
| `KitCatalog` (`Kit/KitCatalog.swift`) | The specimens in the site's order, and the surfaces (`KitSurface`, by `surfaces.ts`'s id: `panel.system`). A surface goes there only if it draws from the frozen readings and starts no service: a page that registers hotkeys, applies the appearance or asks for a permission would change what it photographs, or the Mac |
| `KitFixtures` | The readings the renders draw (`SystemMonitor.freezeForKit(_:)`, development builds only): the same numbers on every Mac and run |
| `KitRenderer` | `--kit-render <dir>` (`main.swift`, development builds): each variant in a borderless window of its own above an opaque backdrop window, per language (`L10n`) and theme (`NSApp.appearance`), photographed with ScreenCaptureKit |

```sh
docs/scripts/kit.sh                          # build, then everything: TR + EN, dark + light (≈ 1 min)
docs/scripts/kit.sh --specimen SettingsCard  # some specimens; the others' images stay
docs/scripts/kit.sh --only surfaces --no-build
cd web && npm run collect -- --kit ~/BeaconKit/kit && npm run dev
```

- **Adding a specimen:** a `static var` in the category's file under `Kit/Specimens/`, then its name in
  `KitCatalog.specimens`. Its id is the component's as the site lists it; the collector warns when it names none.
  `./build.sh --typecheck-dev` (CI runs it) checks the development code, which a release build never compiles. No
  macros (`#Preview`, `@Observable`): the app builds against the macOS 26 SDK with the Command Line Tools.
- **The renderer** is the developer build copied to `~/BeaconKit/BeaconKit Renderer.app` under its own bundle id
  (`co.ikili.beaconkit.renderer`), so the language it switches through stays out of the developer app's settings, and
  launched with `open`, so Screen Recording is asked of it. **With** that permission it photographs the screen itself:
  a material blurs the backdrop as it would the desktop. **Without** it, it photographs its own two windows
  (`SCShareableContent.currentProcess`, no prompt) and materials come out flat; the manifest and the site
  ("malzeme düz") say which. Either way controls draw in their active state (the render panel can be key and never
  hides).
- **A render on a 1x screen is refused** (the site shows @2x pixels): the mini needs a HiDPI mode
  (`docs/beaconkit-mac-mini.md`). `KIT_ALLOW_1X=1` renders anyway, to try something.
- **Output:** `export/registry.json`; `render/components/<lang>/<theme>/<slug>/<variant>.png` and
  `render/surfaces/<lang>/<theme>/<surface>.png`, each with a `manifest.json` (sizes in points, the capture mode);
  `render/rendered.json` (each group's commit and time, for the site's "Bileşen görüntüleri: <date> · <commit>").
  Log: `docs/logs/kit-render.log`. The collector turns the PNGs into lossless WebP under `web/public/renders`.

## iOS (`iOS/`, the Beacon app)

The catalog has a second platform: Beacon, the iPhone app (`iOS/README.md`). Its design system is tokens from the
start (`iOS/Beacon/DesignSystem/`: `BeaconColor`, `BeaconType`, `BeaconMetrics`, `BeaconMotion`), and each component
declares its `KitSpecimen` in its own file, which its `#Preview`s, the in-app Settings › Design catalog and the site
all draw. `BeaconColor`'s doc names the Mac token each colour keeps the meaning of (`/// CPU: PanelMetricColor.green.`),
and the site's iPhone › Colours shows the two side by side.

- **Renders** (`kit.sh`'s iOS step, `--only ios`; part of every full run): builds Beacon for the simulator with
  XcodeGen and xcodebuild, on a simulator of its own ("BeaconKit", iPhone 18 Pro, the newest iOS runtime), status bar
  at 9:41. Per language the app runs `-demo 1 -kitExport 1`: it draws every specimen variant in both themes with
  ImageRenderer at @3x and resolves the colour tokens into its Documents/kit, which the script copies out; then each
  screen opens on the demo Mac (`-screen dashboard`, `cpu`, …; `macs` is the empty list) and `simctl io screenshot`
  takes it, dark and light. Output: `export/ios-{registry,tokens}.json`, `render/ios/{components,screens}/…` with
  manifests (sizes in points), `rendered.json`'s `ios` stamp. Log: `docs/logs/kit-ios.log`. ≈ 3 min for TR and EN.
- **Collector** (`collector/ios.ts`): the components from the `KitSpecimen("…", .category, [` declarations and the
  `///` above each `struct`, the colours from `BeaconColor.swift` (the app's own resolution from the renders where
  there is one), the screens; the renders as WebP. Pages: iPhone · Beacon › Bileşenler, Ekranlar, Renkler.
- **Adding a component** to the iOS catalog: a `@MainActor static let` specimen in its file, its id in
  `KitCatalog.specimens` (`iOS/Beacon/DesignSystem/Catalog/KitSpecimen.swift`), a `#Preview` drawing `.preview()`.

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

## Hosting (the private `0x-d2/beacon-kit-runner`)

- **Not in this repo, on purpose.** This repo is public: anyone can fork it and open a pull request, and a pull request
  runs the workflows it brings. A self-hosted runner registered here would be within reach of a file saying
  `runs-on: beacon-kit`. So the runner and its workflow (`.github/workflows/kit.yml` there) live in a private repo whose
  only job is this; no workflow of a public repo can ask for another repo's runner. Never register a runner here.
- **Manual only:** Actions › BeaconKit™ › Run workflow in that repo, or
  `gh workflow run kit.yml -R 0x-d2/beacon-kit-runner -f ref=custom -f scope=all`. `ref`: a branch or tag of this repo
  (only its owner can push those; a pull request's head or a bare commit, which could come from anyone's fork, is
  refused). `scope`: `all` (the Mac's components and surfaces and the iPhone app, then the site), `components`,
  `surfaces`, `ios`, or `site` (the site alone, on the images kept in `~/BeaconKit/kit` from an earlier run);
  `languages`: `tr en`, `tr`, `en`. The job runs only when the repo's owner starts it (`github.triggering_actor`).
- **The checkout is this repo's:** the collector reads the repo and branch its links name from the checkout
  (`git.ts`'s `repository()` falls back to the `origin` remote when `GITHUB_REPOSITORY` is unset, which the workflow
  ensures with `env -u`), so the site links here, not to the private repo.
- **The runner:** the Mac mini `brain`, registered on the private repo (`~/actions-runner/beacon`, label `beacon-kit`,
  beside Ata-Online's `ata-kit`), a LaunchAgent in the mini's GUI session.
- **Publish:** `web/dist` → `~/BeaconKit/site/releases/<run>`, the `current` link moved to it in one rename (the newest
  two stay). Caddy serves `current` on 127.0.0.1:8789; `tailscale serve --bg --https=8445 http://127.0.0.1:8789` brings
  it to the tailnet only: `https://brain.<tailnet>.ts.net:8445`. The repo never writes the mini's user or the tailnet's
  name.
