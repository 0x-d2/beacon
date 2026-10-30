// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

#if VORSSAINT_DEVELOPMENT
import Foundation

/// The readings BeaconKit™'s renders draw: an M-series Mac at an ordinary
/// moment, the same numbers on every Mac and in every run, so two renders of
/// the same code differ only where the code does. The renderer hands it to
/// `SystemMonitor.freezeForKit(_:)`.
enum KitFixtures {
    static let snapshot: SystemSnapshot = {
        var snapshot = SystemSnapshot()
        snapshot.cpuTemperature = 54.2
        snapshot.gpuTemperature = 47.5
        snapshot.batteryTemperature = 31.4
        snapshot.cpuUsage = 0.23
        snapshot.cpuCoreUsage = [0.62, 0.48, 0.31, 0.12, 0.27, 0.18, 0.09, 0.05, 0.14, 0.03]
        snapshot.gpuUsage = 0.12
        snapshot.memoryTotal = 16 * gigabyte
        snapshot.memoryUsed = 11_200_000_000
        snapshot.memoryAppUsed = 8_400_000_000
        snapshot.memoryCompressed = 1_100_000_000
        snapshot.memoryCached = 3_050_000_000
        snapshot.memorySwapUsed = 420_000_000
        snapshot.memoryPressure = .normal
        snapshot.fanSpeeds = [1850]
        snapshot.netDownBytesPerSec = 1_240_000
        snapshot.netUpBytesPerSec = 182_000
        snapshot.netTotalDown = 2_840_000_000
        snapshot.netTotalUp = 412_000_000
        snapshot.cpuHistory = wave(base: 0.2, swing: 0.14, period: 17)
        snapshot.gpuHistory = wave(base: 0.1, swing: 0.08, period: 23)
        snapshot.memoryHistory = wave(base: 0.68, swing: 0.03, period: 41)
        snapshot.memoryAppHistory = wave(base: 0.52, swing: 0.03, period: 37)
        snapshot.netDownHistory = wave(base: 900_000, swing: 700_000, period: 11)
        snapshot.netUpHistory = wave(base: 150_000, swing: 90_000, period: 13)
        snapshot.diskReadHistory = wave(base: 4_000_000, swing: 3_500_000, period: 9)
        snapshot.diskWriteHistory = wave(base: 2_000_000, swing: 1_800_000, period: 14)
        snapshot.systemPowerHistory = wave(base: 9, swing: 4, period: 19)
        snapshot.batteryHistory = (0..<120).map { 0.86 - Double($0) * 0.0008 }
        return snapshot
    }()

    /// Sample processes for the breakdown rows; names any Mac has.
    static let processes: [ProcessUsage] = [
        ProcessUsage(pid: 412, name: "Safari", value: 18.4, networkDownBytesPerSec: nil, networkUpBytesPerSec: nil, startedAt: nil),
        ProcessUsage(pid: 977, name: "Xcode", value: 9.7, networkDownBytesPerSec: nil, networkUpBytesPerSec: nil, startedAt: nil),
        ProcessUsage(pid: 230, name: "WindowServer", value: 6.1, networkDownBytesPerSec: nil, networkUpBytesPerSec: nil, startedAt: nil),
    ]

    private static let gigabyte: UInt64 = 1_073_741_824

    /// 120 samples (the history's capacity) of a smooth, made-up reading.
    static func wave(base: Double, swing: Double, period: Double) -> [Double] {
        (0..<120).map { index in
            let t = Double(index)
            return max(0, base + swing * (0.6 * sin(t / period * 2 * .pi) + 0.4 * sin(t / (period * 0.37) * 2 * .pi)))
        }
    }
}
#endif
