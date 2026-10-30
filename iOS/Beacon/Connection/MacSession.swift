// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Network
import UIKit

/// One Mac's live readings, and the connection that brings them
/// (docs/remote-monitor.md). TLS 1.2 with the pre-shared key the Mac gave this
/// phone, a WebSocket on top, tried at the Mac's local name first and then at
/// its address away from home; lost, it tries again after 1, 2, 4… up to 30
/// seconds. It asks for readings only while a screen shows them (`watching`),
/// so the Mac samples for the phone only then. Everything runs on the main
/// queue: one message every second or two needs no other thread, and the
/// state stays where SwiftUI reads it.
@MainActor
@Observable
final class MacSession: Identifiable {
    enum Status: Equatable {
        case idle
        case connecting
        case live
        /// Not reachable right now: retrying.
        case offline(String)
        /// The Mac turned this phone away (removed from its list, another protocol).
        case refused(String)
    }

    let mac: PairedMac
    let isDemo: Bool
    nonisolated var id: String { mac.id }

    private(set) var status: Status = .idle
    private(set) var info: RemoteMacInfo?
    private(set) var snapshot: RemoteSnapshot?
    private(set) var history = LiveHistory()
    /// The host the open connection uses: the local name or the address away from home.
    private(set) var connectedHost: String?

    /// Whether a screen shows this Mac's readings. Screens count themselves in
    /// and out (`watch()`, `unwatch()`), so going from the dashboard to a detail
    /// page never drops the subscription in between, whichever appears first.
    private(set) var watching = false {
        didSet {
            guard watching != oldValue else { return }
            if isDemo { watching ? startDemo() : stopDemo(); return }
            if watching { connect() } else { sendSubscription(); scheduleIdleClose() }
        }
    }
    private var watchers = 0

    func watch() {
        watchers += 1
        watching = true
    }

    func unwatch() {
        watchers = max(0, watchers - 1)
        watching = watchers > 0 || watchedFromWatch
    }

    /// The app leaves the screen: every watcher at once, but the watch's.
    func stopWatching() {
        watchers = 0
        watching = watchedFromWatch
    }

    /// Whether the Apple Watch shows this Mac's readings (WatchRelay). It
    /// watches through this phone even with Beacon in the background, so the
    /// app leaving the screen doesn't stop it.
    var watchedFromWatch = false {
        didSet { watching = watchers > 0 || watchedFromWatch }
    }

    private var connection: NWConnection?
    private var hostIndex = 0
    private var attempt = 0
    private var lastHeard = Date.distantPast
    private var tasks: [Task<Void, Never>] = []
    private var demoTask: Task<Void, Never>?
    private var idleClose: Task<Void, Never>?

    init(mac: PairedMac, isDemo: Bool = false) {
        self.mac = mac
        self.isDemo = isDemo
        if isDemo {
            info = DemoData.info
            snapshot = DemoData.snapshot
            history = LiveHistory(DemoData.history)
            status = .live
        }
    }

    // MARK: - Connection

    func connect() {
        guard !isDemo else { return }
        idleClose?.cancel()
        if connection != nil, status == .live || status == .connecting {
            sendSubscription()
            return
        }
        open(hostIndex: 0)
    }

