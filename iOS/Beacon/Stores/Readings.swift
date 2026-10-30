// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

// What the screens read off a Mac's readings, on the phone and on the watch:
// the readings there are, the recent history their charts draw, and what a
// snapshot works out. Compiled into Beacon and Beacon for Apple Watch, so it
// needs SwiftUI and the protocol only.

/// The readings the dashboard shows, in order, and what each tile and detail page are about.
enum MetricKind: String, CaseIterable, Identifiable, Hashable {
    case cpu, memory, gpu, temperature, network, power, disk, fans

    var id: String { rawValue }
    static let dashboard: [MetricKind] = allCases

    var title: LocalizedStringKey {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .gpu: return "GPU"
        case .temperature: return "Temperatures"
        case .network: return "Network"
        case .power: return "Power"
        case .disk: return "Disks"
        case .fans: return "Fans"
        }
    }

    var symbol: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .gpu: return "square.stack.3d.up"
        case .temperature: return "thermometer.medium"
        case .network: return "network"
        case .power: return "bolt.fill"
        case .disk: return "internaldrive"
        case .fans: return "fanblades"
        }
    }

    var tint: Color {
        switch self {
        case .cpu: return BeaconColor.cpu
        case .memory: return BeaconColor.memory
        case .gpu: return BeaconColor.gpu
        case .temperature: return BeaconColor.temperature
        case .network: return BeaconColor.download
        case .power: return BeaconColor.power
        case .disk: return BeaconColor.disk
        case .fans: return BeaconColor.fan
        }
    }
}

/// The recent readings for the charts: the Mac's history when the phone
/// subscribes, then each snapshot as it comes, 120 at most (four minutes at
/// the Mac's usual two seconds).
struct LiveHistory: Equatable {
    static let capacity = 120
    var cpu: [Double] = []
    var gpu: [Double] = []
    var memory: [Double] = []
    var networkDown: [Double] = []
    var networkUp: [Double] = []
    var power: [Double] = []

    init() {}

    init(_ history: RemoteHistory) {
        cpu = Array(history.cpu.suffix(Self.capacity))
        gpu = Array(history.gpu.suffix(Self.capacity))
        memory = Array(history.memory.suffix(Self.capacity))
        networkDown = Array(history.networkDown.suffix(Self.capacity))
        networkUp = Array(history.networkUp.suffix(Self.capacity))
        power = Array(history.power.suffix(Self.capacity))
    }

    mutating func append(_ snapshot: RemoteSnapshot) {
        func push(_ value: Double?, _ list: inout [Double]) {
            guard let value else { return }
            list.append(value)
            if list.count > Self.capacity { list.removeFirst(list.count - Self.capacity) }
        }
        push(snapshot.cpuUsage, &cpu)
        push(snapshot.gpuUsage, &gpu)
        if let used = snapshot.memoryUsed, let total = snapshot.memoryTotal, total > 0 { push(Double(used) / Double(total), &memory) }
        push(snapshot.networkDownBytesPerSec, &networkDown)
        push(snapshot.networkUpBytesPerSec, &networkUp)
        push(snapshot.power?.systemWatts, &power)
    }

    /// The same readings as the Mac sends them, for the watch: its charts start full too.
    func remote(interval: Double) -> RemoteHistory {
        RemoteHistory(interval: interval, cpu: cpu, gpu: gpu, memory: memory, networkDown: networkDown, networkUp: networkUp, power: power)
    }
}

extension RemoteSnapshot {
    var memoryFraction: Double? {
        guard let used = memoryUsed, let total = memoryTotal, total > 0 else { return nil }
        return Double(used) / Double(total)
    }

    /// The one number a reading is about, as its detail page's headline writes it.
    func headline(_ kind: MetricKind, unit: TemperatureUnit) -> String {
        switch kind {
        case .cpu: return Format.percent(cpuUsage)
        case .gpu: return Format.percent(gpuUsage)
        case .memory: return Format.bytes(memoryUsed)
        case .temperature: return Format.temperature(cpuTemperature, unit: unit)
        case .network: return Format.rate(networkDownBytesPerSec)
        case .power:
            if let charge = power?.chargePercent { return Format.percent(Double(charge) / 100) }
            return Format.watts(power?.systemWatts)
        case .disk:
            return disks.first.map { Format.percent(Double($0.usedBytes) / Double(max($0.totalBytes, 1))) } ?? "–"
        case .fans: return fanSpeeds.first.map(Format.rpm) ?? "–"
        }
    }
}
