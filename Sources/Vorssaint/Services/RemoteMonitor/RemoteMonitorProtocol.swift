// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

// What the Mac and the Beacon iPhone app say to each other (docs/remote-monitor.md).
// This one file is compiled into both: the Mac app's build.sh takes it with
// every other source, and iOS/project.yml names it among Beacon's. So it
// imports Foundation only, holds plain Sendable values, and has to compile
// as Swift 5 on the Mac (back to Swift 6.0.3) and as Swift 6 on iOS.
//
// The phone opens a WebSocket over TLS 1.2 with a pre-shared key it got from
// the Mac's pairing QR code, one key per phone. Each message is one JSON text
// frame, `{"type": "...", "payload": {...}}`. The phone says hello and asks
// for readings while its screen shows them; the Mac answers with who it is
// and the recent history once, then a snapshot on every reading.

enum RemoteMonitorProtocol {
    /// Bumped when a message changes shape so that an older peer can't read it.
    static let version = 1
    static let serviceType = "_beacon-mac._tcp"
    static let defaultPort: UInt16 = 47823
    static let path = "/beacon/v1"
    /// A peer silent for longer than this is gone; each side pings at a third of it.
    static let silenceTimeout: TimeInterval = 15
    static let keyLength = 32
}

struct RemoteHello: Codable, Sendable, Equatable {
    var protocolVersion: Int
    /// The pairing's id from the QR code: which of the paired phones this is,
    /// so the Mac can name it, and drop it when it's removed.
    var id: String
    /// The phone's name, shown in the Mac's list of paired phones.
    var device: String
    var app: String
}

struct RemoteMacInfo: Codable, Sendable, Equatable {
    var protocolVersion: Int
    var name: String
    var model: String
    var osVersion: String
    var appVersion: String
    var cpuCores: Int
    var memoryTotal: UInt64?
    /// Seconds between readings while a phone watches.
    var interval: Double
}

/// The phone wants readings (its dashboard is on screen) or no longer does.
/// Nothing is sampled for it while no phone is subscribed.
struct RemoteSubscription: Codable, Sendable, Equatable {
    var active: Bool
}

struct RemotePower: Codable, Sendable, Equatable {
    var systemWatts: Double?
    var adapterWatts: Double?
    var batteryWatts: Double?
    var chargePercent: Int?
    var timeRemainingSeconds: Double?
    var healthPercent: Double?
    var cycleCount: Int?
    var isCharging: Bool
    var externalConnected: Bool
    var hasBattery: Bool
}

struct RemoteDisk: Codable, Sendable, Equatable {
    var name: String
    var totalBytes: UInt64
    var usedBytes: UInt64
    var readBytesPerSec: Double?
    var writeBytesPerSec: Double?
    var isInternal: Bool
}

/// One reading. Every value is optional: a Mac without a battery, a feature
/// the owner uninstalled, a sensor that didn't answer.
struct RemoteSnapshot: Codable, Sendable, Equatable {
    var time: Date
    var cpuUsage: Double?
    var cpuCoreUsage: [Double?]
    var gpuUsage: Double?
    var cpuTemperature: Double?
    var gpuTemperature: Double?
    var batteryTemperature: Double?
    var memoryUsed: UInt64?
    var memoryAppUsed: UInt64?
    var memoryTotal: UInt64?
    var memoryCompressed: UInt64?
    var memoryCached: UInt64?
    var memorySwapUsed: UInt64?
    /// `normal`, `warning`, `critical` or `unknown`.
    var memoryPressure: String
    var fanSpeeds: [Double]
    var networkDownBytesPerSec: Double?
    var networkUpBytesPerSec: Double?
    var networkTotalDown: UInt64?
    var networkTotalUp: UInt64?
    var power: RemotePower?
    var disks: [RemoteDisk]
}

/// The recent readings, oldest first, sent once when a phone subscribes so its
/// charts start full.
struct RemoteHistory: Codable, Sendable, Equatable {
    var interval: Double
    var cpu: [Double]
    var gpu: [Double]
    var memory: [Double]
    var networkDown: [Double]
    var networkUp: [Double]
    var power: [Double]
}

enum RemoteMessage: Sendable, Equatable {
    case hello(RemoteHello)
    case info(RemoteMacInfo)
    case subscribe(RemoteSubscription)
    case snapshot(RemoteSnapshot)
    case history(RemoteHistory)
    case ping
    case pong
    /// The Mac turns the phone away (an older protocol, a revoked pairing), saying why.
    case refused(String)
    /// A message this side doesn't know, from a newer peer: ignored, not an error.
    case unknown(String)
}

