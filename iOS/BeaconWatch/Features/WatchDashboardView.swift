// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// One Mac on the wrist: every reading the phone's dashboard shows, a row
/// each, each opening its page. The watch asks the phone for readings while
/// this is on screen and stops when it leaves.
struct WatchDashboardView: View {
    @Environment(WatchModel.self) private var model
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let state: WatchMacState

    var body: some View {
        List {
            WatchMacHeader(state: state)
            ForEach(MetricKind.dashboard) { kind in
                NavigationLink(value: WatchRoute.metric(state.id, kind)) {
                    WatchMetricRow(kind: kind, snapshot: state.snapshot, history: state.history, cpuCores: state.info?.cpuCores,
                                   unit: model.temperatureUnit)
                }
            }
        }
        .navigationTitle(state.info?.name ?? state.mac.name)
        // Wrist down, the screen updates rarely: numbers jump to their value rather than ease.
        .transaction { if isLuminanceReduced { $0.animation = nil } }
        .onAppear { state.watch() }
        .onDisappear { state.unwatch() }
    }
}

/// Where a Mac's readings stand, above them: live, connecting, the iPhone out
/// of reach, the Mac turning the phone away.
struct WatchMacHeader: View {
    let state: WatchMacState

    var body: some View {
        VStack(alignment: .leading, spacing: BeaconMetrics.spacing2) {
            HStack(spacing: BeaconMetrics.spacing3) {
                StatusPill(kind: state.pillKind)
                if case .live(away: true) = state.status {
                    Image(systemName: "globe").foregroundStyle(.secondary).accessibilityLabel("Away")
                }
            }
            if let note = state.note {
                Text(note).font(.footnote).foregroundStyle(.secondary)
            } else if let info = state.info {
                Text("\(info.model) · \(info.osVersion)").font(.footnote).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .listRowBackground(Color.clear)
    }
}

/// One reading on the wrist's dashboard: its name in its colour, the number
/// and a word beside it, and the small chart or bar that suits it.
struct WatchMetricRow: View {
    let kind: MetricKind
    let snapshot: RemoteSnapshot?
    let history: LiveHistory
    let cpuCores: Int?
    let unit: TemperatureUnit

    var body: some View {
        let value = snapshot?.headline(kind, unit: unit) ?? "–"
        VStack(alignment: .leading, spacing: BeaconMetrics.spacing2) {
            Label(kind.title, systemImage: kind.symbol)
                .font(BeaconType.tileTitle)
                .foregroundStyle(kind.tint)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: BeaconMetrics.spacing3) {
                Text(value)
                    .font(BeaconType.readingSmall)
                    .contentTransition(.numericText())
                    .animation(BeaconMotion.reading, value: value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if let caption {
                    Text(caption).font(BeaconType.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            accessory
        }
        .padding(.vertical, BeaconMetrics.spacing2)
        .accessibilityElement(children: .combine)
    }

    /// The word beside the number, as the phone's tile writes it.
    private var caption: String? {
        switch kind {
        case .cpu: return cpuCores.map { String(localized: "\($0) cores") }
        case .memory: return snapshot?.memoryTotal.map { String(localized: "of \(Format.bytes($0))") }
        case .gpu: return snapshot?.gpuTemperature.map { Format.temperature($0, unit: unit) }
        case .temperature: return snapshot?.gpuTemperature.map { String(localized: "GPU \(Format.temperature($0, unit: unit))") }
        case .network: return String(localized: "↑ \(Format.rate(snapshot?.networkUpBytesPerSec))")
        case .power:
            guard let power = snapshot?.power else { return nil }
            if power.chargePercent != nil {
                return power.isCharging ? String(localized: "Charging") : Format.duration(power.timeRemainingSeconds)
            }
            return String(localized: "The Mac draws")
        case .disk: return snapshot?.disks.first?.name
        case .fans:
            let count = snapshot?.fanSpeeds.count ?? 0
            return count == 0 ? String(localized: "No fan readings") : String(localized: "\(count) fans")
        }
    }

    @ViewBuilder
    private var accessory: some View {
        let sparkHeight: CGFloat = 22
        switch kind {
        case .cpu:
            SparkChart(values: history.cpu, tint: kind.tint, maxValue: 1).frame(height: sparkHeight)
        case .gpu:
            SparkChart(values: history.gpu, tint: kind.tint, maxValue: 1).frame(height: sparkHeight)
        case .network:
            SparkChart(values: history.networkDown, tint: kind.tint).frame(height: sparkHeight)
        case .memory:
            HStack {
                // The Mac warns on memory by its pressure, not by how full it is: the badge says it.
                LevelBar(fraction: snapshot?.memoryFraction ?? 0, tint: kind.tint, warns: false)
                if let pressure = snapshot?.memoryPressure, pressure != "normal" { PressureBadge(pressure: pressure) }
            }
        case .power:
            if let charge = snapshot?.power?.chargePercent {
                LevelBar(fraction: Double(charge) / 100, tint: kind.tint, warns: false)
            } else if !history.power.isEmpty {
                SparkChart(values: history.power, tint: kind.tint).frame(height: sparkHeight)
            }
        case .disk:
            if let disk = snapshot?.disks.first {
                LevelBar(fraction: Double(disk.usedBytes) / Double(max(disk.totalBytes, 1)), tint: kind.tint, warns: true)
            }
        case .temperature, .fans:
            EmptyView()
        }
    }
}

extension WatchMacState {
    var pillKind: StatusPill.Kind {
        if isDemo { return .demo }
        if phoneUnreachable { return .offline }
        switch status {
        case .live: return .live
        case .connecting: return .connecting
        case .idle, .offline, .refused, .forgotten: return .offline
        }
    }

    /// Why no readings come, when none do.
    var note: String? {
        if phoneUnreachable { return String(localized: "Can't reach your iPhone. Keep it nearby, with Bluetooth or Wi-Fi on.") }
        switch status {
        case let .offline(reason): return reason
        case .refused("removed"): return String(localized: "This iPhone was removed on the Mac. Pair it again in Beacon on the iPhone.")
        case let .refused(reason): return String(localized: "The Mac turned the iPhone away (\(reason)).")
        case .forgotten: return String(localized: "The iPhone no longer has this Mac.")
        case .idle, .connecting, .live: return nil
        }
    }
}

#Preview("Dashboard") {
    let model = WatchModel(demoOnly: true)
    NavigationStack { WatchDashboardView(state: model.demo) }.environment(model)
}
