// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A point-in-time impact snapshot - seedCount/currentLevelNumber/currentProgress - regardless of
/// whether it came from the server (logged-in, via `LoggedInImpactCacheProtocol`) or was computed
/// locally (logged-out, via `SeedProgressManagerProtocol.currentSnapshot()`). `ImpactManager`
/// publishes these three values as flat properties either way, so the shape is shared on purpose.
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

/// A single, login-state-agnostic way to read the current impact snapshot: `ImpactManager` picks
/// whichever store's `.Type` is relevant and calls this, without branching on the call shape
/// itself - both `SeedProgressManagerProtocol` (userId ignored - one local slot, not per-account)
/// and `LoggedInImpactCacheProtocol` (userId required, nil short-circuits to `nil`) conform.
public protocol ImpactSnapshotReadable {
    static func currentSnapshot(forUserId userId: String?) -> ImpactSnapshot?
}

/// Persists the last known server-reported seed/level/progress for a logged-in user, so the UI can
/// show real numbers immediately on cold launch instead of the logged-out cap
/// (`UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers`) while a fresh value is fetched.
public protocol LoggedInImpactCacheProtocol: ImpactSnapshotReadable {
    /// Returns the cached snapshot, or `nil` if there is none or it belongs to a different user.
    static func load(forUserId userId: String) -> ImpactSnapshot?

    /// Persists a snapshot, tagged with the user it belongs to.
    static func save(_ snapshot: ImpactSnapshot, userId: String)

    /// Clears any cached snapshot, regardless of which user it belonged to.
    static func clear()
}

extension LoggedInImpactCacheProtocol {
    /// Shared vocabulary with `SeedProgressManagerProtocol.clearOnLogout()`: `ImpactManager`
    /// calls both stores by this same name on logout, without needing to know each store's own
    /// reason for clearing.
    public static func clearOnLogout() {
        clear()
    }
}

extension LoggedInImpactCacheProtocol {
    public static func currentSnapshot(forUserId userId: String?) -> ImpactSnapshot? {
        guard let userId else { return nil }
        return load(forUserId: userId)
    }
}
