// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class SeedProgressManager {
    
    static let progressUpdatedNotification = Notification.Name("SeedProgressUpdated")
    
    // UserDefaults keys
    private static let levelKey = "SeedProgressLevel"
    private static let seedsCollectedKey = "SeedsCollected"
    private static let lastAppOpenDateKey = "LastAppOpenDate"
    
    private static let level1Threshold = 5
    private static let level2Threshold = 7
    
    private init() {}
    
    // MARK: - Static Methods

    // Load the current level from UserDefaults
    static func loadLevel() -> Int {
        return UserDefaults.standard.integer(forKey: levelKey) == 0 ? 1 : UserDefaults.standard.integer(forKey: levelKey)
    }

    // Load the seeds collected from UserDefaults
    static func loadSeedsCollected() -> Int {
        return UserDefaults.standard.integer(forKey: seedsCollectedKey) == 0 ? 1 : UserDefaults.standard.integer(forKey: seedsCollectedKey)
    }

    // Load the last app open date from UserDefaults
    static func loadLastAppOpenDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastAppOpenDateKey) as? Date
    }

    // Save the seed progress and level to UserDefaults
    static func saveProgress(level: Int, seedsCollected: Int, lastAppOpenDate: Date?) {
        let defaults = UserDefaults.standard
        defaults.set(level, forKey: levelKey)
        defaults.set(seedsCollected, forKey: seedsCollectedKey)
        if let date = lastAppOpenDate {
            defaults.set(date, forKey: lastAppOpenDateKey)
        }
        NotificationCenter.default.post(name: progressUpdatedNotification, object: nil)
    }

    // Add seeds to the counter
    static func addSeeds(_ count: Int) {
        var level = loadLevel()
        var seedsCollected = loadSeedsCollected()

        // Increment the seeds collected by the specified count
        seedsCollected += count

        // Handle level progression logic
        if level == 1 && seedsCollected >= level1Threshold {
            level = 2
            seedsCollected = 0
        } else if level == 2 && seedsCollected >= level2Threshold {
            seedsCollected = level2Threshold // Cap at level 2
        }

        // Save the updated progress
        saveProgress(level: level, seedsCollected: seedsCollected, lastAppOpenDate: loadLastAppOpenDate())
    }

    // Reset the counter to the initial state
    static func resetCounter() {
        saveProgress(level: 1, seedsCollected: 1, lastAppOpenDate: nil)
    }

    // Calculate progress value (0 to 1) based on current level and seeds collected
    static func calculateProgress() -> CGFloat {
        let level = loadLevel()
        let seedsCollected = loadSeedsCollected()
        let currentThreshold = (level == 1) ? level1Threshold : level2Threshold
        
        if level == 1 || level == 2 {
            return CGFloat(seedsCollected) / CGFloat(currentThreshold)
        }
        return 1.0
    }
    
    // Collect a seed once per day
    static func collectSeed() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        if let lastOpenDate = loadLastAppOpenDate(), calendar.isDateInToday(lastOpenDate) {
            // Seed already collected today, do nothing
            return
        }
        
        // Add 1 seed and save the last open date as today
        addSeeds(1)
        saveProgress(level: loadLevel(), seedsCollected: loadSeedsCollected(), lastAppOpenDate: currentDate)
    }
}
