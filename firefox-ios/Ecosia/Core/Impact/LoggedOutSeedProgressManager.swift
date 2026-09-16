// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Owns the logged-out local seed lifecycle - adding (day-gated or debug-forced) and resetting -
/// through the shared `ImpactCacheProtocol`. Logged-out users are capped at
/// `maxSeedsForLoggedOutUsers` and always remain at level 1 (no level progression).
///
/// Self-contained: every write goes through `ImpactCacheProtocol.save`, which itself posts
/// `.EcosiaImpactCacheUpdated` - callers just need to trigger `collectDailySeedIfDue()` (e.g. on
/// NTP appear / foreground) rather than orchestrate reading the result back out.
public final class LoggedOutSeedProgressManager: @unchecked Sendable {

    public static let maxSeedsForLoggedOutUsers = 3

    /// Convenience shared instance for simple call sites (debug menu, nav button) that don't need
    /// their own injected cache.
    public static let shared = LoggedOutSeedProgressManager(cache: ImpactCache())

    private static let lastAppOpenDateKey = "LoggedOutSeedProgressManager.lastAppOpenDate"

    private let cache: ImpactCacheProtocol
    private let authenticationService: EcosiaAuthenticationService
    nonisolated(unsafe) public var seedCounterConfig: SeedCounterConfig?
    private var seedLevels: [SeedCounterConfig.SeedLevel] { seedCounterConfig?.levels.compactMap { $0 } ?? [] }

    public init(cache: ImpactCacheProtocol, authenticationService: EcosiaAuthenticationService = .shared) {
        self.cache = cache
        self.authenticationService = authenticationService
    }

    /// Reads the current snapshot, or a zeroed default if nothing's stored yet, or if the shared
    /// slot currently holds a logged-in user's data instead of the guest's own. A pure read - it
    /// never writes to the cache.
    public func load() -> ImpactSnapshot {
        guard let cached = cache.load(), cached.loggedInUserID == nil else {
            return reconciled(.loggedOutZero)
        }
        return reconciled(cached)
    }

    /// Guest progress is config-driven (`seedCounterConfig` can change remotely) and must stay
    /// live, so it's always recomputed rather than trusted from the cache. The seed count is also
    /// clamped and the level forced to 1 here, not just when writing - the cache is shared with the
    /// logged-in path, so a snapshot read back must never expose more than a logged-out user is
    /// allowed to have.
    private func reconciled(_ snapshot: ImpactSnapshot) -> ImpactSnapshot {
        let cappedSeedCount = min(snapshot.seedCount, Self.maxSeedsForLoggedOutUsers)
        return ImpactSnapshot(
            seedCount: cappedSeedCount,
            currentLevelNumber: 1,
            currentProgress: Double(calculateInnerProgress(seedCount: cappedSeedCount)),
            loggedInUserID: nil
        )
    }

    /// Collects today's seed if due (once per day, capped). A no-op while actually logged in -
    /// defense in depth alongside `LoggedInImpactUpdater`'s own identity check, in case a caller
    /// ever invokes this while a user is genuinely logged in (e.g. off a stale check of its own).
    public func collectDailySeedIfDue() {
        guard !authenticationService.isLoggedIn else {
            EcosiaLogger.accounts.notice("Skipping local seed collection - a user is actually logged in")
            return
        }

        let current = load()
        let lastAppOpenDate = UserDefaults.standard.object(forKey: Self.lastAppOpenDateKey) as? Date
        guard shouldCollectDailySeed(lastAppOpenDate: lastAppOpenDate) else { return }

        let newCount = cappedSeedCount(adding: 1, to: current.seedCount)
        let increment = newCount - current.seedCount
        save(seedCount: newCount, seedsIncrement: increment > 0 ? increment : nil)
        UserDefaults.standard.set(Date(), forKey: Self.lastAppOpenDateKey)
    }

    /// Debug-only: force-adds `count` seeds directly, bypassing the once-per-day gate, so QA can
    /// rapid-test the seed/level UI without waiting a day between taps. A no-op while actually
    /// logged in, for the same reason as `collectDailySeedIfDue()`.
    @discardableResult
    public func addDebugSeeds(_ count: Int) -> ImpactSnapshot {
        guard !authenticationService.isLoggedIn else {
            EcosiaLogger.accounts.notice("Skipping debug seed add - a user is actually logged in")
            return load()
        }

        let current = load()
        let newCount = cappedSeedCount(adding: count, to: current.seedCount)
        let increment = newCount - current.seedCount
        return save(seedCount: newCount, seedsIncrement: increment > 0 ? increment : nil)
    }

    /// Resets to a fresh guest snapshot (0 seeds, level 1) and clears the last-app-open date, so
    /// the next `collectDailySeedIfDue()` collects immediately. Called on logout - overwrites
    /// whatever the logged-in path left behind and, via `cache.save`, notifies observers right away.
    /// Never animated - this is a reset, not an earned seed.
    public func reset() {
        UserDefaults.standard.removeObject(forKey: Self.lastAppOpenDateKey)
        save(seedCount: 0, seedsIncrement: nil)
    }

    /// For testing: clears the last-app-open-date key directly, so tests don't leak one test's
    /// daily-collection state into another via real `UserDefaults` (the cache itself is already
    /// injectable per test; this key is the one piece of state that isn't).
    func resetLastAppOpenDateForTesting() {
        UserDefaults.standard.removeObject(forKey: Self.lastAppOpenDateKey)
    }

    @discardableResult
    private func save(seedCount: Int, seedsIncrement: Int?) -> ImpactSnapshot {
        let snapshot = ImpactSnapshot(
            seedCount: seedCount,
            currentLevelNumber: 1,
            currentProgress: Double(calculateInnerProgress(seedCount: seedCount)),
            loggedInUserID: nil
        )
        cache.save(snapshot, seedsIncrement: seedsIncrement, didLevelUp: false)
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
    private func requiredSeedsForLevel(_ level: Int) -> Int {
        if let seedLevel = seedLevels.first(where: { $0.level == level }) {
            return seedLevel.requiredSeeds
        }
        return seedLevels.first?.requiredSeeds ?? 0  // If there is no level matching, use the first one
    }

    /// Calculates the inner progress for level 1 as a fraction from 0 to 1, given a seed count.
    public func calculateInnerProgress(seedCount: Int) -> CGFloat {
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

        return CGFloat(progressInCurrentLevel) / CGFloat(requiredSeedsForCurrentLevel)
    }
}
