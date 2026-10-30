# Beacon for iPhone

A SwiftUI app (iOS 27, iPhone only, portrait + landscape) that pairs with Macs running Watch from iPhone and shows
their readings live: CPU, memory, GPU, temperatures, network, power, disks, fans. English and Turkish. The owner's doc
(Turkish) is `iOS/README.md`.

## Files

| Area | Code | Notes |
|---|---|---|
| Entry | `iOS/Beacon/App/BeaconApp.swift` | `@State AppModel`; `onOpenURL` → `propose(link:)`; `.task` runs `-kitExport`, `-screen`, `-pair`; `scenePhase == .background` → `pauseAll()` |
| State | `iOS/Beacon/Stores/AppModel.swift` | Paired Macs, a `MacSession` per Mac (made lazily by `session(for:)`), the demo Mac, the navigation path (`Route`), the temperature unit, pairing, the `WatchRelay` |
| Readings model | `iOS/Beacon/Stores/Readings.swift` | `MetricKind` (the 8 readings: title, symbol, tint), `LiveHistory` (120 points), `RemoteSnapshot.memoryFraction` / `headline(_:unit:)` — shared with the watch |
| Connection | `iOS/Beacon/Connection/MacSession.swift` | One Mac: TLS 1.2 PSK + WebSocket over `NWConnection`, the local name first then the address away from home, back-off 1→30 s, ping every 5 s, 15 s silence = gone, 20 s idle close |
| Pairing store | `iOS/Beacon/Connection/PairedMac.swift` | `PairedMac` + `PairingStore`: one keychain item per Mac (service `co.ikili.beacon.macs`, `AfterFirstUnlockThisDeviceOnly`, no iCloud) |
| Watch relay | `iOS/Beacon/Connection/WatchRelay.swift`, `WatchLink.swift` | `ref/features/BeaconWatch.md` |
| Screens | `iOS/Beacon/Features/` | `Macs/MacsView` (root: cards or the empty state), `Dashboard/DashboardView` (2-column tiles), `Detail/MetricDetailView` (+ shared `MetricRows`), `Pairing/PairingView` (VisionKit QR scanner or a pasted link), `Settings/SettingsView` + `MacSettingsView` |
| Formatting | `iOS/Beacon/Formatting/Format.swift` | Every number on screen goes through `Format` (percent, bytes, rate, temperature, watts, rpm, duration) in the phone's region |
| Demo | `iOS/Beacon/Fixtures/DemoData.swift` | The demo Mac's readings (the Mac catalog's fixture); never touches the network |
| Design system | `iOS/Beacon/DesignSystem/` | `ref/design-system.md` |
| Strings | `iOS/Beacon/Resources/Localizable.xcstrings` | `ref/localization.md` |
| Tests | `iOS/BeaconTests/BeaconTests.swift` | Swift Testing, `@MainActor` suites |

## How it behaves

- **Watching, not polling.** A screen that shows a Mac's readings calls `session.watch()` in `onAppear` and
  `unwatch()` in `onDisappear`; the session counts them, so going dashboard → detail never drops the subscription in
  between. `watching` true → connect + `subscribe {active: true}`; false → `subscribe {active: false}` and close after
  20 s. The Mac samples for the phone only while it is subscribed. `MacCard` on the list watches too (CPU/memory/GPU).
- **The watch is a watcher of its own:** `MacSession.watchedFromWatch`; `stopWatching()` (app to background) clears
  the screens' count but not the watch's, and `pauseAll()` leaves that session connected.
- **Pairing:** scanned or pasted in the app → `pair(link:)` saves at once. A `beacon://` link from outside
  (`onOpenURL`: the Camera app, a web page) → `propose(link:)` → `MacsView` asks "Pair with this Mac?" with its
  name and addresses; nothing is saved before the owner taps. The same pairing id updates its entry; another Mac with
  the same name and host stays.
- **Status:** `MacSession.Status` `.idle / .connecting / .live / .offline(reason) / .refused(reason)` → `StatusPill`
  (`statusKind`). `refused("removed")` is "This phone was removed on the Mac".
- **Background:** nothing reads while the app is in the background, except the Mac the Apple Watch shows.

## Launch arguments (simulator, catalog renders)

- `-demo 1`: don't load the paired Macs, no watch relay.
- `-screen dashboard|cpu|memory|gpu|network|power|disk|temperature|fans`: opens it on the demo Mac.
- `-pair '<beacon://…>'`: pairs at launch.
- `-kitExport 1`: draws the BeaconKit renders, then quits.

## Rules

- A new reading on screen: `ref/new-feature.md` › A new reading. A new screen: `ref/new-feature.md` › A new screen.
- State lives in `@MainActor @Observable` classes; `NWConnection` runs on the main queue and its callbacks use
  `MainActor.assumeIsolated` (`ref/swift-conventions.md`).
- Keep `BeaconColor.swift`'s line form (`dynamic(light: (r, g, b), dark: UIColor.systemX)`): the kit collector parses
  it (`ref/design-system.md`).
- Known gap (pre-existing, unverified): after the app returns from the background, a screen already on screen doesn't
  re-subscribe (`pauseAll()` zeroes the watchers and SwiftUI doesn't rerun `onAppear`). The watch app avoids this with
  a `paused` flag instead of zeroing.
