// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class UserDefaultsSeedProgressManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "CurrentLevel")
        UserDefaults.standard.removeObject(forKey: "TotalSeedsCollected")
        UserDefaults.standard.removeObject(forKey: "LastAppOpenDate")
    }

    // Test the initial state
    func test_initial_seed_progress_state() {
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        
        XCTAssertEqual(level, 1, "Initial level should be 1")
        XCTAssertEqual(totalSeedsCollected, 1, "Initial totalSeedsCollected should be 0")
    }

    // Test adding seeds and progressing to level 2 without resetting total seeds
    func test_add_seeds_progress_to_next_level() {
        UserDefaultsSeedProgressManager.addSeeds(4)
        
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        
        XCTAssertEqual(level, 2, "User should progress to level 2 after collecting 5 seeds")
        XCTAssertEqual(totalSeedsCollected, 5, "Total seeds should be cumulative and remain 5")
    }

    // Test adding seeds beyond level 1 and continuing accumulation for level 2
    func test_add_seeds_beyond_level_1() {
        UserDefaultsSeedProgressManager.addSeeds(5)  // Reach level 2
        
        UserDefaultsSeedProgressManager.addSeeds(2)  // Add 2 more seeds in level 2
        
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let innerProgress = UserDefaultsSeedProgressManager.calculateInnerProgress()

        XCTAssertEqual(level, 2, "User should stay in level 2")
        XCTAssertEqual(totalSeedsCollected, 8, "Total seeds should accumulate across levels")
        XCTAssertEqual(innerProgress, 0.3, accuracy: 0.01, "Should show 30% progress towards completing level 2")
    }

    // Test inner progress calculation for Level 2
    func test_calculate_inner_progress_for_level_2() {
        UserDefaultsSeedProgressManager.addSeeds(6)  // Collect 6 seeds total, which puts the user at level 2

        let innerProgress = UserDefaultsSeedProgressManager.calculateInnerProgress()
        XCTAssertEqual(innerProgress, 0.2, accuracy: 0.01, "Inner progress should reflect 20% progress for level 2 after collecting 2 seeds")
    }

    // Test resetting the progress to the initial state
    func test_reset_counter() {
        UserDefaultsSeedProgressManager.addSeeds(10)
        UserDefaultsSeedProgressManager.resetCounter()

        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let innerProgress = UserDefaultsSeedProgressManager.calculateInnerProgress()

        XCTAssertEqual(level, 1, "Reset should set the level to 1")
        XCTAssertEqual(totalSeedsCollected, 1, "Reset should set totalSeedsCollected to 1")
        XCTAssertEqual(innerProgress, 0.2, "Reset should set progress to 20%")
    }

    // Test collecting a seed once per day
    func test_collect_seed_once_per_day() {
        UserDefaultsSeedProgressManager.collectSeed()  // First seed collection today
        let totalSeedsAfterFirstCollect = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        
        UserDefaultsSeedProgressManager.collectSeed()  // Try collecting another seed today
        let totalSeedsAfterSecondCollect = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(totalSeedsAfterFirstCollect, 1, "Should collect one seed on first open")
        XCTAssertEqual(totalSeedsAfterSecondCollect, 1, "Should not collect more than one seed in a day")
    }

    // Test that a seed can be collected the next day
    func test_collect_seed_next_day() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")
        
        UserDefaultsSeedProgressManager.collectSeed()  // Simulate collecting seed today
        
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        XCTAssertEqual(totalSeedsCollected, 2, "User should be able to collect a seed on a new day")
    }

    // Test progress calculation for level 2 and beyond
    func test_progress_calculation_beyond_level_2() {
        // Setup to be at level 2 with 7 seeds collected
        UserDefaultsSeedProgressManager.addSeeds(7)
        
        let innerProgress = UserDefaultsSeedProgressManager.calculateInnerProgress()
        XCTAssertEqual(innerProgress, 0.3, "Should have 30% progress in level 2 after collecting 3 seeds in level 2")
    }
}
