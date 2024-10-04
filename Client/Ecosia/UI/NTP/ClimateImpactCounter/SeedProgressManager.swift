// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol SeedProgressManagerProtocol {
    static var progressUpdatedNotification: Notification.Name { get }
    static func loadCurrentLevel() -> Int
    static func loadTotalSeedsCollected() -> Int
    static func loadLastAppOpenDate() -> Date
    
    static func saveProgress(totalSeeds: Int, currentLevel: Int, lastAppOpenDate: Date)
    
    static func addSeeds(_ count: Int)
    static func resetCounter()
    
    static func calculateInnerProgress() -> CGFloat
    static func collectSeed()
}

final class UserDefaultsSeedProgressManager: SeedProgressManagerProtocol {    
    
    static var progressUpdatedNotification: Notification.Name { .init("SeedProgressUpdated") }
    private static let numberOfSeedsAtStart = 1
    
    // UserDefaults keys
    private static let totalSeedsCollectedKey = "TotalSeedsCollected"
    private static let currentLevelKey = "CurrentLevel"
    private static let lastAppOpenDateKey = "LastAppOpenDate"
    
    // Thresholds for each level
    private static let levelThresholds: [Int] = [5, 10] // Example thresholds for levels 1, 2
    
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

    // Calculate the seed threshold for the current level
    private static func seedThreshold(for level: Int) -> Int {
        return level <= levelThresholds.count ? levelThresholds[level - 1] : levelThresholds.last ?? 0
    }

    // Calculate the inner progress for the current level (0 to 1)
    static func calculateInnerProgress() -> CGFloat {
        let totalSeeds = loadTotalSeedsCollected()
        let currentLevel = loadCurrentLevel()
        let thresholdForCurrentLevel = seedThreshold(for: currentLevel)
        
        // Seeds needed to reach the current level
        let previousLevelTotal = currentLevel > 1 ? seedThreshold(for: currentLevel - 1) : 0
        
        // Inner progress is calculated between the seeds collected in the current level
        let seedsForCurrentLevel = totalSeeds - previousLevelTotal
        return CGFloat(seedsForCurrentLevel) / CGFloat(thresholdForCurrentLevel)
    }

    // Add seeds to the counter and handle level progression
    static func addSeeds(_ count: Int) {
        var totalSeeds = loadTotalSeedsCollected()
        var currentLevel = loadCurrentLevel()
        
        totalSeeds += count
        
        // Check if the new total seeds surpass the threshold for the current level
        while totalSeeds >= seedThreshold(for: currentLevel) {
            if currentLevel < levelThresholds.count {
                currentLevel += 1
            } else {
                break // Stay at the highest defined level
            }
        }
        
        saveProgress(totalSeeds: totalSeeds, currentLevel: currentLevel, lastAppOpenDate: loadLastAppOpenDate())
    }

    // Reset the counter to the initial state
    static func resetCounter() {
        saveProgress(totalSeeds: numberOfSeedsAtStart, 
                     currentLevel: 1,
                     lastAppOpenDate: .now)
    }

    // Collect a seed once per day
    static func collectSeed() {
        let currentDate = Date()
        let lastOpenDate = loadLastAppOpenDate()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(lastOpenDate) {
            return // Seed already collected today
        }
        
        // Add 1 seed and save the last open date as today
        addSeeds(1)
        saveProgress(totalSeeds: loadTotalSeedsCollected(), currentLevel: loadCurrentLevel(), lastAppOpenDate: currentDate)
    }
}
