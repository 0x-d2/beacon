// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The rows behind a reading on its detail page: each core, the memory's
/// parts, the network's totals, the power and the battery, each disk, each
/// fan. The phone's detail page and the watch's draw these same rows, so the
/// watch shows every reading the phone does.
struct MetricRows: View {
    let kind: MetricKind
    let snapshot: RemoteSnapshot?
    let cpuCores: Int?
    let unit: TemperatureUnit

    var body: some View {
        switch kind {
        case .cpu:
            if let cores = snapshot?.cpuCoreUsage, !cores.isEmpty {
                Section("Cores") { CoreGrid(usage: cores).padding(.vertical, BeaconMetrics.spacing3) }
            }
            Section {
                StatRow(title: "Temperature", value: Format.temperature(snapshot?.cpuTemperature, unit: unit), tint: BeaconColor.temperature)
                if let cpuCores { StatRow(title: "Cores", value: "\(cpuCores)") }
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
                    let name = Label(disk.name, systemImage: disk.isInternal ? "internaldrive" : "externaldrive").lineLimit(1)
                    let size = Text("\(Format.diskBytes(disk.usedBytes)) / \(Format.diskBytes(disk.totalBytes))")
                        .font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                    let read = Text("Read \(Format.rate(disk.readBytesPerSec))")
                    let write = Text("Write \(Format.rate(disk.writeBytesPerSec))")
                    VStack(alignment: .leading, spacing: BeaconMetrics.spacing3) {
                        // Side by side where they fit (the phone), one under the other where they don't (the watch).
                        ViewThatFits(in: .horizontal) {
                            HStack { name; Spacer(); size }
                            VStack(alignment: .leading, spacing: 2) { name; size }
                        }
                        LevelBar(fraction: Double(disk.usedBytes) / Double(max(disk.totalBytes, 1)), tint: BeaconColor.disk)
                        ViewThatFits(in: .horizontal) {
                            HStack { read; Spacer(); write }
                            VStack(alignment: .leading, spacing: 2) { read; write }
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
