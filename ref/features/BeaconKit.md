# BeaconKit™ — the design-system catalog

The app's design system as a website, generated from the sources: tokens, components, surfaces and inline values of
the Mac app, plus the iPhone app's components, screens and colours, each linked to the line that declares it. Published
to the owner's tailnet from the Mac mini. **Full doc: `docs/beaconkit.md`** (and `docs/beaconkit-mac-mini.md`, Turkish,
for the mini's setup). Read it before touching any of the parts below.

## Parts

| Part | Where | Role |
|---|---|---|
| Collector | `web/collector/*.ts` (`npm run collect`) | Reads Swift line by line → `web/public/data/catalog.json`, validated by `collector/schema.ts` (zod; a mismatch fails the collect). `tokens.ts`, `literals.ts`, `components.ts`, `surfaces.ts`, `guide.ts`, `git.ts`, `renders.ts`, `ios.ts` |
| Site | `web/src/` (Vite + React + TS, port 5180) | Pages per token kind, components, surfaces, inline values, changes; ⌘K search; TR/EN copy via `t('…', '…')`; theme + language switch for the renders |
| Mac renders | `Sources/Vorssaint/Kit/` (all `#if VORSSAINT_DEVELOPMENT`) | `KitSpecimen`/`KitVariant`, `Kit/Specimens/*.swift`, `KitCatalog`, `KitFixtures` (`SystemMonitor.freezeForKit`), `KitRenderer` (`--kit-render <dir>`, ScreenCaptureKit) |
| iPhone renders | `iOS/Beacon/DesignSystem/Catalog/` | `KitSpecimen` per component file, `KitCatalog.specimens`, `KitExport` (`-kitExport 1`: ImageRenderer @3x, both themes, colour tokens resolved) |
| Script | `docs/scripts/kit.sh` | Builds and renders everything (TR + EN, dark + light); `--specimen X`, `--only components|surfaces|ios`, `--no-build`. iOS step: its own "BeaconKit" simulator (iPhone 18 Pro), status bar 9:41, `-screen …` screenshots |
| Workflow | private repo `0x-d2/beacon-kit-runner`, `.github/workflows/kit.yml` | Manual only (`gh workflow run kit.yml -R 0x-d2/beacon-kit-runner -f ref=custom`), owner-triggered; checks out a branch or tag of this repo and runs on the Mac mini's self-hosted runner `beacon-kit`; publishes `web/dist`. **Never register a runner on this public repo** — a fork's PR runs the workflows it brings |
| Notes | `.github/ISSUE_TEMPLATE/kit-revize.yml` | "Not bırak" opens an issue labelled `kit-revize`; the next collect shows it on the item |

```sh
docs/scripts/kit.sh                                   # everything (≈ 1 min Mac + ≈ 3 min iOS)
cd web && npm run collect -- --kit ~/BeaconKit/kit && npm run dev
npm run check                                         # tsc, no emit
```

## Rules

- **Kit code stays apart from upstream code**: Mac specimens live in `Kit/`, behind `VORSSAINT_DEVELOPMENT`, so a
  release never carries them. `./build.sh --typecheck-dev` checks that code (CI runs it). No macros on the Mac.
- **Collector parses by line patterns**, so source style is part of the contract:
  - iOS components: `KitSpecimen("Name", .category, [` and `KitVariant("id", "title"` on one line each; the `///`
    block above `struct Name` is the component's doc.
  - iOS colours: `static let name = dynamic(light: (r, g, b), dark: UIColor.systemX)` or a plain `Color…` in
    `iOS/Beacon/DesignSystem/BeaconColor.swift`; the doc line names the Mac token (`/// CPU: PanelMetricColor.green.`).
  - Mac: see `docs/beaconkit.md` › Collector. `guide.ts` entries name a file and a pattern, never a line number.
  If you change one of these forms, change the collector in the same change and run `npm run collect`.
- **A new iOS component**: a `@MainActor static let` specimen in its own file, its id in `KitCatalog.specimens`, a
  `#Preview` drawing `.preview()`.
- **A new iOS screen in the catalog**: add it to `screens=(…)` in `docs/scripts/kit.sh`, its titles to `screenTitles` in
  `web/collector/ios.ts`, and a `-screen <id>` case in `AppModel.open(screen:)`.
- The watch app isn't in the catalog yet (its components are the phone's; its colours are the dark values).
- Never committed: `web/public/data`, `web/public/renders`, `web/node_modules`, `web/dist`, `docs/logs/`.
