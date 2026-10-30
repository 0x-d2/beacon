// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import Security

/// One phone allowed to read this Mac: its id (the TLS identity it presents),
/// the name it gave, and its own pre-shared key.
struct RemotePairedPhone: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    let key: Data
    let pairedAt: Date
    var lastSeen: Date?
}

/// The paired phones, each a generic password in the login keychain under
/// this build's bundle id, so the developer variant keeps its own. A phone
/// removed here can no longer connect: its key is gone from the listener.
enum RemotePairingStore {
    private static var service: String {
        "\(Bundle.main.bundleIdentifier ?? "com.vorssaint.utils").remote-monitor"
    }

    static func phones() -> [RemotePairedPhone] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let items = result as? [[String: Any]] else { return [] }
        let decoder = JSONDecoder()
        return items.compactMap { item in
            (item[kSecValueData as String] as? Data).flatMap { try? decoder.decode(RemotePairedPhone.self, from: $0) }
        }
        .sorted { $0.pairedAt < $1.pairedAt }
    }

    @discardableResult
    static func save(_ phone: RemotePairedPhone) -> Bool {
        guard let data = try? JSONEncoder().encode(phone) else { return false }
        let match: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: phone.id,
        ]
        if SecItemUpdate(match as CFDictionary, [kSecValueData as String: data] as CFDictionary) == errSecSuccess {
            return true
        }
        var add = match
        add[kSecValueData as String] = data
        add[kSecAttrLabel as String] = "Beacon · \(phone.name)"
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

    /// A new phone's id and key: random, never derived from anything on the Mac.
    static func newCredentials() -> (id: String, key: Data)? {
        var bytes = [UInt8](repeating: 0, count: RemoteMonitorProtocol.keyLength)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { return nil }
        return (UUID().uuidString.lowercased(), Data(bytes))
    }
}
