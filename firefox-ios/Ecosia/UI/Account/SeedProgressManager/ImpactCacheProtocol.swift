// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A point-in-time impact snapshot - seedCount/currentLevelNumber/currentProgress - regardless of
/// whether it came from the server (logged-in) or was computed locally (logged-out)
public struct ImpactSnapshot: Equatable, Sendable {
    public let seedCount: Int
    public let currentLevelNumber: Int
    public let currentProgress: Double

    public init(seedCount: Int, currentLevelNumber: Int, currentProgress: Double) {
        self.seedCount = seedCount
        self.currentLevelNumber = currentLevelNumber
        self.currentProgress = currentProgress
    }

    /// The default snapshot for a user with no history yet: 0 seeds, level 1, no progress.
    static let zero = ImpactSnapshot(seedCount: 0, currentLevelNumber: 1, currentProgress: 0)
}

/// Persists the last known seed/level/progress, so the UI can show real numbers immediately on
/// cold launch instead of a placeholder while a fresh value is fetched (logged-in) or computed
/// (logged-out).
public protocol ImpactCacheProtocol: Sendable {
    /// Returns the cached snapshot, or `nil` if there is none.
    func load() -> ImpactSnapshot?

    /// Persists a snapshot.
    func save(_ snapshot: ImpactSnapshot)

    /// Clears any cached snapshot.
    func clear()
}

extension ImpactCacheProtocol {
    /// Named for its caller, `LoggedOutSeedProgressManager.reset()`, which only runs on logout or
    /// local data deletion.
    public func clearOnLogout() {
        clear()
    }
}
