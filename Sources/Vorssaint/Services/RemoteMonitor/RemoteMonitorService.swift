// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Combine
import Network
import SystemConfiguration

/// Serves this Mac's readings to the paired Beacon iPhone app
/// (docs/remote-monitor.md). Off unless the owner turns it on in Settings ›
/// Monitor, and even then nothing listens until a phone is paired or being
/// paired. Each phone holds its own 32-byte key from the pairing QR code; the
/// listener accepts TLS 1.2 with those keys only (TLS-PSK), so an unpaired
/// device can't even finish the handshake, and removing a phone removes its
/// key. Readings are sampled only while a phone shows them (`subscribe`),
/// at the panel's cadence, and nothing is sent anywhere else.
final class RemoteMonitorService: ObservableObject {
    static let shared = RemoteMonitorService()

    enum State: Equatable {
        case off
        /// On, with no phone to listen for.
        case idle
        case listening(port: UInt16)
        case failed(String)
    }

    @Published private(set) var state: State = .off
    @Published private(set) var phones: [RemotePairedPhone] = []
    /// The ids of the phones connected right now.
    @Published private(set) var connected: Set<String> = []
    /// The pairing the Settings card shows as a QR code, until a phone uses it or it expires.
    @Published private(set) var pendingPairing: RemotePairing?

    /// How long a QR code stays usable: long enough to pick up the phone,
    /// short enough that a photo of the screen goes stale.
    static let pairingLifetime: TimeInterval = 10 * 60

    private let queue = DispatchQueue(label: "com.vorssaint.utils.remote-monitor", qos: .utility)
    private var listener: NWListener?
    // Queue-confined.
    private var clients: [ObjectIdentifier: Client] = [:]
    private var heartbeat: DispatchSourceTimer?
    private var snapshots: AnyCancellable?
    private var pairingExpiry: DispatchWorkItem?

    private final class Client {
        let connection: NWConnection
        var phoneID: String?
        var subscribed = false
        var lastHeard = Date()

        init(_ connection: NWConnection) { self.connection = connection }
    }

    private init() {}

