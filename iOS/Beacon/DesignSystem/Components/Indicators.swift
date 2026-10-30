// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// A level as a thin bar: the Mac panel's UsageBar, a little taller for a finger's reading distance.
struct LevelBar: View {
    var fraction: Double
    var tint: Color
    var warns = true

    var body: some View {
        let value = min(1, max(0, fraction))
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(BeaconColor.track)
                Capsule()
                    .fill((warns ? BeaconColor.level(value, calm: tint) : tint).gradient)
                    .frame(width: max(BeaconMetrics.barHeight, proxy.size.width * value))
                    .animation(BeaconMotion.reading, value: value)
            }
        }
        .frame(height: BeaconMetrics.barHeight)
        .accessibilityValue(Format.percent(value))
    }
}

/// Memory pressure as the Mac shows it: a dot and a word in green, yellow or red.
struct PressureBadge: View {
    /// `normal`, `warning`, `critical` or `unknown`, as the protocol sends it.
    var pressure: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(BeaconType.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.14), in: Capsule())
    }

    private var color: Color {
        switch pressure {
        case "normal": return BeaconColor.positive
        case "warning": return BeaconColor.caution
        case "critical": return BeaconColor.critical
        default: return .secondary
        }
    }

    private var label: LocalizedStringKey {
        switch pressure {
        case "normal": return "Normal"
        case "warning": return "Warning"
        case "critical": return "Critical"
        default: return "Unknown"
        }
    }
}

/// Where a Mac's connection stands: a dot and a word, green when readings flow.
struct StatusPill: View {
    enum Kind { case live, connecting, offline, demo }
    var kind: Kind

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                // The pulse animates the dot's opacity only: a repeating animation that caught the pill moving would
                // swing the dot between both places for good.
                .animation(kind == .connecting ? .easeInOut(duration: 0.8).repeatForever() : .default) {
                    $0.opacity(kind == .connecting ? 0.5 : 1)
                }
            Text(label).font(BeaconType.caption.weight(.semibold))
        }
        .foregroundStyle(kind == .offline ? Color.secondary : color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        switch kind {
        case .live: return BeaconColor.positive
        case .connecting: return BeaconColor.caution
        case .offline: return .secondary
        case .demo: return .accentColor
        }
    }

    private var label: LocalizedStringKey {
        switch kind {
        case .live: return "Live"
        case .connecting: return "Connecting"
        case .offline: return "Offline"
        case .demo: return "Demo"
        }
    }
}

/// A label and its value on one line, for the detail pages' lists.
struct StatRow: View {
    let title: LocalizedStringKey
    var value: String
    var tint: Color? = nil

    var body: some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: BeaconMetrics.spacing4)
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(tint ?? .primary)
                .contentTransition(.numericText())
                .animation(BeaconMotion.reading, value: value)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Each core's load as a short bar, performance cores first as the Mac reports them.
struct CoreGrid: View {
    var usage: [Double?]

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: min(max(usage.count, 1), 6))
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(usage.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 4) {
                    GeometryReader { proxy in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(BeaconColor.track)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(BeaconColor.level(value ?? 0, calm: BeaconColor.cpu).gradient)
                                .frame(height: proxy.size.height * min(1, max(0.02, value ?? 0)))
                                .animation(BeaconMotion.reading, value: value ?? 0)
                        }
                    }
                    .frame(height: 44)
                    Text("\(index + 1)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Core \(index + 1)"))
                .accessibilityValue(Format.percent(value))
            }
        }
    }
}

/// What a screen shows when there is nothing yet: a symbol, a title, a line and the one thing to do.
struct EmptyState<Actions: View>: View {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            actions()
        }
    }
}

extension KitSpecimen {
    @MainActor static let levelBar = KitSpecimen("LevelBar", .instruments, [
        KitVariant("calm", "fraction: 0.23") { LevelBar(fraction: 0.23, tint: .accentColor) },
        KitVariant("caution", "fraction: 0.72") { LevelBar(fraction: 0.72, tint: .accentColor) },
        KitVariant("critical", "fraction: 0.93") { LevelBar(fraction: 0.93, tint: .accentColor) },
        KitVariant("disk", "warns: false, tint: BeaconColor.disk") { LevelBar(fraction: 0.51, tint: BeaconColor.disk, warns: false) },
    ])

    @MainActor static let pressureBadge = KitSpecimen("PressureBadge", .badges, [
        KitVariant("normal", "pressure: \"normal\"", width: 140) { PressureBadge(pressure: "normal") },
        KitVariant("warning", "pressure: \"warning\"", width: 140) { PressureBadge(pressure: "warning") },
        KitVariant("critical", "pressure: \"critical\"", width: 140) { PressureBadge(pressure: "critical") },
    ])

    @MainActor static let statusPill = KitSpecimen("StatusPill", .badges, [
        KitVariant("live", ".live", width: 140) { StatusPill(kind: .live) },
        KitVariant("connecting", ".connecting", width: 140) { StatusPill(kind: .connecting) },
        KitVariant("offline", ".offline", width: 140) { StatusPill(kind: .offline) },
        KitVariant("demo", ".demo", width: 140) { StatusPill(kind: .demo) },
    ])

    @MainActor static let statRow = KitSpecimen("StatRow", .rows, [
        KitVariant("plain", "StatRow(title:value:)") { StatRow(title: "Compressed", value: Format.bytes(1_100_000_000)) },
        KitVariant("tinted", "tint:") { StatRow(title: "Charging", value: Format.watts(12.4), tint: BeaconColor.power) },
    ])

    @MainActor static let coreGrid = KitSpecimen("CoreGrid", .instruments, [
        KitVariant("ten", "usage: 10 cores") { CoreGrid(usage: DemoData.snapshot.cpuCoreUsage) },
    ])

    @MainActor static let emptyState = KitSpecimen("EmptyState", .rows, [
        KitVariant("noMacs", "EmptyState(symbol:title:message:actions:)", height: 320) {
            EmptyState(symbol: "macbook.and.iphone", title: "No Macs yet", message: "Turn on Watch from iPhone in your Mac's Settings › Monitor, then scan its code.") {
                Button("Add a Mac") {}.buttonStyle(.borderedProminent)
            }
        },
    ])
}

#Preview("Indicators") {
    ScrollView {
        VStack(spacing: 24) {
            KitSpecimen.levelBar.preview()
            KitSpecimen.pressureBadge.preview()
            KitSpecimen.statusPill.preview()
            KitSpecimen.statRow.preview()
            KitSpecimen.coreGrid.preview()
        }
    }
}
