// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Charts
import SwiftUI

/// One reading in full: the headline number, its last four minutes as a
/// chart, and the rows behind it (each core, the memory's parts, each disk,
/// the battery).
struct MetricDetailView: View {
    @Environment(AppModel.self) private var model
    let session: MacSession
    let kind: MetricKind

    var body: some View {
        let snapshot = session.snapshot
        List {
            Section {
                VStack(alignment: .leading, spacing: BeaconMetrics.spacing4) {
                    Text(headline(snapshot))
                        .font(BeaconType.hero)
                        .foregroundStyle(kind.tint)
                        .contentTransition(.numericText())
                        .animation(BeaconMotion.reading, value: headline(snapshot))
                    if let series = series {
                        HistoryChart(values: series.values, tint: kind.tint, maxValue: series.maxValue, format: series.format,
                                     interval: session.info?.interval ?? 2)
                            .frame(height: 180)
                    }
                }
                .padding(.vertical, BeaconMetrics.spacing3)
            }
            MetricRows(kind: kind, snapshot: snapshot, cpuCores: session.info?.cpuCores, unit: model.temperatureUnit)
            if kind == .network, !session.history.networkUp.isEmpty {
                Section("Upload") {
                    HistoryChart(values: session.history.networkUp, tint: BeaconColor.upload, maxValue: nil, format: { Format.rate($0) },
                                 interval: session.info?.interval ?? 2)
                        .frame(height: 120)
                }
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { session.watch() }
        .onDisappear { session.unwatch() }
    }

    private func headline(_ snapshot: RemoteSnapshot?) -> String {
        snapshot?.headline(kind, unit: model.temperatureUnit) ?? "–"
    }

    private var series: (values: [Double], maxValue: Double?, format: (Double) -> String)? {
        let history = session.history
        switch kind {
        case .cpu: return (history.cpu, 1, { Format.percent($0) })
        case .gpu: return (history.gpu, 1, { Format.percent($0) })
        case .memory: return (history.memory, 1, { Format.percent($0) })
        case .network: return (history.networkDown, nil, { Format.rate($0) })
        case .power: return history.power.isEmpty ? nil : (history.power, nil, { Format.watts($0) })
        case .temperature, .disk, .fans: return nil
        }
    }
}

/// A reading's history as a chart: an area under a line, the time axis in
/// minutes ago, the values in the reading's own unit, and a finger that
/// scrubs shows the value under it.
struct HistoryChart: View {
    var values: [Double]
    var tint: Color
    var maxValue: Double?
    var format: (Double) -> String
    var interval: Double
    @State private var selected: Int?

    var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                AreaMark(x: .value("Time", index), y: .value("Value", value))
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(0.3), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", index), y: .value("Value", value))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .interpolationMethod(.monotone)
            }
            if let selected, values.indices.contains(selected) {
                RuleMark(x: .value("Time", selected))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                        Text(format(values[selected])).font(.caption.monospacedDigit().weight(.semibold))
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(.regularMaterial, in: Capsule())
                    }
            }
        }
        .chartYScale(domain: 0...max(maxValue ?? (values.max() ?? 1) * 1.1, 0.0001))
        .chartXScale(domain: 0...max(1, values.count - 1))
        .chartXAxis {
            AxisMarks(values: .stride(by: max(1, 60 / interval))) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let index = value.as(Int.self) {
                        let minutes = Int((Double(values.count - 1 - index) * interval / 60).rounded())
                        Text(minutes == 0 ? String(localized: "now") : String(localized: "−\(minutes) min"))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel { if let v = value.as(Double.self) { Text(format(v)) } }
            }
        }
        .chartXSelection(value: $selected)
    }
}

#Preview("CPU") {
    let model = AppModel(demoOnly: true)
    NavigationStack { MetricDetailView(session: model.demo, kind: .cpu) }.environment(model)
}

#Preview("Memory") {
    let model = AppModel(demoOnly: true)
    NavigationStack { MetricDetailView(session: model.demo, kind: .memory) }.environment(model)
}
