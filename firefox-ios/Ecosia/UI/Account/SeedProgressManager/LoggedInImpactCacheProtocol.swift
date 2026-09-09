// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A cached snapshot of a logged-in user's last known server-reported impact stats.
public struct LoggedInImpactSnapshot: Equatable {
    public let seedCount: Int
    public let currentLevelNumber: Int
    public let currentProgress: Double

    public init(seedCount: Int, currentLevelNumber: Int, currentProgress: Double) {
        self.seedCount = seedCount
        self.currentLevelNumber = currentLevelNumber
        self.currentProgress = currentProgress
    }
}

/// Persists the last known server-reported seed/level/progress for a logged-in user, so the UI can
/// show real numbers immediately on cold launch instead of the logged-out cap
/// (`UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers`) while a fresh value is fetched.
public protocol LoggedInImpactCacheProtocol {
    /// Returns the cached snapshot, or `nil` if there is none or it belongs to a different user.
    static func load(forUserId userId: String) -> LoggedInImpactSnapshot?

    /// Persists a snapshot, tagged with the user it belongs to.
    static func save(_ snapshot: LoggedInImpactSnapshot, userId: String)

    /// Clears any cached snapshot, regardless of which user it belonged to.
    static func clear()
}
