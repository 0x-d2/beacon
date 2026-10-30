// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Testing
@testable import Beacon

/// The phone's side of the protocol it shares with the Mac, its history and its readings' formats.
@MainActor
struct BeaconTests {
    @Test func pairingLinkReadsBackAsTheMacWritesIt() throws {
        let key = Data((0..<32).map { UInt8($0) })
        let pairing = RemotePairing(name: "Mac mini", host: "mac-mini.local", alternateHost: "100.100.1.2", port: 47823,
                                    id: "0f9b6c1e-1111-4222-8333-444455556666", key: key)
        let read = try #require(RemotePairing(url: pairing.url))
        #expect(read == pairing)
        let mac = PairedMac(pairing: read)
        #expect(mac.hosts == ["mac-mini.local", "100.100.1.2"], "the local name first, then the address away from home")
    }

    @Test(arguments: [
        "https://pair?v=1",
        "beacon://pair?v=1&name=Mac&host=a.local&port=47823&id=short&key=AAAA",
        "beacon://pair?v=2&name=Mac&host=a.local&port=47823&id=0f9b6c1e-1111&key=AAAA",
    ])
    func aLinkThatIsntExactlyAPairingIsRefused(_ text: String) {
        #expect(URL(string: text).flatMap(RemotePairing.init(url:)) == nil)
    }

    @Test func aModelRefusesAForeignLinkAndSaysWhy() {
        let model = AppModel(demoOnly: true)
        #expect(model.pair(link: "https://example.com") == nil)
        #expect(model.pairingError != nil)
    }

    @Test func historyKeepsTheLastFourMinutes() {
        var history = LiveHistory()
        for tick in 0..<200 { history.append(DemoData.snapshot(tick: tick)) }
        #expect(history.cpu.count == LiveHistory.capacity)
        #expect(history.memory.allSatisfy { (0...1).contains($0) }, "memory is kept as the used share of the total")
        let seeded = LiveHistory(DemoData.history)
        #expect(seeded.networkDown.count == 120)
    }

    @Test func temperaturesFollowTheChosenUnit() {
        #expect(Format.temperature(100, unit: .fahrenheit).hasPrefix("212"))
        #expect(Format.temperature(nil, unit: .celsius) == "–")
    }

    @Test func messagesSurviveTheTripFromTheMac() throws {
        let message = RemoteMessage.snapshot(DemoData.snapshot)
        let data = try message.encoded()
        let read = try RemoteMessage.decoded(from: data)
        guard case let .snapshot(snapshot) = read else { Issue.record("not a snapshot"); return }
        #expect(snapshot.cpuCoreUsage.count == 10)
        #expect(snapshot.disks.count == 2)
    }
}

/// A beacon:// link from outside the app (anything can open one) waits for the owner, and never replaces another Mac.
@MainActor
struct PairingConfirmationTests {
    @Test func aLinkFromOutsideIsOnlyProposed() throws {
        let model = AppModel(demoOnly: true)
        let pairing = RemotePairing(name: "Mac mini", host: "mac-mini.local", alternateHost: nil, port: 47823,
                                    id: "0f9b6c1e-1111-4222-8333-444455556666", key: Data(count: 32))
        model.propose(link: pairing.url.absoluteString)
        #expect(model.proposedPairing == pairing)
        #expect(model.macs.isEmpty, "nothing is saved before the owner confirms")
        model.proposedPairing = nil
        #expect(model.macs.isEmpty)
    }
}
