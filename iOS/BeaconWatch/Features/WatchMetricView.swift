// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// One reading in full on the wrist: the number, its last four minutes, and
/// every row the phone's page shows (MetricRows: each core, the memory's
/// parts, each disk, the battery, each fan).
struct WatchMetricView: View {
    @Environment(WatchModel.self) private var model
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    let state: WatchMacState
    let kind: MetricKind

    var body: some View {
        let snapshot = state.snapshot
        let headline = snapshot?.headline(kind, unit: model.temperatureUnit) ?? "–"
        List {
            VStack(alignment: .leading, spacing: BeaconMetrics.spacing3) {
                Text(headline)
                    .font(BeaconType.hero)
                    .foregroundStyle(kind.tint)
                    .contentTransition(.numericText())
                    .animation(BeaconMotion.reading, value: headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let series {
                    SparkChart(values: series.values, tint: kind.tint, maxValue: series.maxValue).frame(height: 56)
                }
            }
            .listRowBackground(Color.clear)
            MetricRows(kind: kind, snapshot: snapshot, cpuCores: state.info?.cpuCores, unit: model.temperatureUnit)
            if kind == .network, !state.history.networkUp.isEmpty {
                Section("Upload") {
                    SparkChart(values: state.history.networkUp, tint: BeaconColor.upload).frame(height: 40)
                }
            }
        }
        .navigationTitle(kind.title)
        .transaction { if isLuminanceReduced { $0.animation = nil } }
        .onAppear { state.watch() }
        .onDisappear { state.unwatch() }
    }

    /// The history the chart draws, and its fixed top for a share (nil follows the highest reading).
    private var series: (values: [Double], maxValue: Double?)? {
        let history = state.history
        switch kind {
        case .cpu: return (history.cpu, 1)
        case .gpu: return (history.gpu, 1)
        case .memory: return (history.memory, 1)
        case .network: return (history.networkDown, nil)
        case .power: return history.power.isEmpty ? nil : (history.power, nil)
        case .temperature, .disk, .fans: return nil
        }
    }
}

#Preview("CPU") {
    let model = WatchModel(demoOnly: true)
    NavigationStack { WatchMetricView(state: model.demo, kind: .cpu) }.environment(model)
}
