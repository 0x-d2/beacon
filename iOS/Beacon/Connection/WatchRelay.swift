// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Observation
import UIKit
import WatchConnectivity

/// Beacon on the Apple Watch reads the Macs through this phone
/// (WatchLink.swift): the watch can't open a Mac's connection itself. While a
/// watch screen shows a Mac and keeps saying so, the relay keeps that Mac's
/// session watching, Beacon in the background or not (the watch's message
/// wakes it), and passes on what the Mac sends. It tells the watch the paired
/// Macs by id and name; their keys stay here.
@MainActor
final class WatchRelay: NSObject {
    private weak var model: AppModel?
    /// How long the watch may stay silent before it counts as gone.
    private let silence: Duration
    /// The Mac the watch shows.
    private(set) var watched: MacSession?
    private var forwarding: Task<Void, Never>?
    private var expiry: Task<Void, Never>?
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid

    init(model: AppModel, silence: Duration = .seconds(WatchLink.silenceTimeout)) {
        self.model = model
        self.silence = silence
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Tells the watch the paired Macs and the unit; it keeps them until the next.
    func publishContext() {
        guard WCSession.isSupported(), let model else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let context = WatchContext(macs: model.macs.map { WatchMac(id: $0.id, name: $0.name) }, temperatureUnit: model.temperatureUnit.rawValue)
        try? session.updateApplicationContext(context.dictionary())
    }

    func receive(_ message: WatchMessage) {
        guard case let .watch(macID, active) = message else { return }
        if active { watch(macID) } else if watched?.id == macID { stop() }
    }

    private func watch(_ macID: String) {
        if watched?.id != macID {
            stop()
            guard let session = model?.session(for: macID) else {
                // The watch's list is behind: this phone no longer has that Mac.
                send(.status(macID: macID, status: .forgotten))
                publishContext()
                return
            }
            watched = session
            session.watchedFromWatch = true
            forward(session)
        }
        // A first word or a heartbeat: either keeps the watch watching a while longer.
        renewBackgroundTime()
        scheduleExpiry()
    }

    private func stop() {
        forwarding?.cancel()
        forwarding = nil
        expiry?.cancel()
        expiry = nil
        if let watched {
            watched.watchedFromWatch = false
            // In the background no screen will close it: close it now rather than leave it to the Mac's silence timeout.
            if UIApplication.shared.applicationState == .background, !watched.watching { watched.disconnect() }
        }
        watched = nil
        endBackgroundTime()
    }

    /// What the phone already has first, so the watch's screen and charts start full; then each change.
    private func forward(_ session: MacSession) {
        let macID = session.id
        forwarding = Task { [weak self] in
            var last: Relayed?
            for await now in Observations({ Relayed(session) }) {
                guard let self else { return }
                if now.status != last?.status { send(.status(macID: macID, status: now.status)) }
                if now.info != last?.info, let info = now.info { send(.info(macID: macID, info: info)) }
                // A reading the history only grew by goes alone; a history changed any other way (the first, a new
                // connection's) goes whole, after it.
                var grown = last?.history ?? LiveHistory()
                if now.snapshot != last?.snapshot, let snapshot = now.snapshot {
                    send(.snapshot(macID: macID, snapshot: snapshot))
                    grown.append(snapshot)
                }
                if now.history != grown {
                    send(.history(macID: macID, history: now.history.remote(interval: now.info?.interval ?? 2)))
                }
                last = now
            }
        }
    }

    private func send(_ message: WatchMessage) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable, let data = try? message.encoded() else { return }
        session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }

    /// The watch stopped saying it watches (its app went away, out of reach): stop for it.
    private func scheduleExpiry() {
        expiry?.cancel()
        expiry = Task { [weak self, silence] in
            try? await Task.sleep(for: silence)
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    /// Each word from the watch buys Beacon another stretch in the background (the system's to decide, about half a
    /// minute), so the Mac's connection stays open while the watch shows it.
    private func renewBackgroundTime() {
        let previous = backgroundTask
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Apple Watch") { [weak self] in
            self?.endBackgroundTime()
        }
        if previous != .invalid { UIApplication.shared.endBackgroundTask(previous) }
    }

    private func endBackgroundTime() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

extension WatchRelay: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in self.publishContext() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    /// The owner switched to another watch: start over with that one.
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    /// Beacon came to the watch (or a watch was paired): it needs the Macs.
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.publishContext() }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let message = try? WatchMessage.decoded(from: messageData) else { return }
        DispatchQueue.main.async { MainActor.assumeIsolated { self.receive(message) } }
    }
}

/// What the relay passes on of a session, beside what it passed last.
private struct Relayed: Equatable, Sendable {
    var status: WatchStatus
    var info: RemoteMacInfo?
    var snapshot: RemoteSnapshot?
    var history: LiveHistory

    @MainActor init(_ session: MacSession) {
        status = WatchStatus(session)
        info = session.info
        snapshot = session.snapshot
        history = session.history
    }
}

extension WatchStatus {
    @MainActor init(_ session: MacSession) {
        switch session.status {
        case .idle: self = .idle
        case .connecting: self = .connecting
        case .live: self = .live(away: session.connectedHost.map { $0 != session.mac.host } ?? false)
        case let .offline(reason): self = .offline(reason)
        case let .refused(reason): self = .refused(reason)
        }
    }
}
