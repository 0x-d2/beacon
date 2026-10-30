// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The demo Mac's readings, the same as the Mac app's catalog fixture
/// (Sources/Vorssaint/Kit/KitFixtures.swift): the previews, the gallery and
/// "Try with sample data" draw these, and nothing here touches the network.
enum DemoData {
    static let pairing = RemotePairing(name: "Mac mini", host: "demo.local", alternateHost: nil, port: RemoteMonitorProtocol.defaultPort,
                                       id: "demo-0000-0000-0000", key: Data(repeating: 0, count: RemoteMonitorProtocol.keyLength))

    static let info = RemoteMacInfo(protocolVersion: RemoteMonitorProtocol.version, name: "Mac mini", model: "Mac16,10",
                                    osVersion: "macOS 27.2", appVersion: "3.4.3", cpuCores: 10,
                                    memoryTotal: 17_179_869_184, interval: 2)

    static let snapshot = snapshot(tick: 0)

    /// A reading that drifts with `tick`, so the demo's charts move.
    static func snapshot(tick: Int) -> RemoteSnapshot {
        let t = Double(tick)
        let cpu = 0.2 + 0.14 * (0.6 * sin(t / 17 * 2 * .pi) + 0.4 * sin(t / 6.3 * 2 * .pi))
        return RemoteSnapshot(
            time: .now,
            cpuUsage: max(0.02, cpu),
            cpuCoreUsage: [0.62, 0.48, 0.31, 0.12, 0.27, 0.18, 0.09, 0.05, 0.14, 0.03].map { max(0, min(1, $0 + 0.08 * sin(t + $0 * 10))) },
            gpuUsage: 0.12 + 0.05 * sin(t / 9),
            cpuTemperature: 54.2 + 2 * sin(t / 11),
            gpuTemperature: 47.5,
            batteryTemperature: nil,
            memoryUsed: 11_200_000_000,
            memoryAppUsed: 8_400_000_000,
            memoryTotal: 17_179_869_184,
            memoryCompressed: 1_100_000_000,
            memoryCached: 3_050_000_000,
            memorySwapUsed: 420_000_000,
            memoryPressure: "normal",
            fanSpeeds: [1850 + 40 * sin(t / 7)],
            networkDownBytesPerSec: max(0, 900_000 + 700_000 * sin(t / 5)),
            networkUpBytesPerSec: max(0, 150_000 + 90_000 * sin(t / 4)),
            networkTotalDown: 2_840_000_000,
            networkTotalUp: 412_000_000,
            power: RemotePower(systemWatts: 9 + 3 * sin(t / 8), adapterWatts: 18, batteryWatts: nil, chargePercent: nil,
                               timeRemainingSeconds: nil, healthPercent: nil, cycleCount: nil, isCharging: false,
                               externalConnected: true, hasBattery: false),
            disks: [
                RemoteDisk(name: "Macintosh HD", totalBytes: 994_662_584_320, usedBytes: 512_300_000_000,
                           readBytesPerSec: 4_000_000, writeBytesPerSec: 1_200_000, isInternal: true),
                RemoteDisk(name: "Archive", totalBytes: 2_000_398_934_016, usedBytes: 1_480_000_000_000,
                           readBytesPerSec: 0, writeBytesPerSec: 0, isInternal: false),
            ]
        )
    }

    static let history = RemoteHistory(
        interval: 2,
        cpu: wave(base: 0.2, swing: 0.14, period: 17),
        gpu: wave(base: 0.1, swing: 0.08, period: 23),
        memory: wave(base: 0.65, swing: 0.03, period: 41),
        networkDown: wave(base: 900_000, swing: 700_000, period: 11),
        networkUp: wave(base: 150_000, swing: 90_000, period: 13),
        power: wave(base: 9, swing: 4, period: 19)
    )

    private static func wave(base: Double, swing: Double, period: Double) -> [Double] {
        (0..<120).map { index in
            let t = Double(index)
            return max(0, base + swing * (0.6 * sin(t / period * 2 * .pi) + 0.4 * sin(t / (period * 0.37) * 2 * .pi)))
        }
    }
}
