// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct EnvironmentFetcher {

    private init() {}

    /// Fetches a string value associated with the specified key either from the Main Bundle Info Dictionary or the Process Info environment.
    ///
    /// - Parameters:
    ///   - key: The key for which to retrieve the associated string value.
    /// - Returns: The string value associated with the key, or nil if not found.
    public static func valueFromMainBundleOrProcessInfo(forKey key: String) -> String? {
        resolveValue(
            bundleValue: Bundle.main.object(forInfoDictionaryKey: key) as? String,
            processInfoValue: ProcessInfo.processInfo.environment[key]
        )
    }

    /// Resolves a configuration value, preferring a non-empty Main Bundle value and
    /// falling back to a non-empty Process Info value.
    ///
    /// An empty Main Bundle value is treated as absent: when an xcconfig variable is
    /// left unset the build substitutes an *empty string* (not a missing key) into
    /// Info.plist. The previous `?? ProcessInfo...` only fell through on `nil`, so an
    /// empty bundle value short-circuited the fallback and the function returned nil —
    /// fatal for callers like DefaultAuth0SettingsProvider.id. Treating empty as absent
    /// preserves the documented "Main Bundle OR Process Info" contract. Tracked in MOB-4384.
    static func resolveValue(bundleValue: String?, processInfoValue: String?) -> String? {
        if let bundleValue, !bundleValue.isEmpty {
            return bundleValue
        }
        if let processInfoValue, !processInfoValue.isEmpty {
            return processInfoValue
        }
        return nil
    }
}
