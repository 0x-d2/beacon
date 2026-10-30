// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Observation
import WatchConnectivity
import WidgetKit

/// The watch's state: the Macs the phone has paired, what the phone passes on
/// of each, and the demo Mac. The watch reads no Mac itself
/// (Beacon/Connection/WatchLink.swift): while a screen shows one it asks the
/// phone, and again every few seconds, and the phone stops for a watch that
/// goes quiet.
@MainActor
@Observable
final class WatchModel: NSObject {
    private(set) var macs: [WatchMac] = []
    private(set) var temperatureUnit = TemperatureUnit.celsius
    /// Where the navigation stack is: a Mac's readings, then one of them.
    var path: [WatchRoute] = []

    let demo = WatchMacState(mac: WatchMac(id: DemoData.pairing.id, name: DemoData.pairing.name), isDemo: true)

    @ObservationIgnored private var states: [String: WatchMacState] = [:]
    @ObservationIgnored private var heartbeat: Task<Void, Never>?
    @ObservationIgnored private var openedTheOnlyMac = false
    /// A Mac the complication opened before the phone's list of Macs came in.
    @ObservationIgnored private var pendingMacID: String?
    @ObservationIgnored private var complicationReloaded = Date.distantPast
    /// `-demo 1`: the simulator and the screenshots. The phone isn't asked, and the demo's readings may go to the complication.
    @ObservationIgnored private let demoOnly: Bool

    init(demoOnly: Bool = false) {
        self.demoOnly = demoOnly
        super.init()
        demo.model = self
        if !demoOnly, WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func state(for id: String) -> WatchMacState? {
        if id == demo.id { return demo }
        if let state = states[id] { return state }
        guard let mac = macs.first(where: { $0.id == id }) else { return nil }
        let state = WatchMacState(mac: mac, isDemo: false)
        state.model = self
        states[id] = state
        return state
    }

    /// `-screen dashboard`, `-screen cpu`… at launch (with `-demo 1`): opens that screen on the demo Mac.
    func open(screen: String) {
        if screen == "dashboard" { path = [.mac(demo.id)]; return }
        if let kind = MetricKind(rawValue: screen) { path = [.mac(demo.id), .metric(demo.id, kind)] }
    }

    /// The complication's link: that Mac's readings, now or once the phone's list of Macs is in.
    func open(link: URL) {
        guard let id = LastReading.macID(in: link) else { return }
        if state(for: id) != nil { path = [.mac(id)] } else { pendingMacID = id }
    }

    /// The app left the screen: its screens stay counted, but nothing is asked for until it's back.
    func setPaused(_ paused: Bool) {
        ([demo] + Array(states.values)).forEach { $0.paused = paused }
    }

    // MARK: - The phone

    private func apply(_ context: WatchContext) {
        macs = context.macs
        temperatureUnit = TemperatureUnit(rawValue: context.temperatureUnit) ?? .celsius
        // A Mac the phone forgot leaves the screen, and so stops being watched.
        let ids = Set(macs.map(\.id))
        path.removeAll { $0.macID != demo.id && !ids.contains($0.macID) }
        states = states.filter { ids.contains($0.key) }
        if let pendingMacID, ids.contains(pendingMacID) {
            path = [.mac(pendingMacID)]
            self.pendingMacID = nil
        }
        // With one Mac, the app opens on it: once, so going back to the list stays there.
        if !openedTheOnlyMac, path.isEmpty, macs.count == 1 { path = [.mac(macs[0].id)] }
        openedTheOnlyMac = true
    }

    private func receive(_ message: WatchMessage) {
        let id: String
        switch message {
        case let .status(macID, _), let .info(macID, _), let .history(macID, _), let .snapshot(macID, _): id = macID
        case .watch: return
        }
        guard let state = states[id] else { return }
        state.apply(message)
    }

    fileprivate func watchingChanged(_ state: WatchMacState) {
        if state.watching {
            if state.info == nil, state.status == .idle { state.status = .connecting }
            send(.watch(macID: state.id, active: true), for: state)
            startHeartbeat()
        } else {
            send(.watch(macID: state.id, active: false), for: state)
            reloadComplication()
        }
    }

    /// While any screen shows a Mac, says so again every few seconds.
    private func startHeartbeat() {
        guard heartbeat == nil else { return }
        heartbeat = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(WatchLink.heartbeat))
                guard let self else { return }
                let watched = states.values.filter(\.watching)
                if watched.isEmpty { heartbeat = nil; return }
                // Out of reach for a whole beat (not just the moment after launch, before WatchConnectivity says so): say it.
                for state in watched where !send(.watch(macID: state.id, active: true), for: state) { state.phoneUnreachable = true }
            }
        }
    }

    /// The phone came back in reach: say at once what the screens show.
    private func resendWatching() {
        states.values.filter(\.watching).forEach { send(.watch(macID: $0.id, active: true), for: $0) }
    }

    /// Whether the phone was in reach to send it to; one that doesn't take it marks the Mac's state.
    @discardableResult
    private func send(_ message: WatchMessage, for state: WatchMacState) -> Bool {
        guard WCSession.isSupported(), let data = try? message.encoded() else { return false }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return false }
        // WatchConnectivity calls this on a queue of its own.
        session.sendMessageData(data, replyHandler: nil) { @Sendable _ in
            Task { @MainActor in state.phoneUnreachable = true }
        }
        return true
    }

    // MARK: - The complication

    /// Keeps a reading for the complication; it redraws at most once a minute while readings flow, and once more
    /// when the screen stops showing them.
    fileprivate func read(_ state: WatchMacState) {
        guard !state.isDemo || demoOnly, let snapshot = state.snapshot else { return }
        LastReadingStore.write(LastReading(macID: state.id, macName: state.info?.name ?? state.mac.name, time: snapshot.time,
                                           cpu: snapshot.cpuUsage, memory: snapshot.memoryFraction, gpu: snapshot.gpuUsage,
                                           cpuTemperature: snapshot.cpuTemperature, temperatureUnit: temperatureUnit))
        if Date.now.timeIntervalSince(complicationReloaded) >= 60 { reloadComplication() }
    }

    private func reloadComplication() {
        complicationReloaded = .now
        WidgetCenter.shared.reloadTimelines(ofKind: LastReading.widgetKind)
    }
}

