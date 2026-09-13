// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A point-in-time impact snapshot - seedCount/currentLevelNumber/currentProgress - regardless of
/// whether it came from the server (logged-in) or was computed locally (logged-out, via
/// `SeedProgressManagerProtocol.currentSnapshot()`). `EcosiaAuthUIStateProvider` publishes these
/// three values as flat properties either way, so the shape is shared on purpose.
public struct ImpactSnapshot: Equatable {
    public let seedCount: Int
    public let currentLevelNumber: Int
    public let currentProgress: Double

    public init(seedCount: Int, currentLevelNumber: Int, currentProgress: Double) {
        self.seedCount = seedCount
        self.currentLevelNumber = currentLevelNumber
        self.currentProgress = currentProgress
    }
}

/// Persists the last known seed/level/progress for a single user id, so the UI can show real
/// numbers immediately on cold launch instead of a placeholder while a fresh value is fetched
/// (logged-in) or computed (logged-out, tagged with a fixed anonymous id).
public protocol ImpactCacheProtocol {
    /// Returns the cached snapshot, or `nil` if there is none or it belongs to a different user.
    static func load(forUserId userId: String) -> ImpactSnapshot?

    /// Persists a snapshot, tagged with the user it belongs to.
    static func save(_ snapshot: ImpactSnapshot, userId: String)

    /// Clears any cached snapshot, regardless of which user it belonged to.
    static func clear()
}

extension ImpactCacheProtocol {
    /// Shared vocabulary with `SeedProgressManagerProtocol.clearOnLogout()`: `EcosiaAuthUIStateProvider`
    /// calls both `loggedOutImpactCacheType` and `loggedInImpactCacheType` by this same name on
    /// logout, without needing to know that they route through the very same `UserDefaultsImpactCache`
    /// storage under the hood.
    public static func clearOnLogout() {
        clear()
    }
}
