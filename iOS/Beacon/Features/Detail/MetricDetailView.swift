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
            rows(snapshot)
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { session.watch() }
        .onDisappear { session.unwatch() }
    }

    private func headline(_ snapshot: RemoteSnapshot?) -> String {
        switch kind {
        case .cpu: return Format.percent(snapshot?.cpuUsage)
        case .gpu: return Format.percent(snapshot?.gpuUsage)
        case .memory: return Format.bytes(snapshot?.memoryUsed)
        case .temperature: return Format.temperature(snapshot?.cpuTemperature, unit: model.temperatureUnit)
        case .network: return Format.rate(snapshot?.networkDownBytesPerSec)
        case .power:
            if let charge = snapshot?.power?.chargePercent { return Format.percent(Double(charge) / 100) }
            return Format.watts(snapshot?.power?.systemWatts)
        case .disk:
            let disk = snapshot?.disks.first
            return disk.map { Format.percent(Double($0.usedBytes) / Double(max($0.totalBytes, 1))) } ?? "–"
        case .fans: return snapshot?.fanSpeeds.first.map(Format.rpm) ?? "–"
        }
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

    @ViewBuilder
    private func rows(_ snapshot: RemoteSnapshot?) -> some View {
        let unit = model.temperatureUnit
        switch kind {
        case .cpu:
            if let cores = snapshot?.cpuCoreUsage, !cores.isEmpty {
                Section("Cores") { CoreGrid(usage: cores).padding(.vertical, BeaconMetrics.spacing3) }
            }
            Section {
                StatRow(title: "Temperature", value: Format.temperature(snapshot?.cpuTemperature, unit: unit), tint: BeaconColor.temperature)
                if let cores = session.info?.cpuCores { StatRow(title: "Cores", value: "\(cores)") }
            }
        case .memory:
            Section {
                if let pressure = snapshot?.memoryPressure {
                    HStack { Text("Pressure").foregroundStyle(.secondary); Spacer(); PressureBadge(pressure: pressure) }
                }
                StatRow(title: "Used", value: Format.bytes(snapshot?.memoryUsed))
                StatRow(title: "App memory", value: Format.bytes(snapshot?.memoryAppUsed))
                StatRow(title: "Compressed", value: Format.bytes(snapshot?.memoryCompressed))
                StatRow(title: "Cached files", value: Format.bytes(snapshot?.memoryCached))
                StatRow(title: "Swap used", value: Format.bytes(snapshot?.memorySwapUsed))
                StatRow(title: "Total", value: Format.bytes(snapshot?.memoryTotal))
            }
        case .gpu:
            Section { StatRow(title: "Temperature", value: Format.temperature(snapshot?.gpuTemperature, unit: unit), tint: BeaconColor.temperature) }
        case .temperature:
            Section {
                StatRow(title: "CPU", value: Format.temperature(snapshot?.cpuTemperature, unit: unit))
                StatRow(title: "GPU", value: Format.temperature(snapshot?.gpuTemperature, unit: unit))
                if snapshot?.batteryTemperature != nil {
                    StatRow(title: "Battery", value: Format.temperature(snapshot?.batteryTemperature, unit: unit))
                }
            }
        case .network:
            Section {
                StatRow(title: "Download", value: Format.rate(snapshot?.networkDownBytesPerSec), tint: BeaconColor.download)
                StatRow(title: "Upload", value: Format.rate(snapshot?.networkUpBytesPerSec), tint: BeaconColor.upload)
            }
            Section("Since the Mac started watching") {
                StatRow(title: "Downloaded", value: Format.bytes(snapshot?.networkTotalDown))
                StatRow(title: "Uploaded", value: Format.bytes(snapshot?.networkTotalUp))
            }
            if !session.history.networkUp.isEmpty {
                Section("Upload") {
                    HistoryChart(values: session.history.networkUp, tint: BeaconColor.upload, maxValue: nil, format: { Format.rate($0) },
                                 interval: session.info?.interval ?? 2)
                        .frame(height: 120)
                }
            }
        case .power:
            let power = snapshot?.power
            Section {
                StatRow(title: "The Mac draws", value: Format.watts(power?.systemWatts))
                if power?.adapterWatts != nil { StatRow(title: "Adapter", value: Format.watts(power?.adapterWatts)) }
                if power?.hasBattery == true {
                    StatRow(title: "Battery", value: power?.chargePercent.map { Format.percent(Double($0) / 100) } ?? "–", tint: BeaconColor.power)
                    StatRow(title: power?.isCharging == true ? "Charging at" : "Battery draw", value: Format.watts(power?.batteryWatts))
                    StatRow(title: "Time remaining", value: Format.duration(power?.timeRemainingSeconds))
                    StatRow(title: "Health", value: power?.healthPercent.map { Format.percent($0 / 100) } ?? "–")
                    StatRow(title: "Cycles", value: power?.cycleCount.map { "\($0)" } ?? "–")
                }
            }
        case .disk:
            Section {
                ForEach(snapshot?.disks ?? [], id: \.name) { disk in
                    VStack(alignment: .leading, spacing: BeaconMetrics.spacing3) {
                        HStack {
                            Label(disk.name, systemImage: disk.isInternal ? "internaldrive" : "externaldrive")
                            Spacer()
                            Text("\(Format.diskBytes(disk.usedBytes)) / \(Format.diskBytes(disk.totalBytes))")
                                .font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        LevelBar(fraction: Double(disk.usedBytes) / Double(max(disk.totalBytes, 1)), tint: BeaconColor.disk)
                        HStack {
                            Text("Read \(Format.rate(disk.readBytesPerSec))")
                            Spacer()
                            Text("Write \(Format.rate(disk.writeBytesPerSec))")
                        }
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        case .fans:
            Section {
                ForEach(Array((snapshot?.fanSpeeds ?? []).enumerated()), id: \.offset) { index, speed in
                    StatRow(title: "Fan \(index + 1)", value: Format.rpm(speed))
                }
            }
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
