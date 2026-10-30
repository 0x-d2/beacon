# Watch from iPhone — the Mac side

Settings › Monitor › **Watch from iPhone** (`iPhone'dan izle`): the Mac serves its readings to the paired Beacon
apps. Off by default; nothing listens until it is on and a phone is paired or being paired. The full spec (transport,
messages, sampling, privacy, backup) is `docs/remote-monitor.md` — read it first; this file is the map and the rules.

## Files

| File | Role |
|---|---|
| `Sources/Vorssaint/Services/RemoteMonitor/RemoteMonitorProtocol.swift` | The messages, `RemotePairing` (the QR link), constants (port 47823, path `/beacon/v1`, 15 s silence, 32-byte key). Shared with iOS (`ref/architecture.md` › Code shared) |
| `…/RemoteMonitor/RemoteMonitorService.swift` | `RemoteMonitorService.shared` (`ObservableObject`): the `NWListener`, connected clients (queue-confined on its own `DispatchQueue`), pairing, heartbeat, `RemoteMonitorBridge` (`SystemSnapshot` → protocol values, field by field) |
| `…/RemoteMonitor/RemotePairingStore.swift` | Paired phones, one generic password each in the login keychain under the build's bundle id |
| `Sources/Vorssaint/UI/Settings/RemoteMonitorCard.swift` | The Settings card (switch, QR code, paired phones, address away from home); placed in `UI/Settings/MonitorSettings.swift` |
| `Sources/Vorssaint/Core/RemoteMonitorStrings.swift` | The card's copy in all 15 `AppLanguage` cases (`ref/localization.md` › Mac) |
| `Sources/Vorssaint/Core/Defaults.swift` | `remoteMonitorEnabled`, `remoteMonitorPort`, `remoteMonitorAlternateHost` — machine state, excluded from settings backup in `SettingsBackupSupport.machineStateKeys` |
| `Services/SystemMonitor/SystemMonitor.swift` | `setRemoteNeeds(_:)`: a subscribed phone is a foreground surface like the panel (`SystemMonitorPanelNeeds.remoteReadings`) |
| `App/FeatureRuntime.swift` | One line: `RemoteMonitorService.shared.syncWithPreferences()` |
| `Resources/Info.plist`, `Resources/*.lproj/InfoPlist.strings` | `NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_beacon-mac._tcp`), in every language |
| `Tests/RemoteMonitorProtocolTests.swift`, `Tests/SystemMonitorPlanTests.swift` | Round trips, unknown types, pairing-link parsing; a watching phone samples, one that stops doesn't |

## How it behaves

- **Pairing:** "Add a phone" → `startPairing()`: fresh id + key saved to the keychain, the listener restarted with it,
  the QR code shown for 10 min (`pairingLifetime`). A code never used takes its key with it when it expires or is
  replaced. The phone's `hello` names it (`pairingUsed(by:)`) and puts the code away.
- **Connection:** a peer that doesn't say `hello` within 10 s is dropped. `hello` with another protocol version →
  `refused("protocol N")`; an unknown id → `refused("unknown")`; otherwise `info`. `subscribe {active: true}` → the
  recent `history` and a `snapshot` at once, then a `snapshot` on every reading; `active: false` stops them.
- **Removing a phone** (`remove(id:)`): its key leaves the keychain and the listener, and an open connection gets
  `refused("removed")` and is closed. The iPhone shows "This phone was removed on the Mac".
- **Away from home:** `alt` in the QR code is the address the owner typed, else the Mac's Tailscale address
  (100.64.0.0/10 on a `utun` interface).
- The Apple Watch never connects here: to the Mac it is the phone watching (`ref/features/BeaconWatch.md`).

## Rules

- The protocol file compiles in three places with two Swift modes: Foundation only, plain `Sendable` values, no
  Swift-6-only syntax. Add a field as optional so an older peer still decodes; a change of shape bumps
  `RemoteMonitorProtocol.version` (the Mac then refuses older phones with `refused("protocol N")`).
- A new message type is safe: an unknown `type` decodes as `.unknown` on both sides and is ignored.
- A new reading goes Mac `SystemSnapshot` → `RemoteMonitorBridge` → `RemoteSnapshot` (optional) → iOS
  (`ref/new-feature.md` › A new reading).
- Mac code style is upstream's: `ObservableObject` + Combine, GCD queues, no macros (`ref/vorssaint-mac.md`).
- A test that needs a new source file: add the file to `TEST_SOURCES` in `build.sh` (the app itself globs
  `Sources/Vorssaint/**/*.swift`).
- Check: `./build.sh --test-suite=remote-monitor`, then the whole `./build.sh --test` before reporting done.
- Trying it for real needs the installed Developer app (`./build.sh --dev --install`): Local Network permission and
  Bonjour need a signed bundle with an Info.plist (`ref/build-and-test.md`).
