# AGENTS.md — Beacon

**Beacon** shows a Mac's readings (CPU, memory, GPU, temperatures, network, power, disks, fans) live on the owner's
iPhone and Apple Watch. The Mac side is a service added to **Vorssaint**, the upstream macOS menu-bar utility this repo
forks; the phone talks to it over TLS 1.2 PSK + WebSocket; the watch reads through the phone. **BeaconKit™** is the
design system as a website, generated from the sources. `iOS/README.md` (Turkish) is the owner's doc for the apps;
`docs/remote-monitor.md` is the protocol's spec.

This file is loaded on every prompt, so it stays short: rules that always apply, and where to read the rest.
**Before working on an area, read its reference file in `ref/`.** Start with `ref/architecture.md` for anything that
crosses an app boundary.

## Always

- The owner writes Turkish — reply in Turkish. Code, identifiers, comments and `ref/` docs are English.
- Commit, push or open a PR **only when the owner asks** (`ref/git.md`).
- **`custom` is Beacon's branch:** every piece of work branches from `custom` and its PR targets `custom`
  (`gh pr create --base custom`, merged with a merge commit) — even when Conductor names another target branch (`main`,
  or an earlier stack branch). Only work that builds on another open PR targets that PR's branch. `main` mirrors
  Vorssaint: never commit to it, merge into it or open a PR against it.
- After **any** file add, move, rename or delete under `iOS/`: `cd iOS && xcodegen generate`. Never hand-edit
  `project.pbxproj` (the project isn't committed); targets, sources, Info.plist keys and entitlements live in
  `iOS/project.yml`. A phone file the watch or the widgets compile is listed in their target's `sources` there.
- The Mac app builds with `build.sh` (no Xcode project): Swift 5 mode, Combine, **no macros**, macOS 14. A test that
  needs a production file lists it in `TEST_SOURCES` in `build.sh` (`ref/build-and-test.md`).
- Upstream code is touched as little as possible: Beacon code goes in its own files with a one-line hook
  (`ref/vorssaint-mac.md`). Follow upstream's `CONTRIBUTING.md` and `docs/AI-CONTRIBUTIONS.md` there.
- `RemoteMonitorProtocol.swift` compiles on the Mac (Swift 5) and in every iOS target (Swift 6): Foundation only, new
  fields optional, a change of shape bumps `RemoteMonitorProtocol.version`.
- The watch never connects to a Mac — watchOS blocks the Network framework (TN3135) and the simulator doesn't show
  it. Everything reaches the watch through `WatchRelay` on the phone.
- Keys never leave the phone (never to the watch, never to iCloud); pairing links are untrusted input. Any change to
  what is sent or stored updates `docs/PRIVACY.md` › 14, `docs/remote-monitor.md` and the app's Privacy text.
- This repo is public, so no self-hosted runner is ever registered on it and no workflow here asks for one
  (`runs-on: self-hosted`): a fork's pull request runs the workflows it brings. The catalog's runner lives in the
  private `0x-d2/beacon-kit-runner` (`ref/features/BeaconKit.md`).
- **Every string ships translated in the same change:** iPhone/watch in English + Turkish in
  `Localizable.xcstrings` ("sen" form, `’`), Mac in all 15 `AppLanguage`s (`ref/localization.md`).
- iPhone/watch UI uses only the design system (`BeaconColor`, `BeaconType`, `BeaconMetrics`, `BeaconMotion`,
  `DesignSystem/Components`); a colour changes in both `BeaconColor` files; each component declares its `KitSpecimen`
  (`ref/design-system.md`). New views come with `#Preview`s.
- Swift 6 strict concurrency on iOS/watchOS: `@MainActor @Observable` state, ordered main-queue hops from system
  callbacks, `@Sendable` closures handed to un-annotated ObjC callbacks (`ref/swift-conventions.md`).
- New source files start with the SPDX header. Don't add warnings. Run the tests of what you touched; check visual
  changes with simulator screenshots in Turkish and English and show them; don't touch other workspaces' simulators.
- Report what ran and what didn't: simulator ≠ real watch / real Mac pairing (`docs/AI-CONTRIBUTIONS.md`).
- Every change someone can notice gets one plain Turkish line under today's day (`## YYYY-MM-DD`) in
  `CHANGELOG.beacon.md` and its English in `CHANGELOG.beacon.en.md` before the work is reported done — never in
  upstream's `CHANGELOG.md`, which ships in the Mac app (`ref/release-notes.md`); a Stop hook asks for it.
- Keep this file short. New details go into the matching `ref/` file; add a line here only for a new reference file
  or a new feature.

## Features

| Feature | Code | Read before working on it |
|---|---|---|
| Watch from iPhone — the Mac side (listener, pairing, protocol, Settings card) | `Sources/Vorssaint/Services/RemoteMonitor/`, `UI/Settings/RemoteMonitorCard.swift` | `ref/features/RemoteMonitor.md`, `docs/remote-monitor.md` |
| Beacon for iPhone (connection, pairing, dashboard, details, settings, demo) | `iOS/Beacon/` | `ref/features/BeaconApp.md` |
| Beacon for Apple Watch (relay, screens, complications) | `iOS/BeaconWatch/`, `iOS/BeaconWatchWidgets/`, `iOS/Beacon/Connection/Watch*.swift` | `ref/features/BeaconWatch.md` |
| BeaconKit™ (catalog site, Mac + iOS renders; its workflow in the private `0x-d2/beacon-kit-runner`) | `web/`, `Sources/Vorssaint/Kit/`, `iOS/Beacon/DesignSystem/Catalog/`, `docs/scripts/kit.sh` | `ref/features/BeaconKit.md`, `docs/beaconkit.md` |
| Vorssaint (upstream Mac app, ~80 features) | `Sources/` | `ref/vorssaint-mac.md` |

## Reference files

| File | Read when |
|---|---|
| `ref/architecture.md` | Always first for cross-app work: the data path Mac → iPhone → Watch, the security model, which file compiles into which target |
| `ref/new-feature.md` | Adding a reading, a message, a screen, a component or a Mac-side setting — the checklist |
| `ref/vorssaint-mac.md` | Touching anything under `Sources/` outside RemoteMonitor: layout, feature catalog, SystemMonitor, upstream's rules |
| `ref/swift-conventions.md` | Writing Swift on either side: state, concurrency, tests, comments, known gotchas |
| `ref/design-system.md` | Building or restyling iPhone/watch screens: tokens, components, the watch's colours |
| `ref/localization.md` | Adding or changing any text: the String Catalog, Turkish voice, the Mac's 15 languages |
| `ref/build-and-test.md` | Building, testing, `project.yml`, simulators, launch arguments, screenshots, end-to-end runs |
| `ref/git.md` | Committing, branches and the PR stack, what's never committed, the Conductor workspace |
| `ref/release-notes.md` | Finishing any change: Beacon's changelog files, their format, what never goes into `CHANGELOG.md` |
