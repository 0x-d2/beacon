// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The last reading the watch had of a Mac, for the complication
/// (BeaconWatchWidgets). The watch reads a Mac only while its app shows one,
/// through the phone, so the complication draws what it read last and says
/// when. The app writes it as readings come; the widget, a process of its
/// own, reads it from the app group they share.
struct LastReading: Codable, Equatable, Sendable {
    var macID: String
    var macName: String
    var time: Date
    var cpu: Double?
    /// The used share of the memory.
    var memory: Double?
    var gpu: Double?
    var cpuTemperature: Double?
    var temperatureUnit: TemperatureUnit

    /// How long a reading counts as current; older, the complication dims it.
    static let freshFor: TimeInterval = 10 * 60
    static let widgetKind = "co.ikili.beacon.reading"

    /// Where tapping the complication goes: that Mac's readings, in the app.
    var link: URL {
        var components = URLComponents()
        components.scheme = "beacon-watch"
        components.host = "mac"
        components.queryItems = [URLQueryItem(name: "id", value: macID)]
        return components.url!
    }

    static func macID(in link: URL) -> String? {
        guard let components = URLComponents(url: link, resolvingAgainstBaseURL: false),
              components.scheme == "beacon-watch", components.host == "mac" else { return nil }
        return components.queryItems?.first { $0.name == "id" }?.value
    }
}

extension TemperatureUnit: Codable {}

enum LastReadingStore {
    static let appGroup = "group.co.ikili.beacon"
    private static let key = "lastReading"

    static func read() -> LastReading? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LastReading.self, from: data)
    }

    static func write(_ reading: LastReading) {
        guard let data = try? JSONEncoder().encode(reading) else { return }
        UserDefaults(suiteName: appGroup)?.set(data, forKey: key)
    }
}
