# Design system — iPhone and Apple Watch

Beacon's design system is tokens from the start (`iOS/Beacon/DesignSystem/`). Screens use the tokens and the shared
components; a screen never defines its own palette, fonts or spacing. A missing value goes into the tokens.

## Tokens

| Token | File | What |
|---|---|---|
| `BeaconColor` | `DesignSystem/BeaconColor.swift` (iPhone), `iOS/BeaconWatch/DesignSystem/BeaconColor+watchOS.swift` (watch) | Metric colours (`cpu` green, `gpu` mint, `memory` cyan, `download` = accent blue, `upload`/`temperature` orange, `power` yellow, `disk` pink, `fan` secondary), states (`positive`, `caution`, `critical`), surfaces (`canvas`, `tile`, `track`, `hairline`), `level(_:calm:)` (calm < 60 % ≤ caution < 85 % ≤ critical) |
| `BeaconType` | `DesignSystem/BeaconStyle.swift` | SF Pro Rounded, monospaced digits for readings: `hero`, `reading`, `readingSmall`, `tileTitle`, `unit`, `caption`, `section`; system text styles elsewhere so Dynamic Type scales |
| `BeaconMetrics` | `BeaconStyle.swift` | 4-pt grid: `spacing2…6` (4–20), `margin` 16, `tileRadius` 24, `tilePadding` 16, `tileMinHeight` 148, `sparkHeight` 36, `ringLineWidth` 8, `barHeight` 6 |
| `BeaconMotion` | `BeaconStyle.swift` | `reading` (smooth 0.45 s, no bounce: a number that overshoots reads as a wrong number), `tap`, `appear` |

**Colour meaning follows the Mac.** Each metric keeps the colour the Mac's menu panel gives it (`PanelMetricColor` in
`Sources/Vorssaint/UI/Theme.swift`): the system colour in dark mode, the same hue darkened in light mode. Each
`BeaconColor` doc line names its Mac token. The watch file has the same names with the dark values only (watchOS is
always dark; `UIColor(dynamicProvider:)` and `UIColor.system*` don't exist there). **Change a colour in both files.**

## Components (`DesignSystem/Components/`, shared by iPhone and watch)

| Component | File | Use |
|---|---|---|
| `MetricTile` | `MetricTile.swift` | A dashboard tile: icon + title in the tint, the reading, unit, caption, an accessory (chart/bar/ring) |
| `GaugeRing` | `GaugeRing.swift` | A level as a ring, colour following `level` unless `warns: false` |
| `SparkChart` | `SparkChart.swift` | Recent readings as an axis-less area chart (`maxValue` fixed for shares) |
| `LevelBar`, `PressureBadge`, `StatusPill`, `StatRow`, `CoreGrid`, `EmptyState` | `Indicators.swift` | Bars, memory pressure, connection status, label–value rows, per-core bars, empty screens |
| `HistoryChart` | `Features/Detail/MetricDetailView.swift` | iPhone only: chart with axes and scrubbing |
| `MetricRows` | `Features/Detail/MetricRows.swift` | The detail rows, shared by both detail pages |

Each component declares a `KitSpecimen` beside its code; its `#Preview`s, Settings › Design catalog and the BeaconKit
site draw that one declaration (`ref/features/BeaconKit.md`).

## Rules

- New view → `#Preview` (demo data from `DemoData`, `AppModel(demoOnly: true)` / `WatchModel(demoOnly: true)`).
- A shared component must lay out on a 46 mm watch as well as a phone: prefer `ViewThatFits(in: .horizontal)` (side by
  side where it fits, stacked where it doesn't) over `#if os(watchOS)`.
- Readings animate with `BeaconMotion.reading` and `.contentTransition(.numericText())`. Scope repeating animations to
  the property they animate (`.animation(_:body:)`): a `repeatForever` attached with `.animation(_:value:)` also catches
  layout changes and swings the view between positions for good (`StatusPill` had this).
- Wrist down (`isLuminanceReduced`), watch screens drop animations (`.transaction { $0.animation = nil }`).
- Tiles are plain cards; Liquid Glass belongs to controls floating over content, not to content.
- Accessibility: rows combine their children; bars and rings carry `accessibilityValue` with the formatted reading.
