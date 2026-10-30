# Architecture — how Beacon works end to end

Read this before touching anything that crosses an app boundary (the protocol, the relay, shared files).

## The repository

This repo is a fork of **Vorssaint** (`vorssaint/vorssaint-utils`), a native macOS menu-bar utility with ~80 features
(`ref/vorssaint-mac.md`). Almost all of its 2,000+ commits are upstream's. The owner's work, **Beacon**, sits on top:

| Part | Where | What it is |
|---|---|---|
| Watch from iPhone (Mac side) | `Sources/Vorssaint/Services/RemoteMonitor/`, `UI/Settings/RemoteMonitorCard.swift` | The Mac serves its readings to paired phones (`ref/features/RemoteMonitor.md`) |
| Beacon for iPhone | `iOS/Beacon/` | SwiftUI app, iOS 27: pairs with Macs, shows their readings live (`ref/features/BeaconApp.md`) |
| Beacon for Apple Watch | `iOS/BeaconWatch/`, `iOS/BeaconWatchWidgets/` | watchOS 27 app + complications, reads the Macs through the phone (`ref/features/BeaconWatch.md`) |
| BeaconKit™ | `web/`, `Sources/Vorssaint/Kit/`, `iOS/Beacon/DesignSystem/Catalog/`, `docs/scripts/kit.sh` | The design system as a website, generated from the sources (`ref/features/BeaconKit.md`) |

Upstream files are touched as little as possible: Beacon code lives in its own files, and an upstream file gets only
the hook line it needs (e.g. one `syncWithPreferences()` call in `App/FeatureRuntime.swift`).

## Data path

```
 Mac (Vorssaint)                         iPhone (Beacon)                        Apple Watch (Beacon)
 SystemMonitor ──► RemoteMonitorService ══TLS 1.2 PSK + WebSocket══► MacSession ──► WatchRelay ══WatchConnectivity══► WatchModel
  samples only      listener :47823        one key per phone,          live state     passes the       sendMessageData,     screens +
  while a phone     Bonjour _beacon-mac    JSON frames                 for screens    Mac's messages   5 s heartbeat        complication
  subscribes                                                                          on
```

- **Mac → iPhone:** `RemoteMonitorProtocol.swift` (one JSON text frame per message: `hello`, `info`, `subscribe`,
  `history`, `snapshot`, `ping`/`pong`, `refused`). The phone subscribes only while a screen shows readings; the Mac
  samples for phones only while one is subscribed. Spec: `docs/remote-monitor.md`.
- **iPhone → Watch:** `iOS/Beacon/Connection/WatchLink.swift`. watchOS blocks the Network framework (the only way to
  a pre-shared key) outside audio/VoIP apps — Apple TN3135 — and **the simulator doesn't enforce it**, so a direct
  watch → Mac design would pass every simulator test and fail on a real watch. The watch says which Mac it shows every
  5 s; that wakes Beacon on the phone in the background, which keeps that Mac's `MacSession` watching
  (`watchedFromWatch`) and forwards what the Mac sends. 15 s of silence and the phone lets go.
- **Watch → complication:** the watch app writes the last reading to the app group `group.co.ikili.beacon`
  (`BeaconWatch/Shared/LastReading.swift`); the WidgetKit extension draws it.

## Security model (never weaken)

- One random 32-byte key per phone, made by the Mac, carried once in the pairing QR code
  (`beacon://pair?v=1&name=…&host=…&alt=…&port=…&id=…&key=…`). The listener holds only paired keys, so an unpaired
  device can't finish the TLS handshake. PSK suites exist only in TLS 1.2, so both ends pin 1.2.
- The key stays on the phone: keychain, `AfterFirstUnlockThisDeviceOnly`, never iCloud, **never sent to the watch**
  (the watch knows each Mac by `id` and `name` only).
- A pairing link is untrusted input (`RemotePairing(url:)` refuses anything not exactly as the Mac writes it); a link
  that arrives from outside the app is shown for confirmation, never saved on its own.
- Any change to what is sent, to whom or what is stored → update `docs/PRIVACY.md` (Network connections › 14),
  `docs/remote-monitor.md` and the iPhone's Settings › Privacy text in the same change.

## Code shared across targets

One file, several compilers — so each shared file imports only what every target has.

| File | Compiled into | Constraint |
|---|---|---|
| `Sources/Vorssaint/Services/RemoteMonitor/RemoteMonitorProtocol.swift` | Mac app, Mac tests, iPhone, watch, widgets | Foundation only, plain `Sendable` values; Swift 5 on the Mac (down to the 6.0.3 CI job) **and** Swift 6 on iOS. Bump `RemoteMonitorProtocol.version` when a message changes shape |
| `iOS/Beacon/Connection/WatchLink.swift` | iPhone, watch | Foundation only. Both apps ship in one bundle, so they always speak the same version |
| `iOS/Beacon/Stores/Readings.swift` | iPhone, watch, widgets | `MetricKind`, `LiveHistory`, `RemoteSnapshot.headline(_:unit:)`; SwiftUI only, no UIKit |
| `iOS/Beacon/Features/Detail/MetricRows.swift` | iPhone, watch | The detail rows both draw — the watch shows every reading the phone does |
| `iOS/Beacon/Formatting/Format.swift`, `Fixtures/DemoData.swift` | iPhone, watch, widgets | Foundation only |
| `iOS/Beacon/DesignSystem/BeaconStyle.swift`, `Components/*`, `Catalog/KitSpecimen.swift` | iPhone, watch | SwiftUI only |
| `iOS/Beacon/DesignSystem/BeaconColor.swift` | iPhone **only** | Uses `UIColor(dynamicProvider:)`/`UIColor.system*`, unavailable on watchOS; the kit collector parses its lines. The watch has `BeaconWatch/DesignSystem/BeaconColor+watchOS.swift` with the same API |
| `iOS/BeaconWatch/Shared/LastReading.swift` | watch, widgets | The complication's data |

The target lists live in `iOS/project.yml`: a file shared with the watch or the widgets is listed there by path.

## Platforms and versions

| | Mac app | iPhone | Watch |
|---|---|---|---|
| Minimum OS | macOS 14, Apple Silicon | iOS 27 | watchOS 27 |
| Build | `build.sh` + `swiftc`, no Xcode project | XcodeGen → `iOS/Beacon.xcodeproj` (never committed) | same project, `BeaconWatch` target embedded in `Beacon.app/Watch` |
| Swift | Swift 5 mode, Combine/`ObservableObject`, **no macros** | Swift 6, strict concurrency, `@Observable` | same as iPhone |
| Bundle id | `com.vorssaint.utils` (Developer build: `com.vorssaint.utils.dev`) | `co.ikili.beacon` | `co.ikili.beacon.watchkitapp` (+ `.widgets`) |