extension RemoteMessage: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "hello": self = .hello(try container.decode(RemoteHello.self, forKey: .payload))
        case "info": self = .info(try container.decode(RemoteMacInfo.self, forKey: .payload))
        case "subscribe": self = .subscribe(try container.decode(RemoteSubscription.self, forKey: .payload))
        case "snapshot": self = .snapshot(try container.decode(RemoteSnapshot.self, forKey: .payload))
        case "history": self = .history(try container.decode(RemoteHistory.self, forKey: .payload))
        case "ping": self = .ping
        case "pong": self = .pong
        case "refused": self = .refused(try container.decode(String.self, forKey: .payload))
        default: self = .unknown(type)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .hello(value): try container.encode("hello", forKey: .type); try container.encode(value, forKey: .payload)
        case let .info(value): try container.encode("info", forKey: .type); try container.encode(value, forKey: .payload)
        case let .subscribe(value): try container.encode("subscribe", forKey: .type); try container.encode(value, forKey: .payload)
        case let .snapshot(value): try container.encode("snapshot", forKey: .type); try container.encode(value, forKey: .payload)
        case let .history(value): try container.encode("history", forKey: .type); try container.encode(value, forKey: .payload)
        case .ping: try container.encode("ping", forKey: .type)
        case .pong: try container.encode("pong", forKey: .type)
        case let .refused(reason): try container.encode("refused", forKey: .type); try container.encode(reason, forKey: .payload)
        case let .unknown(type): try container.encode(type, forKey: .type)
        }
    }

    /// One WebSocket text frame's bytes.
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(self)
    }

    static func decoded(from data: Data) throws -> RemoteMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(RemoteMessage.self, from: data)
    }
}

/// What the Mac's QR code carries for one phone:
/// `beacon://pair?v=1&name=…&host=…&alt=…&port=…&id=…&key=…`. `host` is the
/// Mac's name on the local network (`alis-mac.local`); `alt` is optional, an
/// address that reaches it from elsewhere (its Tailscale name). `key` is the
/// phone's own 32-byte pre-shared key in unpadded base64url; `id` names it.
/// Anything that doesn't read as exactly this is refused: a QR code is
/// untrusted input.
struct RemotePairing: Sendable, Equatable {
    var name: String
    var host: String
    var alternateHost: String?
    var port: UInt16
    var id: String
    var key: Data

    static let scheme = "beacon"

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = "pair"
        components.queryItems = [
            URLQueryItem(name: "v", value: String(RemoteMonitorProtocol.version)),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "host", value: host),
        ] + (alternateHost.map { [URLQueryItem(name: "alt", value: $0)] } ?? []) + [
            URLQueryItem(name: "port", value: String(port)),
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "key", value: Self.base64URL(key)),
        ]
        return components.url!
    }

    init(name: String, host: String, alternateHost: String?, port: UInt16, id: String, key: Data) {
        self.name = name
        self.host = host
        self.alternateHost = alternateHost
        self.port = port
        self.id = id
        self.key = key
    }

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == Self.scheme, components.host == "pair" else { return nil }
        var values: [String: String] = [:]
        for item in components.queryItems ?? [] {
            // A repeated field is ambiguous: refuse rather than pick one.
            guard values[item.name] == nil, let value = item.value else { return nil }
            values[item.name] = value
        }
        guard values["v"] == String(RemoteMonitorProtocol.version),
              let name = values["name"], !name.isEmpty, name.count <= 128,
              let host = values["host"], Self.isHostName(host),
              let portText = values["port"], let port = UInt16(portText), port > 0,
              let id = values["id"], Self.isIdentifier(id),
              let keyText = values["key"], let key = Self.data(base64URL: keyText), key.count == RemoteMonitorProtocol.keyLength
        else { return nil }
        let alternate = values["alt"]
        if let alternate, !Self.isHostName(alternate) { return nil }
        self.init(name: name, host: host, alternateHost: alternate, port: port, id: id, key: key)
    }

    /// A DNS name or an IP address, nothing a URL could be bent with.
    static func isHostName(_ text: String) -> Bool {
        guard !text.isEmpty, text.count <= 253 else { return false }
        return text.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar) && scalar.isASCII || scalar == "." || scalar == "-" || scalar == ":"
        }
    }

    static func isIdentifier(_ text: String) -> Bool {
        (8...64).contains(text.count) && text.unicodeScalars.allSatisfy { scalar in
            scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || scalar == "-")
        }
    }

    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func data(base64URL text: String) -> Data? {
        guard text.unicodeScalars.allSatisfy({ $0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_") }) else { return nil }
        var base64 = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        return Data(base64Encoded: base64)
    }
}
