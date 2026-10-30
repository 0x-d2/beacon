# Beacon for Apple Watch

A watchOS 27 app, embedded in the iPhone app (`Beacon.app/Watch/BeaconWatch.app`), that shows every reading the
phone does, plus complications on the watch face. It has no pairing of its own: it shows the Macs the phone paired.

## Why it reads through the phone

watchOS allows low-level networking (Network framework, `URLSessionWebSocketTask`, Bonjour) only to audio-streaming and
VoIP apps (Apple TN3135); an `NWConnection` elsewhere sits in `.waiting(ENETDOWN)`. The Mac's TLS-PSK needs the Network
framework, and `URLSession` can't do PSK. **The simulator always allows low-level networking**, so a direct design
works there and fails on a real watch. Never add `Network`/`NWConnection` code to the watch targets.

## Files

| Area | Code | Notes |
|---|---|---|
| Messages | `iOS/Beacon/Connection/WatchLink.swift` | `WatchMac {id, name}`, `WatchContext` (Macs + unit, the application context), `WatchStatus`, `WatchMessage` (`.watch(macID, active)` watch → phone; `.status/.info/.history/.snapshot` phone → watch), JSON with `.secondsSince1970` |
| Phone side | `iOS/Beacon/Connection/WatchRelay.swift` | `WCSessionDelegate`, owned by `AppModel` (not in `-demo` mode). `receive(_:)` → `MacSession.watchedFromWatch`, `beginBackgroundTask` renewed on every heartbeat, forwarding via `Observations`, expiry after 15 s |
| Entry | `iOS/BeaconWatch/App/BeaconWatchApp.swift` | `onOpenURL` (the complication's link), `-screen`, scene phase: `.background` pauses, `.active` resumes, `.inactive` (wrist down) keeps reading |
| State | `iOS/BeaconWatch/Stores/WatchModel.swift` | `WatchModel` (`WCSessionDelegate`: Macs from the context, heartbeat, sending, the complication's reading), `WatchMacState` per Mac (status, info, snapshot, `LiveHistory`, `phoneUnreachable`, watcher count + `paused`), `WatchRoute` |
| Screens | `iOS/BeaconWatch/Features/` | `MacListView` (root; with one Mac it opens on it once), `WatchDashboardView` (header + 8 `WatchMetricRow`s), `WatchMetricView` (hero number, `SparkChart`, the shared `MetricRows`) |
| Colours | `iOS/BeaconWatch/DesignSystem/BeaconColor+watchOS.swift` | Same API as the phone's `BeaconColor`, the dark-mode values (watchOS is always dark) |
| Complication data | `iOS/BeaconWatch/Shared/LastReading.swift` | `LastReading` + `LastReadingStore` in `UserDefaults(suiteName: "group.co.ikili.beacon")`; the `beacon-watch://mac?id=…` link |
| Complications | `iOS/BeaconWatchWidgets/BeaconWidgets.swift` | One `AppIntentConfiguration` widget (`ReadingIntent.metric`: CPU, memory, GPU, temperature; `recommendations()` lists the four), families circular / corner / inline / rectangular |
| Targets | `iOS/project.yml` › `BeaconWatch`, `BeaconWatchWidgets` | Each lists the phone files it compiles; both carry the app-group entitlement |

## The conversation

1. The phone publishes `WatchContext` (`updateApplicationContext`) on activation, on pairing/removal and on a unit
   change. The watch reads it at activation (`receivedApplicationContext` survives launches).
2. A watch screen appears → `WatchMacState.watch()` → `.watch(macID, active: true)` via `sendMessageData`, repeated
   every 5 s while any screen shows a Mac. The message wakes Beacon on the phone in the background, even cold.
3. The phone sends what it has — `.status`, `.info`, then `.history` whenever its history changed other than by the
   next reading (first time, reconnect) — and `.snapshot` for every reading. Order matters: the watch receives on the
   main queue in order (`DispatchQueue.main.async` + `MainActor.assumeIsolated`), never via unordered `Task`s.
4. The screen leaves (or the app goes to the background) → `.watch(active: false)`; the phone clears
   `watchedFromWatch` and, if Beacon is in the background, closes the Mac's connection. No word for 15 s → same.
5. Each snapshot is written to `LastReadingStore`; the complication's timeline reloads at most once a minute while
   readings flow and once when they stop. A reading older than 10 min draws dimmed.

## States the watch shows

`StatusPill` from `pillKind`: demo, live, connecting, offline. `note` explains: the phone out of reach (only after a
whole missed heartbeat — right after launch WatchConnectivity reports "unreachable" for a moment), the Mac's reason,
"removed on the Mac", or `.forgotten` (the phone no longer has that Mac). The demo Mac drifts locally and never asks the
phone; with `-demo 1` its readings also feed the complication (for screenshots).

## Rules

- A file the watch or the widgets need from `iOS/Beacon/` is added to that target's `sources` in `project.yml`, then
  `xcodegen generate`. It must compile without UIKit/Network (`ref/architecture.md` › Code shared).
- Closures handed to WatchConnectivity (error handlers) are marked `@Sendable`: they run on its queue, and a closure
  formed on the main actor would trap there under Swift 6 (`ref/swift-conventions.md`).
- The app group needs the signing team's App Groups capability. If a free personal team refuses it, removing both
  `entitlements` blocks keeps the app working with an empty complication (`iOS/README.md` › Apple Watch).
- Verify on a paired iPhone + Watch simulator pair with a stand-in Mac (`ref/build-and-test.md` › End to end), and
  say plainly what a real device would still need to confirm (background wake timing, the app group's signing). The
  watch face can't be edited from the command line: a complication's look is checked by hand.
