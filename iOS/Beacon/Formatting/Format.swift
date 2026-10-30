// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// How Beacon writes a reading, in the phone's region: "23%" or "%23",
/// "1,2 MB/sn" or "1.2 MB/s". Every reading goes through here.
enum Format {
    static func percent(_ fraction: Double?) -> String {
        guard let fraction else { return "–" }
        return (fraction).formatted(.percent.precision(.fractionLength(0)))
    }

    static func bytes(_ count: UInt64?) -> String {
        guard let count else { return "–" }
        return ByteCountFormatter.string(fromByteCount: Int64(clamping: count), countStyle: .memory)
    }

    static func diskBytes(_ count: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: count), countStyle: .file)
    }

    /// Bytes a second, as the Mac's network row writes them.
    static func rate(_ bytesPerSecond: Double?) -> String {
        guard let bytesPerSecond else { return "–" }
        return "\(ByteCountFormatter.string(fromByteCount: Int64(max(0, bytesPerSecond)), countStyle: .file))/s"
    }

    static func temperature(_ celsius: Double?, unit: TemperatureUnit) -> String {
        guard let celsius else { return "–" }
        let value = unit == .fahrenheit ? celsius * 9 / 5 + 32 : celsius
        return "\(value.formatted(.number.precision(.fractionLength(0)))) \(unit.symbol)"
    }

    static func watts(_ watts: Double?) -> String {
        guard let watts else { return "–" }
        return "\(abs(watts).formatted(.number.precision(.fractionLength(watts.magnitude < 10 ? 1 : 0)))) W"
    }

    static func rpm(_ speed: Double) -> String {
        "\(speed.formatted(.number.precision(.fractionLength(0)))) rpm"
    }

    /// "1 h 20 min" / "1 sa 20 dk".
    static func duration(_ seconds: Double?) -> String {
        guard let seconds, seconds > 0 else { return "–" }
        return Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius, fahrenheit

    var id: String { rawValue }
    var symbol: String { self == .celsius ? "°C" : "°F" }
}
