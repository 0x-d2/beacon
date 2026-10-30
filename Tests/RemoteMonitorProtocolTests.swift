// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The protocol the Mac and the Beacon iPhone app share
/// (Services/RemoteMonitor/RemoteMonitorProtocol.swift): messages survive the
/// round trip as the other side reads them, a newer peer's message is ignored
/// rather than fatal, and a pairing link is read only when it is exactly what
/// the Mac writes, since a QR code is untrusted input.
enum RemoteMonitorProtocolTests {
    static func run(_ suite: TestSuite) {
        messages(suite)
        pairing(suite)
    }

    private static func messages(_ suite: TestSuite) {
        let snapshot = RemoteSnapshot(
            time: Date(timeIntervalSince1970: 1_800_000_000), cpuUsage: 0.23, cpuCoreUsage: [0.5, nil, 0.1], gpuUsage: nil,
            cpuTemperature: 54.2, gpuTemperature: nil, batteryTemperature: 31, memoryUsed: 11_200_000_000, memoryAppUsed: nil,
            memoryTotal: 17_179_869_184, memoryCompressed: nil, memoryCached: nil, memorySwapUsed: 0, memoryPressure: "normal",
            fanSpeeds: [1850], networkDownBytesPerSec: 1_240_000, networkUpBytesPerSec: 182_000, networkTotalDown: nil,
            networkTotalUp: nil,
            power: RemotePower(systemWatts: 9.4, adapterWatts: nil, batteryWatts: -9.4, chargePercent: 86, timeRemainingSeconds: 21_600,
                               healthPercent: 97, cycleCount: 112, isCharging: false, externalConnected: false, hasBattery: true),
            disks: [RemoteDisk(name: "Macintosh HD", totalBytes: 994_662_584_320, usedBytes: 512_000_000_000,
                               readBytesPerSec: 4_000_000, writeBytesPerSec: nil, isInternal: true)]
        )
        let all: [RemoteMessage] = [
            .hello(RemoteHello(protocolVersion: 1, id: "3f1c2a9e-0000-4000-8000-000000000001", device: "Ali's iPhone", app: "Beacon 1.0")),
            .info(RemoteMacInfo(protocolVersion: 1, name: "Mac mini", model: "Mac16,10", osVersion: "27.2", appVersion: "3.4.3",
                                cpuCores: 10, memoryTotal: nil, interval: 2)),
            .subscribe(RemoteSubscription(active: true)),
            .snapshot(snapshot),
            .history(RemoteHistory(interval: 2, cpu: [0.1, 0.2], gpu: [], memory: [0.6], networkDown: [1, 2], networkUp: [3], power: [])),
            .ping, .pong, .refused("removed"),
        ]
        for message in all {
            let decoded = (try? message.encoded()).flatMap { try? RemoteMessage.decoded(from: $0) }
            suite.expect(decoded == message, "\(message) survives the round trip")
        }
        let future = Data(#"{"type":"processes","payload":{"rows":[]}}"#.utf8)
        suite.expect((try? RemoteMessage.decoded(from: future)) == .unknown("processes"),
                     "a message a newer peer sends is read as unknown, not refused")
        let text = String(decoding: (try? RemoteMessage.ping.encoded()) ?? Data(), as: UTF8.self)
        suite.expect(text == #"{"type":"ping"}"#, "a message without a payload is just its type")
    }

    private static func pairing(_ suite: TestSuite) {
        let key = Data((0..<32).map { UInt8($0 * 7 & 0xFF) })
        let pairing = RemotePairing(name: "Ali's Mac mini", host: "alis-mac-mini.local", alternateHost: "100.101.102.103",
                                    port: 47823, id: "3f1c2a9e-0000-4000-8000-000000000001", key: key)
        suite.expect(RemotePairing(url: pairing.url) == pairing, "a pairing link reads back as written")
        var withoutAlternate = pairing
        withoutAlternate.alternateHost = nil
        suite.expect(RemotePairing(url: withoutAlternate.url) == withoutAlternate, "the address away from home is optional")
        let encodedKey = RemotePairing.base64URL(key)
        suite.expect(!encodedKey.contains("=") && !encodedKey.contains("+") && !encodedKey.contains("/"),
                     "the key is unpadded base64url, safe in a URL as it is")

        func refused(_ text: String, _ reason: String) {
            suite.expect(URL(string: text).flatMap(RemotePairing.init(url:)) == nil, "a pairing link is refused: \(reason)")
        }
        let good = pairing.url.absoluteString
        refused(good.replacingOccurrences(of: "beacon://", with: "https://"), "another scheme")
        refused(good.replacingOccurrences(of: "v=1", with: "v=2"), "another protocol version")
        refused(good.replacingOccurrences(of: "port=47823", with: "port=0"), "port 0")
        refused(good.replacingOccurrences(of: "port=47823", with: "port=70000"), "a port out of range")
        refused(good.replacingOccurrences(of: "host=alis-mac-mini.local", with: "host=evil.example/path"), "a host with a path")
        refused(good.replacingOccurrences(of: "host=alis-mac-mini.local", with: "host="), "an empty host")
        refused(good + "&host=other.local", "a repeated field")
        refused(good.replacingOccurrences(of: "id=3f1c2a9e-0000-4000-8000-000000000001", with: "id=short"), "an id too short")
        refused(good.replacingOccurrences(of: "key=\(RemotePairing.base64URL(key))", with: "key=\(RemotePairing.base64URL(key.prefix(16)))"),
                "a key that isn't 32 bytes")
        refused(good.replacingOccurrences(of: "key=\(RemotePairing.base64URL(key))", with: "key=not+base64url"), "a key in plain base64")
    }
}
