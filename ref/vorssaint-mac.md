# Vorssaint — the Mac app (upstream)

The Mac app is upstream's: a native menu-bar utility with ~80 features, built by `build.sh` without an Xcode project.
Beacon adds one service to it (`ref/features/RemoteMonitor.md`) and the kit renders (`Sources/Vorssaint/Kit/`). This
file is the map for finding your way; upstream's own rules are `CONTRIBUTING.md` and `docs/AI-CONTRIBUTIONS.md`
(read both before changing upstream code), and its docs are `docs/PRIVACY.md`, `docs/PERMISSIONS.md`,
`docs/TROUBLESHOOTING.md`.

## Layout (`Sources/Vorssaint/`)

| Folder | Holds |
|---|---|
| `main.swift` | CLI first (`--export-settings`/`--import-settings`, `--selftest`, `--sensors`, `--uninstall`; development builds also `--kit-render`, notch probes), then `NSApplication` + `AppDelegate` |
| `App/` | Lifecycle: `AppDelegate` (accessory app, migrations, status item, `NSPopover` with `MenuPanelView`, hotkeys, `FeatureRuntime.syncAtLaunch()`, update checks), `FeatureRuntime` (one sync closure per feature), `StatusItemController` + `MenuBarRenderer` (the menu-bar item and per-metric items) |
| `Core/` | Catalogs and preferences: `FeatureCatalog`, `FeaturePresets`, `Defaults` (`DefaultsKey`, every key), `SettingsBackupSupport`, `Localization` + `Localizations/`, `*Strings.swift` per feature, `Permissions` |
| `Services/` | Behaviour, a folder or file per feature (`Clipboard/`, `Notch/` (50 files), `SystemMonitor/`, `Metrics/`, `RemoteMonitor/`, …) |
| `UI/` | Views: `MenuPanel/` (the popover), `Settings/` (a `*Settings.swift` per page, `SettingsCard`, sidebar, search), `Notch/` (the Dynamic Island), `Theme.swift` (`PanelMetricColor`, `PanelSurface`), feature windows |
| `Support/` | `SelfTest` (`--selftest`: core checks fail, hardware readings warn), `SensorDump` (`--sensors`), `Uninstaller`, development-only notch probes |
| `Kit/` | BeaconKit™ renders, `#if VORSSAINT_DEVELOPMENT` only (`ref/features/BeaconKit.md`) |

Helper targets: `Sources/FanControlHelper` (privileged fan daemon over XPC), `HIDEventSystem` (modulemap for private
IOKit HID headers), `NowPlayingAdapter` (a dylib loaded through `Resources/now-playing.pl`, since MediaRemote is
Apple-signed-only from macOS 15.4), `VMStatisticsCompat` (VM statistics layout for older SDKs).

## Features

`Core/FeatureCatalog.swift`: `enum AppFeature: String, CaseIterable` — raw values are persisted, so add cases, never
rename them. Each feature has a `group`, `symbolName`, `availabilityKey` (`featureAvailable.<id>`), `enabledKeys`,
`permissions`, `installedByDefault`… Two layers of on/off: the hub's **availability** above the feature's own enable
key(s); a service runs only when `AppFeature.x.isAvailable && defaults.bool(enableKey)`, and a feature switched off
never instantiates its service. `FeaturePresets.swift`: `essential` (fresh installs), `windows`, `battery`.

| Group (`FeatureGroup`) | Examples | Services/ | UI/ |
|---|---|---|---|
| windowsDock | switcher, dockPreview, dockClick, windowLayout, autoQuit, spacesOrder | `Switcher`, `DockPreview`, `DockClick`, `WindowLayout`, `AutoQuit`, `SpacesOrder` | `Switcher` |
| mouseKeyboard | scrollInverter, smoothScroll, middleClick, keyboardDebounce, superKey, textSnippets | `MouseButtons`, `MiddleClick`, `MouseNavigation`, `FocusFollowsMouse`, `KeyboardDebounce`, `SuperKey`, `Snippets`, `QuitProtection` | `QuitProtection`, `Settings/MouseSettings` |
| clipboardFiles | clipboardHistory, pastePlain, finderCutPaste, shelf, urlCleaner, diskImageInstaller | `Clipboard`, `Finder`, `Shelf`, `DiskImageInstaller` | `Shelf`, `Finder`, `MenuPanel/PanelClipboardView` |
| sound | mixer, soundOutputSwitcher, audioPriority, micMute, musicBlock | `Audio`, `QuickTools` | `MenuPanel/MixerSection` |
| energyDisplay | keepAwake, brightness, extraBrightness, bluetoothSleep | `KeepAwakeManager`, `Display`, `Bluetooth` | `Settings/EnergySettings` |
| tools | quickLauncher, cleaner, homebrew, screenRecorder, commandBar, killProcess | `QuickTools`, `Cleaner`, `Homebrew`, `Recorder`, `CommandBar`, `KillProcess`, `PortManager`, `Media` | the same names |
| dynamicIsland | notch, notchCalendar, notchLyrics, notchAgents, notchMascot | `Notch`, `AgentUsage` | `Notch` |
| monitor | monitorCPU, monitorGPU, monitorNetwork, monitorPower, fanControl | `SystemMonitor`, `Metrics`, `FanControl`, `RemoteMonitor` | `MenuPanel/*Section` |

A new feature's entry points: a binding in `FeatureRuntime.bindings`; a `SettingsPage` case and its gate in
`UI/Settings/FeatureVisibilitySupport.swift` + the view in `SettingsView`'s switch; the hub row in
`UI/Settings/FeatureHubSettings.swift`; a menu-panel section via `PanelLayout.swift`. Its preferences take part in the
settings backup; machine state and private content are excluded (`SettingsBackupSupport.machineStateKeys`).

## SystemMonitor — where Beacon's readings come from

`Services/SystemMonitor/SystemMonitor.swift`: `SystemMonitor.shared` publishes a `SystemSnapshot` (CPU per core, GPU,
temperatures, memory parts and pressure, fans, network rates and totals, power and battery, disks, USB, histories).
Sampling runs on a utility queue on a timer that stops when nothing needs it. Consumers declare what they need
(`SystemMonitorPanelNeeds`): `setMenuPanelNeeds`, `setNotchDetailNeeds`, `setRemoteNeeds` (Beacon), … The interval is
`monitorIntervalSeconds` (1, 2 or 5; default 2). Samplers live in `Services/Metrics/`; sensor choice in
`TemperatureSensorSelector`.

## Rules for touching upstream code

- Prefer a new Beacon file plus a one-line hook over editing upstream logic; check other callers and the upgrade path
  when changing shared behaviour.
- Swift 5 mode, `ObservableObject`/Combine, no macros, macOS 14 (`ref/swift-conventions.md` › Mac).
- Every user-visible string in all 15 languages (`ref/localization.md` › Mac); every new permission prompt localized.
- New source files carry the SPDX header. A test that needs a production file lists it in `TEST_SOURCES` in `build.sh`.
- Sensor changes come with a `./build/Vorssaint --sensors` dump and the Mac model.
- `CHANGELOG.md` is upstream's release log: it ships in the app and the release workflow builds notes from it. Beacon
  changes go into `CHANGELOG.beacon.md` / `CHANGELOG.beacon.en.md` (`ref/release-notes.md`).
