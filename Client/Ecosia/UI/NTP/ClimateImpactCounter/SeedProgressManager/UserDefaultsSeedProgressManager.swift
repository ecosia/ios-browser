// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class UserDefaultsSeedProgressManager: SeedProgressManagerProtocol {
    
    private static let className = String(describing: SeedCounterNTPExperiment.progressManagerType.self)
    static var progressUpdatedNotification: Notification.Name { .init("\(className).SeedProgressUpdated") }
    static var levelUpNotification: Notification.Name { .init("\(className).SeedLevelUp") }
    private static let numberOfSeedsAtStart = 1
    
    // UserDefaults keys
    private static let totalSeedsCollectedKey = "TotalSeedsCollected"
    private static let currentLevelKey = "CurrentLevel"
    private static let lastAppOpenDateKey = "LastAppOpenDate"
    
    static var seedLevels: [SeedLevelConfig.SeedLevel] = SeedCounterNTPExperiment.seedLevelConfig?.levels.compactMap { $0 } ?? []
    
    private init() {}
    
    // MARK: - Static Methods

    // Load the current level from UserDefaults
    static func loadCurrentLevel() -> Int {
        let currentLevel = UserDefaults.standard.integer(forKey: currentLevelKey)
        return currentLevel == 0 ? 1 : currentLevel
    }

    // Load the total seeds collected from UserDefaults
    static func loadTotalSeedsCollected() -> Int {
        let seedsCollected = UserDefaults.standard.integer(forKey: totalSeedsCollectedKey)
        return seedsCollected == 0 ? numberOfSeedsAtStart : seedsCollected
    }

    // Load the last app open date from UserDefaults
    static func loadLastAppOpenDate() -> Date {
        return UserDefaults.standard.object(forKey: lastAppOpenDateKey) as? Date ?? .now
    }
    
    // Save the seed progress and level to UserDefaults
    static func saveProgress(totalSeeds: Int, currentLevel: Int, lastAppOpenDate: Date) {
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
        return seedLevels.last?.requiredSeeds ?? 0  // If the level exceeds defined levels, use the last one
    }

    // Calculate the inner progress for the current level (0 to 1)
    static func calculateInnerProgress() -> CGFloat {
        let totalSeeds = loadTotalSeedsCollected()
        let currentLevel = loadCurrentLevel()
        
        // Get the required seeds for the current level
        let thresholdForCurrentLevel = requiredSeedsForLevel(currentLevel)
        
        // Seeds needed to reach the current level
        let previousLevelTotal = currentLevel > 1 ? requiredSeedsForLevel(currentLevel - 1) : 0
        
        // Inner progress is calculated between the seeds collected in the current level
        let seedsForCurrentLevel = totalSeeds - previousLevelTotal
        return CGFloat(seedsForCurrentLevel) / CGFloat(thresholdForCurrentLevel)
    }
    
    // Add seeds to the counter and handle level progression
    static func addSeeds(_ count: Int) {
        addSeeds(count, relativeToDate: loadLastAppOpenDate())
    }

    // Add seeds to the counter with a specificed date
    static func addSeeds(_ count: Int, relativeToDate date: Date) {
        var totalSeeds = loadTotalSeedsCollected()
        var currentLevel = loadCurrentLevel()

        let previousLevelTotal = currentLevel > 1 ? requiredSeedsForLevel(currentLevel - 1) : 0
        let thresholdForCurrentLevel = requiredSeedsForLevel(currentLevel)

        totalSeeds += count

        var leveledUp = false
        // Only level up if the total seeds EXCEED the threshold for the current level
        if totalSeeds > previousLevelTotal + thresholdForCurrentLevel {
            if currentLevel < seedLevels.count {
                currentLevel += 1
                leveledUp = true
            }
        }

        saveProgress(totalSeeds: totalSeeds, currentLevel: currentLevel, lastAppOpenDate: date)

        // Notify listeners if leveled up
        if leveledUp {
            NotificationCenter.default.post(name: levelUpNotification, object: nil)
        }
    }
    
    // Reset the counter to the initial state
    static func resetCounter() {
        saveProgress(totalSeeds: numberOfSeedsAtStart,
                     currentLevel: 1,
                     lastAppOpenDate: .now)
    }

    // Collect a seed once per day
    static func collectDailySeed() {
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
