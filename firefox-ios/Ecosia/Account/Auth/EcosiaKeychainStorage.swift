import Foundation
import Security
import Auth0

/// A Keychain-based implementation of CredentialsStorage.
public class EcosiaKeychainStorage: CredentialsStorage {

    private let service: String

    /// Initializes a new instance of KeychainStorage.
    ///
    /// - Parameter service: The service identifier for the Keychain entries.
    public init(service: String = "EcosiaAuthCredentials") {
        self.service = service
    }

    /// Retrieves a storage entry.
    ///
    /// - Parameter key: The key to get from the Keychain.
    /// - Returns: The stored data, or nil if not found.
    public func getEntry(forKey key: String) -> Data? {
        var query = keychainQuery(withKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)

        if status == errSecSuccess {
            return itemCopy as? Data
        } else {
            return nil
        }
    }

    /// Sets a storage entry.
    ///
    /// - Parameters:
    ///   - data: The data to be stored.
    ///   - key: The key to store it to.
    /// - Returns: A boolean indicating if the data was stored successfully.
    public func setEntry(_ data: Data, forKey key: String) -> Bool {
        var query = keychainQuery(withKey: key)

        let attributes: [String: Any] = [kSecValueData as String: data]

        let status: OSStatus
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            // Item exists, update it
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            // Item doesn't exist, add it
            query.merge(attributes) { (_, new) in new }
            status = SecItemAdd(query as CFDictionary, nil)
        }

        return status == errSecSuccess
    }

    /// Deletes a storage entry.
    ///
    /// - Parameter key: The key to delete from the Keychain.
    /// - Returns: A boolean indicating if the data was deleted successfully.
    public func deleteEntry(forKey key: String) -> Bool {
        let query = keychainQuery(withKey: key)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Helper method to create a Keychain query dictionary.
    private func keychainQuery(withKey key: String) -> [String: Any] {
        var query: [String: Any] = [:]
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = key
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return query
    }
}
