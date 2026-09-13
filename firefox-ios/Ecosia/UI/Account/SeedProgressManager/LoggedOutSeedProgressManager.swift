// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Owns the logged-out local seed lifecycle - adding (day-gated or debug-forced) and resetting -
/// through an injected `ImpactCacheProtocol`. Logged-out users are capped at
/// `maxSeedsForLoggedOutUsers` and always remain at level 1 (no level progression).
public final class LoggedOutSeedProgressManager: @unchecked Sendable {

    public static let maxSeedsForLoggedOutUsers = 3
    private static let lastAppOpenDateKey = "LastAppOpenDate"

    private let cache: ImpactCacheProtocol
    nonisolated(unsafe) public var seedCounterConfig: SeedCounterConfig?
    private var seedLevels: [SeedCounterConfig.SeedLevel] { seedCounterConfig?.levels.compactMap { $0 } ?? [] }

    public init(cache: ImpactCacheProtocol) {
        self.cache = cache
    }

    /// Reads the current snapshot, or a zeroed default if nothing's stored yet. A pure read - it
    /// never writes to the cache.
    public func load() -> ImpactSnapshot {
        reconciled(cache.load() ?? .zero)
    }

    /// Guest progress is config-driven (`seedCounterConfig` can change remotely) and must stay
    /// live, so it's always recomputed rather than trusted from the cache. The seed count is
    /// also clamped and the level forced to 1 here, not just when writing - the cache is shared
    /// with the logged-in path, so a snapshot read back must never expose more than a logged-out
    /// user is allowed to have.
    private func reconciled(_ snapshot: ImpactSnapshot) -> ImpactSnapshot {
        let cappedSeedCount = min(snapshot.seedCount, Self.maxSeedsForLoggedOutUsers)
        return ImpactSnapshot(
            seedCount: cappedSeedCount,
            currentLevelNumber: 1,
            currentProgress: Double(calculateInnerProgress(seedCount: cappedSeedCount))
        )
    }

    /// Collects today's seed if due (once per day, capped), returning the resulting snapshot and
    /// how much the seed count increased by (`nil` if nothing changed, e.g. already collected today).
    public func collectDailySeedIfDue() -> (snapshot: ImpactSnapshot, increment: Int?) {
        let current = load()
        let lastAppOpenDate = UserDefaults.standard.object(forKey: Self.lastAppOpenDateKey) as? Date
        guard shouldCollectDailySeed(lastAppOpenDate: lastAppOpenDate) else {
            return (current, nil)
        }

        let newCount = cappedSeedCount(adding: 1, to: current.seedCount)
        let snapshot = save(seedCount: newCount)
        UserDefaults.standard.set(Date(), forKey: Self.lastAppOpenDateKey)
        return (snapshot, newCount > current.seedCount ? newCount - current.seedCount : nil)
    }

    /// Debug-only: force-adds `count` seeds directly, bypassing the once-per-day gate, so QA can
    /// rapid-test the seed/level UI without waiting a day between taps. Returns the resulting
    /// snapshot and how much the seed count actually increased by.
    @discardableResult
    public func addDebugSeeds(_ count: Int) -> (snapshot: ImpactSnapshot, increment: Int) {
        let current = load()
        let newCount = cappedSeedCount(adding: count, to: current.seedCount)
        let snapshot = save(seedCount: newCount)
        return (snapshot, newCount - current.seedCount)
    }

    /// Clears the cache and the last-app-open date. Only called on logout or local data deletion.
    public func reset() {
        cache.clearOnLogout()
        UserDefaults.standard.removeObject(forKey: Self.lastAppOpenDateKey)
    }

    @discardableResult
    private func save(seedCount: Int) -> ImpactSnapshot {
        let snapshot = ImpactSnapshot(
            seedCount: seedCount,
            currentLevelNumber: 1,
            currentProgress: Double(calculateInnerProgress(seedCount: seedCount))
        )
        cache.save(snapshot)
        return snapshot
    }

    private func shouldCollectDailySeed(lastAppOpenDate: Date?) -> Bool {
        guard let lastAppOpenDate else { return true }
        return !Calendar.current.isDateInToday(lastAppOpenDate)
    }

    private func cappedSeedCount(adding count: Int, to currentSeedCount: Int) -> Int {
        min(currentSeedCount + count, Self.maxSeedsForLoggedOutUsers)
    }

    /// Returns the seed threshold required for a specific level.
    ///
    /// - Parameter level: The level to query.
    /// - Returns: The number of seeds required for the level, or 0 if not found.
    private func requiredSeedsForLevel(_ level: Int) -> Int {
        if let seedLevel = seedLevels.first(where: { $0.level == level }) {
            return seedLevel.requiredSeeds
        }
        return seedLevels.first?.requiredSeeds ?? 0  // If the is no level matching, use the first one
    }

    /// Calculates the inner progress for level 1 as a fraction from 0 to 1, given a seed count.
    ///
    /// - Returns: A value between 0.0 and 1.0 representing progress within level 1.
    public func calculateInnerProgress(seedCount: Int) -> CGFloat {
        // Find the level config where total seeds fall in the range of the current level and the next level
        guard let currentLevelConfig = seedLevels.first(where: { level in
            let previousLevelSeeds = level.level > 1 ? requiredSeedsForLevel(level.level - 1) : 0
            let nextLevelSeeds = requiredSeedsForLevel(level.level)
            return seedCount > previousLevelSeeds && seedCount <= nextLevelSeeds
        }) else {
            return 0.0 // Default to 0 if no valid level is found
        }

        let previousLevelSeeds = currentLevelConfig.level > 1 ? requiredSeedsForLevel(currentLevelConfig.level - 1) : 0
        let progressInCurrentLevel = seedCount - previousLevelSeeds
        let requiredSeedsForCurrentLevel = currentLevelConfig.requiredSeeds - previousLevelSeeds

        // Return progress as a fraction (between 0 and 1)
        return CGFloat(progressInCurrentLevel) / CGFloat(requiredSeedsForCurrentLevel)
    }
}
