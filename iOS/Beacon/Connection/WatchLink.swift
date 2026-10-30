// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

// What Beacon on the iPhone and Beacon on the Apple Watch say to each other
// over WatchConnectivity (iOS/README.md › Apple Watch). The watch can't reach
// a Mac itself: watchOS keeps the Network framework, the only way to the
// Mac's pre-shared key, to audio and call apps (Apple's TN3135). So the phone
// reads the Mac for it and passes the readings on as the Mac sent them. The
// keys stay on the phone: the watch knows each Mac by its id and name only.
//
// While a watch screen shows a Mac it says so, and again every few seconds
// (`heartbeat`); the phone answers with what it has (the Mac's info, status
// and recent history), then every change. Each message is one
// `sendMessageData` payload. Both apps ship in one bundle, so they always
// speak the same version of this file.

enum WatchLink {
    /// How often the watch says it still shows a Mac.
    static let heartbeat: TimeInterval = 5
    /// A watch silent for longer than this has stopped watching.
    static let silenceTimeout: TimeInterval = 15
}

/// A paired Mac as the watch knows it: no address, no key.
struct WatchMac: Codable, Sendable, Hashable, Identifiable {
    var id: String
    var name: String
}

/// What the phone keeps on the watch between launches (the application context): the Macs and the unit.
struct WatchContext: Codable, Sendable, Equatable {
    var macs: [WatchMac]
    var temperatureUnit: String

    private static let key = "context"

    func dictionary() throws -> [String: Any] {
        [Self.key: try JSONEncoder().encode(self)]
    }

    init(macs: [WatchMac], temperatureUnit: String) {
        self.macs = macs
        self.temperatureUnit = temperatureUnit
    }

    init?(dictionary: [String: Any]) {
        guard let data = dictionary[Self.key] as? Data, let context = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = context
    }
}

/// Where the phone's connection to a Mac stands, as the watch shows it.
enum WatchStatus: Codable, Sendable, Equatable {
    case idle
    case connecting
    /// Readings flow; `away` when through the address away from home.
    case live(away: Bool)
    case offline(String)
    /// The Mac turned the phone away (`removed`: the phone was removed on the Mac).
    case refused(String)
    /// The phone no longer has this Mac: the watch's list was behind.
    case forgotten
}

enum WatchMessage: Codable, Sendable, Equatable {
    /// Watch → phone: a screen shows this Mac, or no longer does. Repeated as the heartbeat.
    case watch(macID: String, active: Bool)
    // Phone → watch.
    case status(macID: String, status: WatchStatus)
    case info(macID: String, info: RemoteMacInfo)
    /// Replaces the watch's history for that Mac (a new connection, or the watch just started watching).
    case history(macID: String, history: RemoteHistory)
    /// The next reading: the watch shows it and adds it to its history.
    case snapshot(macID: String, snapshot: RemoteSnapshot)

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(self)
    }

    static func decoded(from data: Data) throws -> WatchMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(WatchMessage.self, from: data)
    }
}
