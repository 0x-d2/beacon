# Watch from iPhone

Settings › Monitor › **Watch from iPhone** sends this Mac's readings to the Beacon app on the owner's iPhones
(`iOS/`). It is off by default, and nothing listens on the network until it is on and a phone has been paired.

## How it works

| | |
|---|---|
| `Services/RemoteMonitor/RemoteMonitorProtocol.swift` | The messages, the pairing link and the constants. **Compiled into both apps** (the Mac's `build.sh` and `iOS/project.yml`), so it imports Foundation only and holds plain `Sendable` values; it must build as Swift 5 on the Mac (down to the Swift 6.0.3 CI job) and as Swift 6 on iOS |
| `Services/RemoteMonitor/RemoteMonitorService.swift` | The listener, the connected phones, pairing, and `RemoteMonitorBridge` (`SystemSnapshot` → the protocol's values, field by field) |
| `Services/RemoteMonitor/RemotePairingStore.swift` | The paired phones, one generic password each in the login keychain, under the build's bundle id |
| `UI/Settings/RemoteMonitorCard.swift`, `Core/RemoteMonitorStrings.swift` | The Settings card and its copy in the app's 15 languages |

- **Pairing:** "Add a phone" makes a random 32-byte key and an id for that phone, saves them, and shows
  `beacon://pair?v=1&name=…&host=…&alt=…&port=…&id=…&key=…` as a QR code for 10 minutes. `host` is the Mac's
  `name.local`; `alt` is the address the owner typed for away from home, else this Mac's Tailscale address
  (100.64.0.0/10 on a `utun` interface). A code never used takes its key with it when it expires or is replaced.
- **Transport:** a WebSocket over TLS 1.2 with pre-shared keys (`TLS_PSK_WITH_AES_128_GCM_SHA256`) on port 47823
  (`remoteMonitorPort`), announced on the local network as `_beacon-mac._tcp`. The listener holds every paired
  phone's key and no other, so an unpaired device can't complete the handshake (checked 2026-10-30: a wrong key fails
  with "bad MAC", an unknown identity with "unknown PSK identity"). Removing a phone removes its key, restarts the
  listener and closes that phone's connection. PSK cipher suites exist in TLS 1.2 only, so both ends pin 1.2.
- **Messages:** one JSON text frame each, `{"type": …, "payload": …}`. The phone says `hello` (protocol version, its
  pairing id, its name) and gets `info`; it sends `subscribe {active: true}` while its screen shows readings and gets
  the recent `history` once, then a `snapshot` on every reading; `subscribe {active: false}` when it leaves. Both
  ends `ping` every 5 s; a peer silent for 15 s is dropped. A type a side doesn't know is ignored (`.unknown`), so a
  newer peer can add one.
- **Sampling:** `SystemMonitor.setRemoteNeeds(_:)` makes a subscribed phone a foreground surface like the panel: the
  usual cadence (`monitorInterval`) and history. With no phone subscribed the needs go back to `.none` and, if
  nothing else watches, the monitor stops. The hub's choices still apply: an uninstalled metric is neither sampled
  nor sent.
- **Privacy:** `docs/PRIVACY.md` › Network connections › 14 and `docs/PERMISSIONS.md` (Local Network). The Mac's
  Info.plist carries `NSLocalNetworkUsageDescription` and `NSBonjourServices`; macOS asks for Local Network access
  the first time the listener starts. With the application firewall on, macOS may also ask to accept incoming
  connections.
- **Settings backup:** the three `remoteMonitor…` keys are this Mac's (`SettingsBackupSupport.machineStateKeys`): a
  backup restored on another Mac doesn't turn on a listener there.

## Tests

`./build.sh --test-suite=remote-monitor` (`Tests/RemoteMonitorProtocolTests.swift`): every message survives the round
trip, a newer peer's message reads as unknown, and a pairing link is read only when it is exactly what the Mac writes
(scheme, version, host, port, id and a 32-byte key; a repeated field is refused). `SystemMonitorPlanTests` checks
that a watching phone samples and a phone that stops watching doesn't.
