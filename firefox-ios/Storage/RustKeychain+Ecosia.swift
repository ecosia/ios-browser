// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Ecosia: keychain helpers needed for the v133→v147 login migration.
// See RustLogins+EcosiaMigration.swift for context.

import Foundation

// Ecosia: default implementation so existing KeychainProtocol conformers are not source-broken
public extension KeychainProtocol {
    func legacyDataForKey(_ key: String) -> Data? { return nil }
}

extension RustKeychain {
    // Ecosia: queries keychain items written by the legacy MZKeychainWrapper (pre-v147).
    // Uses kSecAttrAccount as a plain String (matching MZKeychainWrapper's storage format) and
    // omits kSecAttrGeneric so it finds the original item rather than any newer RustKeychain item.
    public func legacyDataForKey(_ key: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.serviceName,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: false,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let accessGroup = self.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return data
    }
}
