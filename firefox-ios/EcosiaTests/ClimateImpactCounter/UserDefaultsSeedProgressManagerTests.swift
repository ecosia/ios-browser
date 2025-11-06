// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
@testable import Client

/// Remember that we always start from 1 seed and level 1 every time.
final class UserDefaultsSeedProgressManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "CurrentLevel")
        UserDefaults.standard.removeObject(forKey: "TotalSeedsCollected")
        UserDefaults.standard.removeObject(forKey: "LastAppOpenDate")

        // Default Seed Levels for testing (arbitrary levels)
        UserDefaultsSeedProgressManager.seedCounterConfig = SeedCounterConfig(
            sparklesAnimationDuration: 10,
            maxCappedLevel: nil,
            maxCappedSeeds: nil,
            levels: [
                SeedCounterConfig.SeedLevel(level: 1, requiredSeeds: 2),
                SeedCounterConfig.SeedLevel(level: 2, requiredSeeds: 3)
            ]
        )
    }

    // Test the initial state
    func test_initial_seed_progress_state() {
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1, "Initial level should be 1")
        XCTAssertEqual(totalSeedsCollected, 1, "Initial totalSeedsCollected should be 1")
    }

    // Test that logged-out users never level up
    func test_logged_out_users_never_level_up() {
        // Given
        UserDefaultsSeedProgressManager.addSeeds(2)

        // When / Then
        var level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        var totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1)
        XCTAssertEqual(totalSeedsCollected, 3)

        // When: Try to add more seeds
        UserDefaultsSeedProgressManager.addSeeds(10)

        // Then: Level remains 1, seeds capped at 3
        level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1)
        XCTAssertEqual(totalSeedsCollected, 3)
    }

    // Test resetting the progress to the initial state
    func test_reset_counter() {
        // Given
        UserDefaultsSeedProgressManager.addSeeds(2)

        // When
        UserDefaultsSeedProgressManager.resetCounter()

        // Then
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1)
        XCTAssertEqual(totalSeedsCollected, 1)
    }

    // Test collecting a seed once per day
    func test_collect_seed_once_per_day() {
        // Given / When
        UserDefaultsSeedProgressManager.collectDailySeed()
        let totalSeedsAfterFirstCollect = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        UserDefaultsSeedProgressManager.collectDailySeed()
        let totalSeedsAfterSecondCollect = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()

        // Then
        XCTAssertEqual(totalSeedsAfterFirstCollect, 1)
        XCTAssertEqual(totalSeedsAfterSecondCollect, 1)
    }

    // Test that a seed can be collected the next day but stays at level 1
    func test_collect_seed_next_day_stays_level_1() {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")

        // When
        UserDefaultsSeedProgressManager.collectDailySeed()

        // Then
        let totalSeedsCollected = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(totalSeedsCollected, 2)
        XCTAssertEqual(level, 1)
    }

    // Test that logged-out users are capped at 3 seeds and always remain at level 1
    func test_logged_out_users_capped_at_max_seeds_and_level_1() {
        // Given
        let initialSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let initialLevel = UserDefaultsSeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(initialSeeds, 1)
        XCTAssertEqual(initialLevel, 1)

        // When
        UserDefaultsSeedProgressManager.addSeeds(2)

        // Then
        var totalSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        var level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)

        // When
        UserDefaultsSeedProgressManager.addSeeds(5)

        // Then
        totalSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)
    }

    // Test that bulk seed addition caps at 3 seeds and level remains 1
    func test_logged_out_users_bulk_addition_caps_at_3_seeds_level_1() {
        // Given
        let initialSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        XCTAssertEqual(initialSeeds, 1)

        // When
        UserDefaultsSeedProgressManager.addSeeds(10)

        // Then
        let totalSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)
    }

    // Test that daily seed collection respects cap and level remains 1
    func test_logged_out_users_daily_seed_respects_cap_and_level_1() {
        // Given
        UserDefaultsSeedProgressManager.addSeeds(2)
        var totalSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        var level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, 3)
        XCTAssertEqual(level, 1)

        // When
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")
        UserDefaultsSeedProgressManager.collectDailySeed()

        // Then
        totalSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        level = UserDefaultsSeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)
    }
}
