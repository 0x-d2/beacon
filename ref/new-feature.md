# Adding a feature — checklists

Read `ref/architecture.md` first. Each list is the order that keeps every target building.

## A new reading (a value the Mac measures, shown on the phone and the watch)

1. **Mac:** the value is in `SystemSnapshot` (`Services/SystemMonitor/`, samplers in `Services/Metrics/`) and, if it
   costs something to sample, in `SystemMonitorPanelNeeds.remoteReadings` (`RemoteMonitorService.swift`).
2. **Protocol:** an optional field on `RemoteSnapshot` (or `RemoteHistory`) in `RemoteMonitorProtocol.swift` — optional,
   so an older peer still decodes. A change of an existing field's shape bumps `RemoteMonitorProtocol.version`.
   `RemoteMonitorBridge` fills it. `Tests/RemoteMonitorProtocolTests.swift` covers the round trip.
3. **Shared readings** (`iOS/Beacon/Stores/Readings.swift`): a new `MetricKind` case (title, symbol, tint) if it gets
   its own tile; `LiveHistory` if it gets a chart; `headline(_:unit:)` for its number. A new colour goes into both
   `BeaconColor` files with its Mac token in the doc line.
4. **Format** (`Format.swift`) if it's a new kind of unit.
5. **iPhone:** `DashboardTile` (`Features/Dashboard/DashboardView.swift`), `MetricDetailView.series` if charted,
   `MetricRows` for the detail rows (the watch gets these too), `AppModel.open(screen:)` keeps working by the kind's id.
6. **Watch:** `WatchMetricRow` caption/accessory, `WatchMetricView.series`; the complication only if it's one of its
   readings (`ComplicationMetric`, `LastReading`).
7. **Demo:** `DemoData.snapshot(tick:)`/`history` (and the Mac's `KitFixtures` if the catalog shows it).
8. **Strings** in English and Turkish (and the Mac's 15 languages if the Mac's UI names it) — `ref/localization.md`.
9. **Catalog:** a new screen id → `docs/scripts/kit.sh` `screens=(…)` + `web/collector/ios.ts` `screenTitles`.
10. **Privacy:** what's sent grew → `docs/PRIVACY.md` › 14 and `docs/remote-monitor.md`.
11. **Check:** `./build.sh --test-suite=remote-monitor`, iOS tests, watch build, screenshots TR + EN.

## A new message between Mac and phone

Add a case to `RemoteMessage` and its `type` string in both `init(from:)` and `encode(to:)`. Older peers decode it as
`.unknown` and ignore it, so no version bump unless an existing message changes. Handle it in
`RemoteMonitorService.handle(_:from:)` and/or `MacSession.handle(_:)`; if the watch needs it, forward it through
`WatchRelay` with a `WatchMessage` case. Document it in `docs/remote-monitor.md` › Messages.

## A new screen (iPhone)

1. `iOS/Beacon/Features/<Area>/<Name>View.swift`, SPDX header, `///` doc, a `#Preview` on demo data.
2. Reads from a `MacSession` → `watch()`/`unwatch()` in `onAppear`/`onDisappear`.
3. Navigation through `AppModel.path` (`Route`); a launch shortcut in `open(screen:)` if the catalog photographs it.
4. Tokens and components only (`ref/design-system.md`); strings in both languages.
5. `cd iOS && xcodegen generate`, build, test, screenshot TR + EN, dark + light.

## A new screen or view on the watch

Same as above under `iOS/BeaconWatch/Features/`; watch through `WatchMacState.watch()`; check on the 46 mm simulator
with `-demo 1 -screen …`; it must read in always-on (`isLuminanceReduced`). A phone file it needs goes into the
`BeaconWatch` target's `sources` in `project.yml`, then `xcodegen generate`.

## A new design-system component

`iOS/Beacon/DesignSystem/Components/<Name>.swift` with its `KitSpecimen` and `#Preview`, its id in
`KitCatalog.specimens`; tokens only. It compiles for the watch too (SwiftUI only, no UIKit) — check the watch build.
`ref/features/BeaconKit.md` › Rules.

## A new Mac-side setting for Beacon

`DefaultsKey` in `Core/Defaults.swift` (machine state → `SettingsBackupSupport.machineStateKeys`), the control in
`UI/Settings/RemoteMonitorCard.swift`, its copy in `Core/RemoteMonitorStrings.swift` for all 15 languages,
`syncWithPreferences()` reacting to it. `./build.sh --test-suite=settings` and `--test-suite=localization`.

## Before reporting done

Builds clean, the tests of what you touched pass, visual changes were looked at in both languages, docs that describe
the behaviour (`iOS/README.md`, `docs/remote-monitor.md`, the matching `ref/` file) still tell the truth, the change
has its line in `CHANGELOG.beacon.md` and `CHANGELOG.beacon.en.md` (`ref/release-notes.md`), and the final message
separates what was run from what was only read or reasoned about.
