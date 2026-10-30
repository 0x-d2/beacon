# Build and test

## Mac app (`build.sh`, no Xcode project)

```sh
./build.sh --dev                     # "Vorssaint (Developer)", com.vorssaint.utils.dev, -D VORSSAINT_DEVELOPMENT -Onone
./build.sh --dev --install           # the same, installed to /Applications (needed for Local Network, Bonjour, TCC)
./build.sh                           # the optimized variant CI builds
./build/Vorssaint --selftest         # health check (the binary's flag, not build.sh's); --sensors dumps sensors
./build.sh --test                    # build/metrics-tests + Tests/*.sh
./build.sh --test-suite=remote-monitor   # one suite; --list-tests lists them (~51)
./build.sh --typecheck-dev           # type-checks development-only code (Kit/), as CI does
```

- Target `arm64-apple-macosx14.0`, built with the Command Line Tools against the pinned macOS 26 SDK. `Package.swift`
  is for editor indexing only.
- The app compiles `Sources/Vorssaint/**/*.swift`; the test binary compiles only `TEST_SOURCES` in `build.sh` plus
  `Tests/` — list a production file there when a test needs it.
- Tests are a custom harness (`Tests/TestSuite.swift`: `suite.expect(…)`), not XCTest: a file exposes
  `enum XTests { static func run(_ suite: TestSuite) }` and is registered under a suite name in
  `Tests/MetricsTests.swift`.
- Signing: a stable local identity (`Tools/setup-signing.sh`, created automatically by dev/install builds); ad-hoc
  signatures invalidate permission grants on every build.
- CI (`.github/workflows/ci.yml`, push to main and PRs): Swift 6.0.3 compatibility build + tests on macos-15, the full
  build + DMG + tests + `--typecheck-dev` on macos-26, and `web/` collect + build on ubuntu. `release.yml` on `v*` tags.
  The BeaconKit workflow lives in the private `0x-d2/beacon-kit-runner` (`ref/features/BeaconKit.md`).

## iPhone and watch (XcodeGen)

**After any file add, move, rename or delete under `iOS/`, run `cd iOS && xcodegen generate`.** The project
(`iOS/Beacon.xcodeproj`) is generated and never committed; never edit `project.pbxproj` — settings, targets, sources,
Info.plist keys and entitlements live in `iOS/project.yml`. A file the watch or the widgets compile from `iOS/Beacon/`
is listed by path in their target's `sources`.

```sh
cd iOS
xcodegen generate
xcodebuild -project Beacon.xcodeproj -scheme Beacon \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build/DerivedData test   # + the watch app
xcodebuild -project Beacon.xcodeproj -scheme BeaconWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -derivedDataPath build/DerivedData build
```

- Targets: `Beacon` (iOS app, embeds `BeaconWatch` in `Beacon.app/Watch`), `BeaconWatch` (watchOS app, embeds
  `BeaconWatchWidgets` in `PlugIns`), `BeaconWatchWidgets` (WidgetKit extension), `BeaconTests` (Swift Testing,
  hosted by the app). Schemes: `Beacon`, `BeaconWatch`.
- Signing: `iOS/Config/Beacon.xcconfig` includes the git-ignored `Local.xcconfig` (the owner's `DEVELOPMENT_TEAM`).
  Simulator builds need no team ("Sign to Run Locally"); don't build with `CODE_SIGNING_ALLOWED=NO` — an unsigned app
  can't use the keychain or the app group.
- The build has two known warnings (`IsolatedConformances` in the specimen declarations); add none.

## Simulators

| Simulator | Use |
|---|---|
| iPhone 18 Pro (iOS 27) | Tests and quick runs |
| iPhone 17 Pro Max + Apple Watch Series 11 (46mm), paired (`xcrun simctl list pairs`) | Anything that involves the watch |
| "BeaconKit" (iPhone 18 Pro) | `docs/scripts/kit.sh` only |
| Names with another workspace's city ("… (Podgorica)") | Not yours — don't touch |

Shut down the simulators you booted when you're done.

## Launch arguments and screenshots

- iPhone: `-demo 1`, `-screen dashboard|cpu|memory|gpu|network|power|disk|temperature|fans`, `-pair '<beacon://…>'`,
  `-kitExport 1`. Watch: `-demo 1`, `-screen …` (same ids). Language: `-AppleLanguages "(tr)" -AppleLocale tr_TR`.
- ```sh
  xcrun simctl launch "$SIM" co.ikili.beacon -demo 1 -screen cpu -AppleLanguages "(tr)" -AppleLocale tr_TR
  xcrun simctl io "$SIM" screenshot .context/beacon-cpu-tr.png
  ```
  In zsh build the arguments as an array; an unquoted `${x:+-screen $x}` is passed as one argument.
- Visual changes: screenshot both languages (and both themes on iPhone), look at them, and show them in the final
  message from `.context/`.

## End to end (a stand-in Mac)

Pairing with the real Mac app needs clicks in its Settings. For a scripted run, write a stand-in server in
`.context/spikes/<name>/main.swift`: an `NWListener` with the same parameters as
`RemoteMonitorService.parameters(keys:)` (TLS 1.2, `TLS_PSK_WITH_AES_128_GCM_SHA256`, WebSocket) and one random
key, that prints its `RemotePairing(…).url`, answers `hello` with `info`, `subscribe` with `history`, and sends a
`snapshot` every 2 s. Build it with
`swiftc main.swift ../../../Sources/Vorssaint/Services/RemoteMonitor/RemoteMonitorProtocol.swift -o server`, run it on a
free port (not 47823 if the Developer app listens there), then `simctl launch … co.ikili.beacon -pair '<link>'`. The
server's log shows `hello`/`subscribe`/`ping` — the phone's side of the conversation. Stop it when done.

For the watch: background the phone app (launch Settings on it) or leave it not running, launch the watch app without
`-demo`, and check that the watch goes live and that the server sees `subscribe {active: false}` ~15 s after the watch
app is terminated.

## What the simulator can't prove

Real-watch networking rules (TN3135), WatchConnectivity background-wake timing, app-group signing with the owner's
team, the camera scanner, Local Network prompts. Say which of these a change depends on and that it wasn't run.
