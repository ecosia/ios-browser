// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manages local seed collection and progression for logged-out users.
///
/// This manager persists seed progress locally using `UserDefaults` and is intended
/// exclusively for tracking seeds collected by users who are not logged in. When users
/// log in, their seed progress is managed server-side through the account system.
///
/// ## Local Storage
///
/// The manager stores three key values in `UserDefaults`:
/// - Total seeds collected since first app launch
/// - Current level based on seed thresholds
/// - Last app open date for daily seed collection
///
/// ## Level Progression
///
/// Seed levels and thresholds are configured via `SeedCounterConfig`, which can be
/// remotely configured. The manager automatically handles level-up transitions when
/// seed thresholds are met and posts notifications for UI updates.
///
/// ## Important
///
/// This manager should only be used for logged-out users. Server-based seed management
/// takes precedence for authenticated users.
public final class UserDefaultsSeedProgressManager: SeedProgressManagerProtocol {

    private static let className = String(describing: UserDefaultsSeedProgressManager.self)
    private static let numberOfSeedsAtStart = 1
    public static let maxSeedsForLoggedOutUsers = 3
    public static var progressUpdatedNotification: Notification.Name { .init("\(className).SeedProgressUpdated") }
    public static var levelUpNotification: Notification.Name { .init("\(className).SeedLevelUp") }

    // UserDefaults keys
    private static let totalSeedsCollectedKey = "TotalSeedsCollected"
    private static let currentLevelKey = "CurrentLevel"
    private static let lastAppOpenDateKey = "LastAppOpenDate"

    public static var seedCounterConfig: SeedCounterConfig?
    private static var seedLevels: [SeedCounterConfig.SeedLevel] { seedCounterConfig?.levels.compactMap { $0 } ?? [] }

    // Fetch max level and max seeds from remote configuration if provided
    private static let maxCappedLevel = seedCounterConfig?.maxCappedLevel
    private static let maxCappedSeeds = seedCounterConfig?.maxCappedSeeds

    private init() {}

    // MARK: - Static Methods

    // Load the current level from UserDefaults
    public static func loadCurrentLevel() -> Int {
        let currentLevel = UserDefaults.standard.integer(forKey: currentLevelKey)
        return currentLevel == 0 ? 1 : currentLevel
    }

    // Load the total seeds collected from UserDefaults
    public static func loadTotalSeedsCollected() -> Int {
        let seedsCollected = UserDefaults.standard.integer(forKey: totalSeedsCollectedKey)
        return seedsCollected == 0 ? numberOfSeedsAtStart : seedsCollected
    }

    // Load the last app open date from UserDefaults
    public static func loadLastAppOpenDate() -> Date {
        return UserDefaults.standard.object(forKey: lastAppOpenDateKey) as? Date ?? .now
    }

    // Save the seed progress and level to UserDefaults
    public static func saveProgress(totalSeeds: Int, currentLevel: Int, lastAppOpenDate: Date) {
        let defaults = UserDefaults.standard
        defaults.set(totalSeeds, forKey: totalSeedsCollectedKey)
        defaults.set(currentLevel, forKey: currentLevelKey)
        defaults.set(lastAppOpenDate, forKey: lastAppOpenDateKey)
        NotificationCenter.default.post(name: progressUpdatedNotification, object: nil)
    }

    // Helper method to get the seed threshold for the current level
    private static func requiredSeedsForLevel(_ level: Int) -> Int {
        if let seedLevel = seedLevels.first(where: { $0.level == level }) {
            return seedLevel.requiredSeeds
        }
        return seedLevels.first?.requiredSeeds ?? 0  // If the is no level matching, use the first one
    }

    // Calculate the inner progress for the current level (0 to 1)
    public static func calculateInnerProgress() -> CGFloat {
        let totalSeeds = loadTotalSeedsCollected()

        // Find the level config where total seeds fall in the range of the current level and the next level
        guard let currentLevelConfig = seedLevels.first(where: { level in
            let previousLevelSeeds = level.level > 1 ? requiredSeedsForLevel(level.level - 1) : 0
            let nextLevelSeeds = requiredSeedsForLevel(level.level)
            return totalSeeds > previousLevelSeeds && totalSeeds <= nextLevelSeeds
        }) else {
            return 0.0 // Default to 0 if no valid level is found
        }

        let previousLevelSeeds = currentLevelConfig.level > 1 ? requiredSeedsForLevel(currentLevelConfig.level - 1) : 0
        let progressInCurrentLevel = totalSeeds - previousLevelSeeds
        let requiredSeedsForCurrentLevel = currentLevelConfig.requiredSeeds - previousLevelSeeds

        // Return progress as a fraction (between 0 and 1)
        return CGFloat(progressInCurrentLevel) / CGFloat(requiredSeedsForCurrentLevel)
    }

    // Add seeds to the counter and handle level progression
    public static func addSeeds(_ count: Int) {
        addSeeds(count, relativeToDate: loadLastAppOpenDate())
    }

    // Add seeds to the counter with a specific date
    public static func addSeeds(_ count: Int, relativeToDate date: Date) {
        // Load total seeds
        var totalSeeds = loadTotalSeedsCollected()

        EcosiaLogger.accounts.info("Seed cap enforced for logged-out user: max \(maxSeedsForLoggedOutUsers) seeds")

        if totalSeeds >= maxSeedsForLoggedOutUsers {
            return
        }

        totalSeeds += count

        if totalSeeds >= maxSeedsForLoggedOutUsers {
            totalSeeds = maxSeedsForLoggedOutUsers
        }

        saveProgress(totalSeeds: totalSeeds, currentLevel: 1, lastAppOpenDate: date)
        NotificationCenter.default.post(name: progressUpdatedNotification, object: nil)
    }

    // Reset the counter to the initial state
    public static func resetCounter() {
        saveProgress(totalSeeds: numberOfSeedsAtStart,
                     currentLevel: 1,
                     lastAppOpenDate: .now)
    }

    // Collect a seed once per day
    public static func collectDailySeed() {
        let currentDate = Date()
        let lastOpenDate = loadLastAppOpenDate()
        let calendar = Calendar.current

        if calendar.isDateInToday(lastOpenDate) {
            return // Seed already collected today
        }

        // Add 1 seed and save the last open date as today
        addSeeds(1, relativeToDate: currentDate)
    }
}
