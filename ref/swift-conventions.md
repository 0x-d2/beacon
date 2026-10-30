# Swift conventions

Two worlds share this repo: the Mac app is upstream's Swift 5-mode code built by `swiftc`; the iPhone and watch apps
are Swift 6 with complete strict concurrency. Write each side the way the code around it is written.

## Every file

- New source files start with the SPDX header:
  ```swift
  // SPDX-License-Identifier: GPL-3.0-or-later
  // Copyright (C) 2026 Vorssaint
  ```
- Comments are English prose in the code's own voice: a `///` on every type and non-obvious member saying what it is
  for and why ("Pings while connected; a Mac silent for 15 seconds is gone"), not what the syntax does. Match the
  density of the file you're in. Point to the doc that has the rest (`(docs/remote-monitor.md)`).
- Names read as English: `watchedFromWatch`, `pairingUsed(by:)`, `scheduleIdleClose()`.

## iPhone and watch (Swift 6)

- **State:** `@MainActor @Observable final class` (`AppModel`, `MacSession`, `WatchModel`, `WatchMacState`). Mark
  lazily-filled caches and closures `@ObservationIgnored`. `private(set)` for what views only read.
- **Callbacks from system queues** (`NWConnection`, `WCSessionDelegate`): either start the object on `.main` and wrap
  the handler body in `MainActor.assumeIsolated { … }` (`MacSession`), or make the delegate method `nonisolated`, turn
  the payload into a `Sendable` value there, and hop with `DispatchQueue.main.async { MainActor.assumeIsolated { … } }`
  — that keeps message order. Unstructured `Task { @MainActor in … }` doesn't guarantee order between messages.
- **Closures passed to Objective-C APIs that aren't annotated** (e.g. `sendMessageData`'s `errorHandler`) and that run
  on another queue: write them `{ @Sendable _ in … }`. A closure formed on the main actor is main-actor-isolated in
  Swift 6, and calling it from another queue traps at run time.
- **Observing an `@Observable` from code:** `Observations { … }` (iOS/watchOS 26+) in a `Task`, comparing with the last
  value (`WatchRelay.forward`).
- **Screens count themselves in and out** of whatever they need (`watch()` in `onAppear`, `unwatch()` in
  `onDisappear`), so a push between two screens of the same Mac never drops it in between.
- **Launch arguments** read through `UserDefaults.standard` (`-screen cpu` → `string(forKey: "screen")`); booleans
  through `ProcessInfo.processInfo.arguments.contains("-demo")`.
- **Tests:** Swift Testing in `iOS/BeaconTests/` (`@Suite`-less `struct`s marked `@MainActor`, `@Test func` named as a
  sentence: `thePhoneStopsForAWatchThatGoesQuiet`). Test behaviour, not the implementation's lines; inject time
  (`WatchRelay(model:silence:)`) instead of sleeping long. Demo-only models (`AppModel(demoOnly: true)`) touch neither
  the keychain nor WatchConnectivity.
- Known pre-existing warnings: `IsolatedConformances` at `Indicators.swift` / `MetricTile.swift` specimen declarations.
  Don't add new warnings.

## Mac (upstream, Swift 5 mode)

- `ObservableObject` + `@Published`, Combine, GCD queues; **no macros** (`@Observable`, `#Preview`): the app builds
  with the Command Line Tools against the macOS 26 SDK. Minimum macOS 14.
- Services own their queue and say so (`// Queue-confined.`), UI state is published on main (`onMain { … }`).
- Keep reusable decisions outside views where they can be tested (upstream's `CONTRIBUTING.md`).
- Every user-visible string goes through the feature's `…Strings.swift` for all 15 languages (`ref/localization.md`).
- More: `ref/vorssaint-mac.md`.

## Known gotchas

- **watchOS networking:** the simulator allows what a real watch blocks (TN3135). Never judge watch networking by the
  simulator.
- **zsh doesn't word-split** an unquoted `${3:+-screen $3}`: build argument arrays (`args+=(-screen "$3")`) in scripts
  that pass launch arguments to `simctl launch`.
- **`UIColor` on watchOS:** `UIColor(dynamicProvider:)`, `UIColor.systemGreen`, `systemGroupedBackground` are
  unavailable — use SwiftUI `Color`s in watch code.
- **WatchConnectivity `isReachable`** reads false for a moment after activation; don't show "unreachable" on the first
  failed send.
