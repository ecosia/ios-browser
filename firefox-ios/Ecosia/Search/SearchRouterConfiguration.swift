// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Resolves `SearchRouterConfig` from the `mob_ios_custom_search_provider` variant payload.
///
/// Cached against the raw payload string: analytics reads this for every structured event,
/// so it must not decode per call. Snowplow tracks off the main thread, hence the lock.
public enum SearchRouterConfiguration {

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cachedPayload: String?
    nonisolated(unsafe) private static var cachedConfig = SearchRouterConfig.default
    nonisolated(unsafe) private static var hasResolved = false

    /// Only `json` payloads are read; any other type is treated as absent.
    private static let jsonPayloadType = "json"

    public static var current: SearchRouterConfig {
        let payload = Unleash.getVariant(.customSearchProvider).payload
        let rawValue = payload?.type == jsonPayloadType ? payload?.value : nil

        lock.lock()
        defer { lock.unlock() }

        guard !hasResolved || rawValue != cachedPayload else { return cachedConfig }

        let decoded = SearchRouterConfig(payload: rawValue)
        let config = decoded ?? .default
        cachedPayload = rawValue
        cachedConfig = config
        hasResolved = true

        if rawValue != nil, decoded == nil {
            EcosiaLogger.featureFlags.error("Search router payload could not be decoded, using default config")
        }
        EcosiaLogger.featureFlags.info(
            "Search router config: aiMode=\(config.aiMode.rawValue), "
            + "providers=[\(config.providers.map(\.rawValue).joined(separator: ", "))]"
        )

        return config
    }

    /// Drops the cache. Used by tests and by the debug Unleash reset.
    public static func invalidateCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedPayload = nil
        cachedConfig = .default
        hasResolved = false
    }
}
