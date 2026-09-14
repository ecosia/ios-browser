// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
@testable import Client

/// Tests for logged-out user seed collection. Users start at 0 seeds and level 1.
final class SeedProgressManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "CurrentLevel")
        UserDefaults.standard.removeObject(forKey: "TotalSeedsCollected")
        UserDefaults.standard.removeObject(forKey: "LastAppOpenDate")

        // Default Seed Levels for testing (arbitrary levels)
        SeedProgressManager.seedCounterConfig = SeedCounterConfig(
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
        // Given / When
        let level = SeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = SeedProgressManager.loadTotalSeedsCollected()

        // Then
        XCTAssertEqual(level, 1, "Initial level should be 1")
        XCTAssertEqual(totalSeedsCollected, 0, "Initial totalSeedsCollected should be 0")
    }

    // Test that logged-out users never level up
    func test_logged_out_users_never_level_up() {
        // Given
        SeedProgressManager.addSeeds(2)

        // When / Then
        var level = SeedProgressManager.loadCurrentLevel()
        var totalSeedsCollected = SeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1)
        XCTAssertEqual(totalSeedsCollected, 2)

        // When: Try to add more seeds
        SeedProgressManager.addSeeds(10)

        // Then: Level remains 1, seeds capped at 3
        level = SeedProgressManager.loadCurrentLevel()
        totalSeedsCollected = SeedProgressManager.loadTotalSeedsCollected()

        XCTAssertEqual(level, 1)
        XCTAssertEqual(totalSeedsCollected, 3)
    }

    // Test resetting the progress to first-launch state
    func test_reset_local_seed_progress() {
        // Given
        SeedProgressManager.addSeeds(2)

        // When
        SeedProgressManager.resetLocalSeedProgress()

        // Then
        let level = SeedProgressManager.loadCurrentLevel()
        let totalSeedsCollected = SeedProgressManager.loadTotalSeedsCollected()
        let lastAppOpenDate = SeedProgressManager.loadLastAppOpenDate()

        XCTAssertEqual(level, 1)
        XCTAssertEqual(totalSeedsCollected, 0)
        XCTAssertNil(lastAppOpenDate, "Last app open date should be cleared to allow immediate seed collection")
    }

    // Test collecting a seed once per day
    func test_collect_seed_once_per_day() {
        // Given: Start with 0 seeds
        let initialSeeds = SeedProgressManager.loadTotalSeedsCollected()
        XCTAssertEqual(initialSeeds, 0)

        // When: Collect seed on first day
        SeedProgressManager.collectDailySeed()
        let totalSeedsAfterFirstCollect = SeedProgressManager.loadTotalSeedsCollected()

        // When: Try to collect again same day
        SeedProgressManager.collectDailySeed()
        let totalSeedsAfterSecondCollect = SeedProgressManager.loadTotalSeedsCollected()

        // Then: First collect should add 1, second should do nothing
        XCTAssertEqual(totalSeedsAfterFirstCollect, 1)
        XCTAssertEqual(totalSeedsAfterSecondCollect, 1)
    }

    // Test that a seed can be collected the next day but stays at level 1
    func test_collect_seed_next_day_stays_level_1() {
        // Given / When
        SeedProgressManager.collectDailySeed()
        var totalSeedsCollected = SeedProgressManager.loadTotalSeedsCollected()
        XCTAssertEqual(totalSeedsCollected, 1)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")
        SeedProgressManager.collectDailySeed()

        // Then
        totalSeedsCollected = SeedProgressManager.loadTotalSeedsCollected()
        let level = SeedProgressManager.loadCurrentLevel()

        XCTAssertEqual(totalSeedsCollected, 2)
        XCTAssertEqual(level, 1)
    }

    // Test that logged-out users are capped at 3 seeds and always remain at level 1
    func test_logged_out_users_capped_at_max_seeds_and_level_1() {
        // Given
        let initialSeeds = SeedProgressManager.loadTotalSeedsCollected()
        let initialLevel = SeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(initialSeeds, 0)
        XCTAssertEqual(initialLevel, 1)

        // When
        SeedProgressManager.addSeeds(3)

        // Then
        var totalSeeds = SeedProgressManager.loadTotalSeedsCollected()
        var level = SeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, SeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)

        // When
        SeedProgressManager.addSeeds(5)

        // Then
        totalSeeds = SeedProgressManager.loadTotalSeedsCollected()
        level = SeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, SeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)
    }

    // Test that bulk seed addition caps at 3 seeds and level remains 1
    func test_logged_out_users_bulk_addition_caps_at_3_seeds_level_1() {
        // Given
        let initialSeeds = SeedProgressManager.loadTotalSeedsCollected()
        XCTAssertEqual(initialSeeds, 0)

        // When
        SeedProgressManager.addSeeds(10)

        // Then
        let totalSeeds = SeedProgressManager.loadTotalSeedsCollected()
        let level = SeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, SeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)
    }

    // Test that daily seed collection respects cap and level remains 1
    func test_logged_out_users_daily_seed_respects_cap_and_level_1() {
        // Given
        SeedProgressManager.addSeeds(3)
        var totalSeeds = SeedProgressManager.loadTotalSeedsCollected()
        var level = SeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, 3)
        XCTAssertEqual(level, 1)

        // When
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        UserDefaults.standard.set(yesterday, forKey: "LastAppOpenDate")
        SeedProgressManager.collectDailySeed()

        // Then
        totalSeeds = SeedProgressManager.loadTotalSeedsCollected()
        level = SeedProgressManager.loadCurrentLevel()
        XCTAssertEqual(totalSeeds, SeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertEqual(level, 1)
    }

    // Test that currentSnapshot() reflects real local progress, not a hardcoded placeholder
    func test_currentSnapshot_reflectsLocalProgress() {
        SeedProgressManager.addSeeds(2) // exactly reaches level 1's threshold (requiredSeeds: 2)

        let snapshot = SeedProgressManager.currentSnapshot()

        XCTAssertEqual(snapshot.seedCount, 2)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
        XCTAssertEqual(snapshot.currentProgress, 1.0, accuracy: 0.0001)
    }

    // Test that clearOnLogout() is the same shared vocabulary as resetLocalSeedProgress()
    func test_clearOnLogout_isEquivalentToResetLocalSeedProgress() {
        SeedProgressManager.addSeeds(2)

        SeedProgressManager.clearOnLogout()

        XCTAssertEqual(SeedProgressManager.loadCurrentLevel(), 1)
        XCTAssertEqual(SeedProgressManager.loadTotalSeedsCollected(), 0)
        let lastOpenDateMessage = "Last app open date should be cleared to allow immediate seed collection"
        XCTAssertNil(SeedProgressManager.loadLastAppOpenDate(), lastOpenDateMessage)
    }
}
