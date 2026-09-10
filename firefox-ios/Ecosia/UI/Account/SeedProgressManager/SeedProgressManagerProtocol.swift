// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol SeedProgressManagerProtocol {
    static var progressUpdatedNotification: Notification.Name { get }
    static var levelUpNotification: Notification.Name { get }
    static var seedCounterConfig: SeedCounterConfig? { get set }

    static func loadCurrentLevel() -> Int
    static func loadTotalSeedsCollected() -> Int
    static func loadLastAppOpenDate() -> Date?

    static func saveProgress(totalSeeds: Int, currentLevel: Int, lastAppOpenDate: Date)

    static func addSeeds(_ count: Int, relativeToDate date: Date)
    static func resetLocalSeedProgress()

    static func calculateInnerProgress() -> CGFloat
    static func collectDailySeed()
}

extension SeedProgressManagerProtocol {
    /// Logged-out counterpart to `LoggedInImpactCacheProtocol.load(forUserId:)`: same `ImpactSnapshot`
    /// shape, computed from local state instead of a cached server value, since logged-out users
    /// don't have one. Composed entirely from the load methods above, so no conforming type needs
    /// to implement this itself.
    public static func currentSnapshot() -> ImpactSnapshot {
        ImpactSnapshot(
            seedCount: loadTotalSeedsCollected(),
            currentLevelNumber: loadCurrentLevel(),
            currentProgress: Double(calculateInnerProgress())
        )
    }

    /// Shared vocabulary with `LoggedInImpactCacheProtocol.clearOnLogout()`.
    public static func clearOnLogout() {
        resetLocalSeedProgress()
    }
}
