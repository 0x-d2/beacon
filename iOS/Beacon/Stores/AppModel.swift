// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The app's state: the paired Macs and a live session for each, the demo
/// Mac, and the reading preferences. Pairing goes through here, from the
/// scanner, a pasted link or a `beacon://pair` link the Camera app opened.
/// The Apple Watch reads the same sessions through `WatchRelay`.
@MainActor
@Observable
final class AppModel {
    private(set) var macs: [PairedMac] = [] {
        didSet { watchRelay?.publishContext() }
    }
    private var sessions: [String: MacSession] = [:]
    /// Where the navigation stack is: a Mac's dashboard, then one of its readings.
    var path: [Route] = []
    var pairingError: String?

    var temperatureUnit = TemperatureUnit(rawValue: UserDefaults.standard.string(forKey: "temperatureUnit") ?? "") ?? .celsius {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
            watchRelay?.publishContext()
        }
    }

    let demo = MacSession(mac: PairedMac(pairing: DemoData.pairing), isDemo: true)

    /// The Apple Watch's way to the Macs; none for the demo-only app (the catalog's renders, the tests).
    @ObservationIgnored private var watchRelay: WatchRelay?

    init(demoOnly: Bool = false) {
        macs = demoOnly ? [] : PairingStore.all()
        if !demoOnly {
            // Early, as WatchConnectivity asks: the watch's message may be what launched the app, in the background.
            let relay = WatchRelay(model: self)
            watchRelay = relay
            relay.activate()
        }
    }

    func session(for id: String) -> MacSession? {
        if id == demo.id { return demo }
        if let session = sessions[id] { return session }
        guard let mac = macs.first(where: { $0.id == id }) else { return nil }
        let session = MacSession(mac: mac)
        sessions[id] = session
        return session
    }

    /// A pairing link that came from outside the app (the Camera app, a web
    /// page, another app): shown for the owner to confirm, never saved on its
    /// own, since anything can open a beacon:// link.
    var proposedPairing: RemotePairing?

    /// Reads a pairing link the owner scanned or pasted in the app, and keeps the Mac it names.
    @discardableResult
    func pair(link: String) -> PairedMac? {
        guard let pairing = parse(link) else { return nil }
        return pair(pairing)
    }

    /// A pairing link from outside the app: asks first (MacsView's confirmation).
    func propose(link: String) {
        proposedPairing = parse(link)
    }

    func confirmProposedPairing() {
        if let pairing = proposedPairing { pair(pairing) }
        proposedPairing = nil
    }

    private func parse(_ link: String) -> RemotePairing? {
        guard let url = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
              let pairing = RemotePairing(url: url) else {
            pairingError = String(localized: "That isn't a Beacon pairing code. On the Mac, open Settings › Monitor › Watch from iPhone and add a phone.")
            return nil
        }
        return pairing
    }

    /// Keeps the Mac a pairing names. The same pairing again (its id) updates
    /// it; any other entry stays until the owner forgets it, whatever the new
    /// one calls itself.
    @discardableResult
    func pair(_ pairing: RemotePairing) -> PairedMac? {
        let mac = PairedMac(pairing: pairing)
        guard PairingStore.save(mac) else {
            pairingError = String(localized: "Couldn't save the Mac's key on this phone.")
            return nil
        }
        sessions[mac.id]?.disconnect()
        sessions[mac.id] = nil
        macs = PairingStore.all()
        pairingError = nil
        path = [.mac(mac.id)]
        return mac
    }

    func remove(_ id: String) {
        sessions[id]?.stopWatching()
        sessions[id]?.disconnect()
        sessions[id] = nil
        PairingStore.remove(id: id)
        macs = PairingStore.all()
        path.removeAll { $0.macID == id }
    }

    /// `-screen dashboard`, `-screen cpu`… at launch (with `-demo 1`): opens that screen on the demo Mac, for the
    /// catalog's renders and for a quick look in the simulator.
    func open(screen: String) {
        if screen == "dashboard" { path = [.mac(demo.id)]; return }
        if let kind = MetricKind(rawValue: screen) { path = [.mac(demo.id), .metric(demo.id, kind)] }
    }

    /// The app went to the background: nothing is read while no one looks, but the Mac the Apple Watch shows.
    func pauseAll() {
        sessions.values.forEach { session in
            session.stopWatching()
            if !session.watching { session.disconnect() }
        }
        demo.stopWatching()
    }
}

enum Route: Hashable {
    case mac(String)
    case metric(String, MetricKind)

    var macID: String {
        switch self {
        case let .mac(id), let .metric(id, _): return id
        }
    }
}
