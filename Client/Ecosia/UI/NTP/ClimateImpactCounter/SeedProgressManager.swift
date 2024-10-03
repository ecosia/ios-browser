// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class SeedProgressManager: ObservableObject {
    @Published var level: Int = 1
    @Published var seedsCollected: Int = 1
    @Published var progressValue: CGFloat = 0.0
    
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private let levelKey = "SeedProgressLevel"
    private let seedsCollectedKey = "SeedsCollected"
    private let lastAppOpenDateKey = "LastAppOpenDate"
    
    private let level1Threshold = 5
    private let level2Threshold = 7
    
    init() {
        // Load progress from UserDefaults when initialized
        loadProgress()
        updateProgress()
    }
    
    // Save the seed progress and level to UserDefaults
    private func saveProgress() {
        userDefaults.set(level, forKey: levelKey)
        userDefaults.set(seedsCollected, forKey: seedsCollectedKey)
        if let lastAppOpenDate = lastAppOpenDate {
            userDefaults.set(lastAppOpenDate, forKey: lastAppOpenDateKey)
        }
    }
    
    // Load the seed progress and level from UserDefaults
    private func loadProgress() {
        if let savedLevel = userDefaults.value(forKey: levelKey) as? Int {
            level = savedLevel
        }
        if let savedSeedsCollected = userDefaults.value(forKey: seedsCollectedKey) as? Int {
            seedsCollected = savedSeedsCollected
        }
        if let savedLastAppOpenDate = userDefaults.value(forKey: lastAppOpenDateKey) as? Date {
            lastAppOpenDate = savedLastAppOpenDate
        }
    }
    
    // Updates the current progress value (0 to 1) based on the current level and seeds collected
    func updateProgress() {
        let currentThreshold = (level == 1) ? level1Threshold : level2Threshold
        if level == 1 || level == 2 {
            progressValue = CGFloat(seedsCollected) / CGFloat(currentThreshold)
        }
        
        // After level 2, the progress remains full
        if level == 2 && seedsCollected >= level2Threshold {
            progressValue = 1.0
        }
        
        // Save progress whenever it's updated
        saveProgress()
    }
    
    // Collect a seed once per day
    func collectSeed() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        if let lastOpenDate = lastAppOpenDate, calendar.isDateInToday(lastOpenDate) {
            // Seed already collected today, do nothing
            return
        }
        
        // Collect one seed
        seedsCollected += 1
        lastAppOpenDate = currentDate
        
        // Handle level transitions
        if level == 1 && seedsCollected >= level1Threshold {
            // Move to level 2
            level = 2
            seedsCollected = 0
        } else if level == 2 && seedsCollected >= level2Threshold {
            // Cap the progress at level 2
            seedsCollected = level2Threshold
        }
        
        // Save progress and update progress bar
        updateProgress()
    }
    
    // Store last app open date
    private var lastAppOpenDate: Date? {
        get {
            return userDefaults.object(forKey: lastAppOpenDateKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: lastAppOpenDateKey)
        }
    }
}