extension WatchModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        // The Macs as the phone last told them, kept across launches.
        guard let context = WatchContext(dictionary: session.receivedApplicationContext) else { return }
        DispatchQueue.main.async { MainActor.assumeIsolated { self.apply(context) } }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let context = WatchContext(dictionary: applicationContext) else { return }
        DispatchQueue.main.async { MainActor.assumeIsolated { self.apply(context) } }
    }

    /// In order, on the main queue: a history and the reading after it must not trade places.
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let message = try? WatchMessage.decoded(from: messageData) else { return }
        DispatchQueue.main.async { MainActor.assumeIsolated { self.receive(message) } }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        DispatchQueue.main.async { MainActor.assumeIsolated { self.resendWatching() } }
    }
}

/// One Mac as the watch sees it, through the phone: where the phone's
/// connection stands, the Mac's info, its latest reading and recent history.
@MainActor
@Observable
final class WatchMacState: Identifiable {
    let mac: WatchMac
    let isDemo: Bool
    nonisolated var id: String { mac.id }

    fileprivate(set) var status: WatchStatus = .idle
    fileprivate(set) var info: RemoteMacInfo?
    fileprivate(set) var snapshot: RemoteSnapshot?
    fileprivate(set) var history = LiveHistory()
    /// The phone didn't take the last word: out of reach, or Beacon there couldn't be woken.
    fileprivate(set) var phoneUnreachable = false

    /// Whether a screen shows this Mac's readings, with the app on screen. Screens count themselves in and out
    /// (`watch()`, `unwatch()`), so going from the readings to one of them never drops it in between.
    private(set) var watching = false
    @ObservationIgnored private var watchers = 0
    @ObservationIgnored fileprivate var paused = false {
        didSet { update() }
    }
    @ObservationIgnored fileprivate weak var model: WatchModel?
    @ObservationIgnored private var demoTask: Task<Void, Never>?

    init(mac: WatchMac, isDemo: Bool) {
        self.mac = mac
        self.isDemo = isDemo
        if isDemo {
            status = .live(away: false)
            info = DemoData.info
            snapshot = DemoData.snapshot
            history = LiveHistory(DemoData.history)
        }
    }

    func watch() {
        watchers += 1
        update()
    }

    func unwatch() {
        watchers = max(0, watchers - 1)
        update()
    }

    private func update() {
        let now = watchers > 0 && !paused
        guard now != watching else { return }
        watching = now
        // The demo Mac never asks the phone: it drifts here.
        if isDemo { watching ? startDemo() : stopDemo() } else { model?.watchingChanged(self) }
    }

    fileprivate func apply(_ message: WatchMessage) {
        phoneUnreachable = false
        switch message {
        case let .status(_, status):
            self.status = status
        case let .info(_, info):
            self.info = info
        case let .history(_, history):
            self.history = LiveHistory(history)
        case let .snapshot(_, snapshot):
            self.snapshot = snapshot
            history.append(snapshot)
            model?.read(self)
        case .watch:
            break
        }
    }

    /// The demo Mac: the fixture's readings, drifting a little every two seconds, as on the phone.
    private func startDemo() {
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                tick += 1
                let next = DemoData.snapshot(tick: tick)
                snapshot = next
                history.append(next)
                model?.read(self)
            }
        }
    }

    private func stopDemo() {
        demoTask?.cancel()
        demoTask = nil
    }
}

enum WatchRoute: Hashable {
    case mac(String)
    case metric(String, MetricKind)

    var macID: String {
        switch self {
        case let .mac(id), let .metric(id, _): return id
        }
    }
}
