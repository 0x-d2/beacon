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

/// The Apple Watch reads the Macs through the phone (WatchLink.swift): what they say, and how long the phone watches for it.
@MainActor
struct WatchLinkTests {
    @Test func messagesSurviveTheTripToTheWatch() throws {
        let messages: [WatchMessage] = [
            .watch(macID: "0f9b6c1e-1111", active: true),
            .status(macID: "0f9b6c1e-1111", status: .offline("Not reachable")),
            .status(macID: "0f9b6c1e-1111", status: .live(away: true)),
            .info(macID: "0f9b6c1e-1111", info: DemoData.info),
            .history(macID: "0f9b6c1e-1111", history: DemoData.history),
            .snapshot(macID: "0f9b6c1e-1111", snapshot: DemoData.snapshot),
        ]
        for message in messages {
            let read = try WatchMessage.decoded(from: message.encoded())
            // Dates go as seconds since 1970, as the Mac's do: equal to well under a millisecond.
            if case let .snapshot(_, snapshot) = read, case let .snapshot(_, sent) = message {
                #expect(snapshot.time.timeIntervalSince(sent.time).magnitude < 0.001)
                #expect(snapshot.cpuCoreUsage == sent.cpuCoreUsage)
            } else {
                #expect(read == message)
            }
        }
    }

    @Test func theWatchLearnsTheMacsButNotTheirKeys() throws {
        let context = WatchContext(macs: [WatchMac(id: "0f9b6c1e-1111", name: "Mac mini")], temperatureUnit: "fahrenheit")
        let dictionary = try context.dictionary()
        #expect(WatchContext(dictionary: dictionary) == context)
        let text = String(decoding: try #require(dictionary["context"] as? Data), as: UTF8.self)
        #expect(!text.contains("key") && !text.contains("host"), "only each Mac's id and name go to the watch")
    }

    @Test func theWatchKeepsItsMacWhenThePhoneLeavesTheScreen() {
        let model = AppModel(demoOnly: true)
        model.demo.watch()
        model.demo.watchedFromWatch = true
        model.pauseAll()
        #expect(model.demo.watching, "the watch still shows it")
        model.demo.watchedFromWatch = false
        #expect(!model.demo.watching)
    }

    @Test func thePhoneStopsForAWatchThatGoesQuiet() async throws {
        let model = AppModel(demoOnly: true)
        let relay = WatchRelay(model: model, silence: .milliseconds(150))
        relay.receive(.watch(macID: model.demo.id, active: true))
        #expect(model.demo.watchedFromWatch)
        try await Task.sleep(for: .milliseconds(100))
        relay.receive(.watch(macID: model.demo.id, active: true))
        try await Task.sleep(for: .milliseconds(100))
        #expect(model.demo.watchedFromWatch, "a heartbeat keeps it watching")
        try await Task.sleep(for: .milliseconds(300))
        #expect(!model.demo.watchedFromWatch, "silence past the timeout ends it")
        #expect(relay.watched == nil)
    }

    @Test func aWatchThatSaysItStoppedIsLetGoAtOnce() {
        let model = AppModel(demoOnly: true)
        let relay = WatchRelay(model: model)
        relay.receive(.watch(macID: model.demo.id, active: true))
        relay.receive(.watch(macID: model.demo.id, active: false))
        #expect(!model.demo.watchedFromWatch)
    }
}