    func disconnect() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        connection?.cancel()
        connection = nil
        connectedHost = nil
        if case .refused = status {} else { status = .idle }
    }

    private func open(hostIndex index: Int) {
        connection?.cancel()
        let hosts = mac.hosts
        hostIndex = index % max(hosts.count, 1)
        let host = hosts[hostIndex]
        let bracketed = host.contains(":") ? "[\(host)]" : host
        guard let url = URL(string: "ws://\(bracketed):\(mac.port)\(RemoteMonitorProtocol.path)") else { return }
        status = .connecting
        let connection = NWConnection(to: .url(url), using: Self.parameters(identity: mac.id, key: mac.key))
        self.connection = connection
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            MainActor.assumeIsolated {
                guard let self, let connection, connection === self.connection else { return }
                self.handle(state, on: connection, host: host)
            }
        }
        connection.start(queue: .main)
        // A host that doesn't answer in a few seconds (the local name, away from home) gives way to the next.
        let timeout = Task { [weak self, weak connection] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled, let self, let connection, connection === self.connection, connection.state != .ready else { return }
            self.tryNextHost()
        }
        tasks.append(timeout)
    }

    private func handle(_ state: NWConnection.State, on connection: NWConnection, host: String) {
        switch state {
        case .ready:
            attempt = 0
            connectedHost = host
            lastHeard = .now
            send(.hello(RemoteHello(protocolVersion: RemoteMonitorProtocol.version, id: mac.id,
                                    device: UIDevice.current.name, app: "Beacon")))
            sendSubscription()
            receive(on: connection)
            startHeartbeat()
        case let .waiting(error), let .failed(error):
            if case .refused = status { return }
            status = .offline(Self.describe(error))
            tryNextHost()
        case .cancelled, .setup, .preparing:
            break
        @unknown default:
            break
        }
    }

    private func tryNextHost() {
        connection?.cancel()
        connection = nil
        connectedHost = nil
        guard watching else { status = .idle; return }
        if hostIndex + 1 < mac.hosts.count {
            open(hostIndex: hostIndex + 1)
            return
        }
        // Every host tried: wait, longer each time, then start over.
        attempt += 1
        let delay = min(30.0, pow(2, Double(attempt - 1)))
        if case .connecting = status { status = .offline(String(localized: "Not reachable")) }
        let retry = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self, self.watching, self.connection == nil else { return }
            self.open(hostIndex: 0)
        }
        tasks.append(retry)
    }

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self, weak connection] data, _, _, error in
            MainActor.assumeIsolated {
                guard let self, let connection, connection === self.connection else { return }
                if let data, !data.isEmpty, let message = try? RemoteMessage.decoded(from: data) {
                    self.lastHeard = .now
                    self.handle(message)
                }
                if error == nil, connection.state == .ready { self.receive(on: connection) }
            }
        }
    }

    private func handle(_ message: RemoteMessage) {
        switch message {
        case let .info(info):
            self.info = info
            status = .live
        case let .history(history):
            self.history = LiveHistory(history)
        case let .snapshot(snapshot):
            self.snapshot = snapshot
            history.append(snapshot)
            status = .live
        case .ping:
            send(.pong)
        case let .refused(reason):
            status = .refused(reason)
            disconnect()
        case .pong, .hello, .subscribe, .unknown:
            break
        }
    }

    private func sendSubscription() {
        guard connection?.state == .ready else { return }
        send(.subscribe(RemoteSubscription(active: watching)))
    }

    private func send(_ message: RemoteMessage) {
        guard let connection, let data = try? message.encoded() else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "message", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }

    /// Pings while connected; a Mac silent for 15 seconds is gone, and the connection starts over.
    private func startHeartbeat() {
        let heartbeat = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(RemoteMonitorProtocol.silenceTimeout / 3))
                guard !Task.isCancelled, let self, self.connection?.state == .ready else { return }
                if Date.now.timeIntervalSince(self.lastHeard) > RemoteMonitorProtocol.silenceTimeout {
                    self.status = .offline(String(localized: "The Mac stopped answering"))
                    self.tryNextHost()
                    return
                }
                self.send(.ping)
            }
        }
        tasks.append(heartbeat)
    }

    /// No screen shows the readings: keep the connection a little in case one comes back, then close it.
    private func scheduleIdleClose() {
        idleClose?.cancel()
        idleClose = Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, let self, !self.watching else { return }
            self.disconnect()
        }
    }

    /// TLS 1.2 with this phone's pre-shared key for that Mac, a WebSocket on top: the Mac's listener, mirrored.
    nonisolated static func parameters(identity: String, key: Data) -> NWParameters {
        let tls = NWProtocolTLS.Options()
        let keyData = key.withUnsafeBytes { DispatchData(bytes: $0) } as __DispatchData
        let identityData = Data(identity.utf8).withUnsafeBytes { DispatchData(bytes: $0) } as __DispatchData
        sec_protocol_options_add_pre_shared_key(tls.securityProtocolOptions, keyData, identityData)
        sec_protocol_options_append_tls_ciphersuite(tls.securityProtocolOptions,
                                                    tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256))!)
        sec_protocol_options_set_min_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        let parameters = NWParameters(tls: tls)
        let webSocket = NWProtocolWebSocket.Options()
        webSocket.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(webSocket, at: 0)
        return parameters
    }

    private static func describe(_ error: NWError) -> String {
        switch error {
        case .tls: return String(localized: "The Mac didn't accept this phone's key")
        case let .posix(code) where code == .ECONNREFUSED: return String(localized: "Watch from iPhone is off on the Mac")
        default: return String(localized: "Not reachable")
        }
    }

    // MARK: - Demo

    /// The demo Mac: the fixture's readings, drifting a little every two seconds.
    private func startDemo() {
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                tick += 1
                let next = DemoData.snapshot(tick: tick)
                self.snapshot = next
                self.history.append(next)
            }
        }
    }

    private func stopDemo() {
        demoTask?.cancel()
        demoTask = nil
    }
}
