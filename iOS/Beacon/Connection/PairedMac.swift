// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Security

/// A Mac this phone may read: where to find it and the key it gave this phone.
struct PairedMac: Codable, Identifiable, Hashable, Sendable {
    /// The pairing's id: the TLS identity this phone presents to that Mac.
    var id: String
    var name: String
    var host: String
    var alternateHost: String?
    var port: UInt16
    var key: Data
    var addedAt: Date

    init(pairing: RemotePairing, addedAt: Date = .now) {
        id = pairing.id
        name = pairing.name
        host = pairing.host
        alternateHost = pairing.alternateHost
        port = pairing.port
        key = pairing.key
        self.addedAt = addedAt
    }

    /// Where to try, in order: the Mac's name on this network, then the address away from home.
    var hosts: [String] { [host] + (alternateHost.map { [$0] } ?? []) }
}

/// The paired Macs, one keychain item each, readable after the phone's first
/// unlock and never synced to iCloud: a key stays on the phone it was given to.
enum PairingStore {
    private static let service = "co.ikili.beacon.macs"

    static func all() -> [PairedMac] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnData as String: true,
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let items = result as? [Data] else { return [] }
        return items.compactMap { try? JSONDecoder().decode(PairedMac.self, from: $0) }.sorted { $0.addedAt < $1.addedAt }
    }

    @discardableResult
    static func save(_ mac: PairedMac) -> Bool {
        guard let data = try? JSONEncoder().encode(mac) else { return false }
        let match: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: mac.id,
        ]
        if SecItemUpdate(match as CFDictionary, [kSecValueData as String: data] as CFDictionary) == errSecSuccess { return true }
        var add = match
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func remove(id: String) {
        let match: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id,
        ]
        SecItemDelete(match as CFDictionary)
    }
}