    // MARK: - Settings

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: DefaultsKey.remoteMonitorEnabled) }

    var port: UInt16 {
        let stored = UserDefaults.standard.integer(forKey: DefaultsKey.remoteMonitorPort)
        return (1...65535).contains(stored) ? UInt16(stored) : RemoteMonitorProtocol.defaultPort
    }

    /// Starts or stops serving to match the Settings switch. Called at launch,
    /// when the switch changes and when the monitor's features do.
    func syncWithPreferences() {
        onMain { [self] in
            phones = RemotePairingStore.phones()
            if isEnabled { restartListener() } else { stop() }
        }
    }

    // MARK: - Pairing

    /// A new phone's QR code: fresh credentials, accepted by the listener at
    /// once, shown until a phone connects with them or they expire unused.
    @discardableResult
    func startPairing() -> RemotePairing? {
        guard isEnabled, let credentials = RemotePairingStore.newCredentials() else { return nil }
        let phone = RemotePairedPhone(id: credentials.id, name: "iPhone", key: credentials.key, pairedAt: Date(), lastSeen: nil)
        guard RemotePairingStore.save(phone) else {
            state = .failed(FeatureStrings.remoteMonitor(L10n.shared.language).keychainFailed)
            return nil
        }
        let pairing = RemotePairing(name: Self.macName, host: Self.localHostName, alternateHost: alternateHost,
                                    port: port, id: credentials.id, key: credentials.key)
        // A code still on screen and never used is replaced, its key with it.
        if let previous = pendingPairing, phones.first(where: { $0.id == previous.id })?.lastSeen == nil {
            RemotePairingStore.remove(id: previous.id)
        }
        pendingPairing = pairing
        phones = RemotePairingStore.phones()
        restartListener()
        pairingExpiry?.cancel()
        let expiry = DispatchWorkItem { [weak self] in self?.expirePairing(id: credentials.id) }
        pairingExpiry = expiry
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.pairingLifetime, execute: expiry)
        return pairing
    }

    func cancelPairing() {
        guard let pairing = pendingPairing else { return }
        expirePairing(id: pairing.id)
    }

    private func expirePairing(id: String) {
        guard pendingPairing?.id == id else { return }
        pendingPairing = nil
        // A code never used takes its key with it.
        if phones.first(where: { $0.id == id })?.lastSeen == nil { remove(id: id) }
    }

    /// Forgets a phone: its key leaves the keychain and the listener, and a
    /// connection it has open now is closed.
    func remove(id: String) {
        RemotePairingStore.remove(id: id)
        phones = RemotePairingStore.phones()
        if pendingPairing?.id == id { pendingPairing = nil }
        queue.async { [weak self] in
            guard let self else { return }
            for client in self.clients.values where client.phoneID == id {
                self.send(.refused("removed"), to: client)
                client.connection.cancel()
            }
        }
        restartListener()
    }

    /// The address the QR code offers for reaching the Mac away from home: the
    /// one the owner typed, else this Mac's Tailscale address if it has one.
    var alternateHost: String? {
        let typed = (UserDefaults.standard.string(forKey: DefaultsKey.remoteMonitorAlternateHost) ?? "")
            .trimmingCharacters(in: .whitespaces)
        if !typed.isEmpty { return RemotePairing.isHostName(typed) ? typed : nil }
        return Self.tailnetAddress()
    }

    // MARK: - Listener

    private func restartListener() {
        listener?.cancel()
        listener = nil
        let keys = phones.map { (identity: $0.id, key: $0.key) }
        guard isEnabled, !keys.isEmpty else {
            state = isEnabled ? .idle : .off
            stopHeartbeat()
            return
        }
        do {
            let listener = try NWListener(using: Self.parameters(keys: keys), on: NWEndpoint.Port(rawValue: port)!)
            listener.service = NWListener.Service(name: Self.macName, type: RemoteMonitorProtocol.serviceType)
            listener.stateUpdateHandler = { [weak self] state in
                onMain {
                    guard let self else { return }
                    switch state {
                    case .ready: self.state = .listening(port: self.port)
                    case let .failed(error): self.state = .failed("\(error)")
                    default: break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
            listener.start(queue: queue)
            self.listener = listener
            startHeartbeat()
            observeSnapshots()
        } catch {
            state = .failed("\(error)")
        }
    }

    private func stop() {
        listener?.cancel()
        listener = nil
        stopHeartbeat()
        snapshots = nil
        queue.async { [weak self] in
            guard let self else { return }
            self.clients.values.forEach { $0.connection.cancel() }
            self.clients.removeAll()
            self.updateNeeds()
        }
        pendingPairing = nil
        connected = []
        state = .off
    }

    /// TLS 1.2 with the paired phones' keys and nothing else, a WebSocket on top.
    /// PSK cipher suites exist in TLS 1.2 only, so both ends pin it.
    static func parameters(keys: [(identity: String, key: Data)]) -> NWParameters {
        let tls = NWProtocolTLS.Options()
        for entry in keys {
            let key = entry.key.withUnsafeBytes { DispatchData(bytes: $0) } as __DispatchData
            let identity = Data(entry.identity.utf8).withUnsafeBytes { DispatchData(bytes: $0) } as __DispatchData
            sec_protocol_options_add_pre_shared_key(tls.securityProtocolOptions, key, identity)
        }
        sec_protocol_options_append_tls_ciphersuite(tls.securityProtocolOptions,
                                                    tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256))!)
        sec_protocol_options_set_min_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        let parameters = NWParameters(tls: tls)
        let webSocket = NWProtocolWebSocket.Options()
        webSocket.autoReplyPing = true
        webSocket.maximumMessageSize = 64 * 1024
        parameters.defaultProtocolStack.applicationProtocols.insert(webSocket, at: 0)
        return parameters
    }

    // MARK: - Clients

    private func accept(_ connection: NWConnection) {
        let client = Client(connection)
        clients[ObjectIdentifier(client)] = client
        connection.stateUpdateHandler = { [weak self, weak client] state in
            guard let self, let client else { return }
            switch state {
            case .ready:
                self.receive(from: client)
            case .failed, .cancelled:
                self.drop(client)
            default:
                break
            }
        }
        connection.start(queue: queue)
        // A peer that hasn't said who it is within a few seconds isn't a phone of ours.
        queue.asyncAfter(deadline: .now() + 10) { [weak self, weak client] in
            guard let self, let client, client.phoneID == nil else { return }
            client.connection.cancel()
            self.drop(client)
        }
    }

    private func receive(from client: Client) {
        client.connection.receiveMessage { [weak self, weak client] data, _, _, error in
            guard let self, let client else { return }
            if let data, !data.isEmpty {
                client.lastHeard = Date()
                if let message = try? RemoteMessage.decoded(from: data) { self.handle(message, from: client) }
            }
            if error == nil, client.connection.state == .ready { self.receive(from: client) }
        }
    }

    private func handle(_ message: RemoteMessage, from client: Client) {
        switch message {
        case let .hello(hello):
            guard hello.protocolVersion == RemoteMonitorProtocol.version else {
                send(.refused("protocol \(RemoteMonitorProtocol.version)"), to: client)
                client.connection.cancel()
                return
            }
            guard RemotePairedPhone.knownIDs.contains(hello.id) else {
                send(.refused("unknown"), to: client)
                client.connection.cancel()
                return
            }
            client.phoneID = hello.id
            send(.info(Self.macInfo()), to: client)
            let ids = Set(currentConnectedIDs())
            onMain { [self] in
                pairingUsed(by: hello)
                connected = ids
            }
        case let .subscribe(subscription):
            guard client.phoneID != nil else { return }
            client.subscribed = subscription.active
            updateNeeds()
            if subscription.active {
                onMain { [weak self] in
                    let snapshot = SystemMonitor.shared.snapshot
                    self?.queue.async {
                        self?.send(.history(RemoteMonitorBridge.history(snapshot)), to: client)
                        self?.send(.snapshot(RemoteMonitorBridge.snapshot(snapshot)), to: client)
                    }
                }
            }
        case .ping:
            send(.pong, to: client)
        case .pong, .info, .snapshot, .history, .refused, .unknown:
            break
        }
    }

    /// The phone that used the QR code on screen: named, marked seen, and the code put away.
    private func pairingUsed(by hello: RemoteHello) {
        guard var phone = RemotePairingStore.phones().first(where: { $0.id == hello.id }) else { return }
        phone.name = String(hello.device.prefix(64))
        phone.lastSeen = Date()
        RemotePairingStore.save(phone)
        phones = RemotePairingStore.phones()
        if pendingPairing?.id == hello.id {
            pendingPairing = nil
            pairingExpiry?.cancel()
        }
    }

    private func drop(_ client: Client) {
        guard clients.removeValue(forKey: ObjectIdentifier(client)) != nil else { return }
        updateNeeds()
        let ids = currentConnectedIDs()
        onMain { [weak self] in self?.connected = Set(ids) }
    }

    private func currentConnectedIDs() -> [String] {
        dispatchPrecondition(condition: .onQueue(queue))
        return clients.values.compactMap(\.phoneID)
    }

    /// Readings are taken for a phone only while one shows them.
    private func updateNeeds() {
        let watching = clients.values.contains { $0.subscribed }
        SystemMonitor.shared.setRemoteNeeds(watching ? .remoteReadings : .none)
    }

    private func send(_ message: RemoteMessage, to client: Client) {
        guard let data = try? message.encoded() else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "message", metadata: [metadata])
        client.connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }

    // MARK: - Readings and heartbeat

    private func observeSnapshots() {
        guard snapshots == nil else { return }
        snapshots = SystemMonitor.shared.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                guard let self else { return }
                let reading = RemoteMonitorBridge.snapshot(snapshot)
                self.queue.async {
                    for client in self.clients.values where client.subscribed { self.send(.snapshot(reading), to: client) }
                }
            }
    }

    private func startHeartbeat() {
        guard heartbeat == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 5, repeating: RemoteMonitorProtocol.silenceTimeout / 3, leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let now = Date()
            for client in self.clients.values {
                if now.timeIntervalSince(client.lastHeard) > RemoteMonitorProtocol.silenceTimeout {
                    client.connection.cancel()
                } else {
                    self.send(.ping, to: client)
                }
            }
        }
        timer.resume()
        heartbeat = timer
    }

    private func stopHeartbeat() {
        heartbeat?.cancel()
        heartbeat = nil
    }

    // MARK: - This Mac

    static var macName: String {
        Host.current().localizedName ?? "Mac"
    }

    /// `name.local`: how phones on the same network reach the Mac by name.
    static var localHostName: String {
        if let name = SCDynamicStoreCopyLocalHostName(nil) as String? { return "\(name).local" }
        return ProcessInfo.processInfo.hostName
    }

    /// This Mac's address on a Tailscale network (100.64.0.0/10 on a utun
    /// interface), which reaches it from anywhere the phone runs Tailscale too.
    static func tailnetAddress() -> String? {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0 else { return nil }
        defer { freeifaddrs(first) }
        var current = first
        while let entry = current?.pointee {
            defer { current = entry.ifa_next }
            guard let address = entry.ifa_addr, address.pointee.sa_family == UInt8(AF_INET),
                  String(cString: entry.ifa_name).hasPrefix("utun") else { continue }
            let ipv4 = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr.s_addr.bigEndian }
            // 100.64.0.0/10: the carrier-grade range Tailscale hands out.
            guard ipv4 & 0xFFC0_0000 == 0x6440_0000 else { continue }
            return "\(ipv4 >> 24).\((ipv4 >> 16) & 0xFF).\((ipv4 >> 8) & 0xFF).\(ipv4 & 0xFF)"
        }
        return nil
    }

    static func macInfo() -> RemoteMacInfo {
        var size = 0
        var model = "Mac"
        if sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 {
            var buffer = [CChar](repeating: 0, count: size)
            if sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 { model = String(cString: buffer) }
        }
        let interval = UserDefaults.standard.integer(forKey: DefaultsKey.monitorInterval)
        return RemoteMacInfo(
            protocolVersion: RemoteMonitorProtocol.version,
            name: macName,
            model: model,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            cpuCores: ProcessInfo.processInfo.activeProcessorCount,
            memoryTotal: ProcessInfo.processInfo.physicalMemory,
            interval: Double(interval > 0 ? interval : 2)
        )
    }
}

/// Published state changes on the main thread, whichever thread asked.
private func onMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
}

extension RemotePairedPhone {
    /// The ids the keychain holds right now: a phone removed a moment ago is turned away
    /// even if its connection outlived the listener it came through.
    static var knownIDs: Set<String> { Set(RemotePairingStore.phones().map(\.id)) }
}

extension SystemMonitorPanelNeeds {
    /// Everything the phone shows: usage, temperatures, memory, network, disks, power and fans.
    static let remoteReadings = SystemMonitorPanelNeeds(
        system: true, network: true, disk: true, power: true, cpu: true, gpu: true, memory: true, battery: true,
        cpuTemperature: true, gpuTemperature: true, batteryTemperature: true, fanSpeed: true
    )
}

/// `SystemSnapshot` → the protocol's values, field by field: the monitor's own
/// types stay free to change without changing what a phone reads.
enum RemoteMonitorBridge {
    static func snapshot(_ snapshot: SystemSnapshot) -> RemoteSnapshot {
        RemoteSnapshot(
            time: Date(),
            cpuUsage: snapshot.cpuUsage,
            cpuCoreUsage: snapshot.cpuCoreUsage,
            gpuUsage: snapshot.gpuUsage,
            cpuTemperature: snapshot.cpuTemperature,
            gpuTemperature: snapshot.gpuTemperature,
            batteryTemperature: snapshot.batteryTemperature,
            memoryUsed: snapshot.memoryUsed,
            memoryAppUsed: snapshot.memoryAppUsed,
            memoryTotal: snapshot.memoryTotal,
            memoryCompressed: snapshot.memoryCompressed,
            memoryCached: snapshot.memoryCached,
            memorySwapUsed: snapshot.memorySwapUsed,
            memoryPressure: pressure(snapshot.memoryPressure),
            fanSpeeds: snapshot.fanSpeeds,
            networkDownBytesPerSec: snapshot.netDownBytesPerSec,
            networkUpBytesPerSec: snapshot.netUpBytesPerSec,
            networkTotalDown: snapshot.netTotalDown,
            networkTotalUp: snapshot.netTotalUp,
            power: snapshot.power.map { power in
                RemotePower(systemWatts: power.systemWatts, adapterWatts: power.adapterWatts, batteryWatts: power.batteryWatts,
                            chargePercent: power.chargePercent, timeRemainingSeconds: power.timeRemainingSeconds,
                            healthPercent: power.healthPercent, cycleCount: power.cycleCount, isCharging: power.isCharging,
                            externalConnected: power.externalConnected, hasBattery: power.hasBattery)
            },
            disks: (snapshot.disk?.devices ?? []).map { device in
                RemoteDisk(name: device.name, totalBytes: device.totalBytes, usedBytes: device.usedBytes,
                           readBytesPerSec: device.readBytesPerSec, writeBytesPerSec: device.writeBytesPerSec,
                           isInternal: device.isInternal)
            }
        )
    }

    static func history(_ snapshot: SystemSnapshot) -> RemoteHistory {
        let interval = UserDefaults.standard.integer(forKey: DefaultsKey.monitorInterval)
        return RemoteHistory(interval: Double(interval > 0 ? interval : 2), cpu: snapshot.cpuHistory, gpu: snapshot.gpuHistory,
                             memory: snapshot.memoryHistory, networkDown: snapshot.netDownHistory,
                             networkUp: snapshot.netUpHistory, power: snapshot.systemPowerHistory)
    }

    static func pressure(_ pressure: MemoryPressure) -> String {
        switch pressure {
        case .normal: return "normal"
        case .warning: return "warning"
        case .critical: return "critical"
        case .unknown: return "unknown"
        }
    }
}
