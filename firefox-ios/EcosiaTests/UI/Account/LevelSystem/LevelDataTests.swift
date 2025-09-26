// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class LevelDataTests: XCTestCase {
    
    // MARK: - Level Structure Tests
    
    func testLevelCount() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.levels.count, 20, "Should have exactly 20 levels")
    }
    
    func testLevelProgression() {
        // Given / When / Then
        for i in 0..<AccountSeedLevelSystem.levels.count {
            let level = AccountSeedLevelSystem.levels[i]
            XCTAssertEqual(level.level, i + 1, "Level number should match array index + 1")
        }
    }
    
    func testSeedRequirementsAreAscending() {
        // Given / When / Then
        for i in 1..<AccountSeedLevelSystem.levels.count {
            let previousLevel = AccountSeedLevelSystem.levels[i - 1]
            let currentLevel = AccountSeedLevelSystem.levels[i]
            XCTAssertLessThan(previousLevel.seedsRequired, currentLevel.seedsRequired, 
                             "Seed requirements should increase with each level")
        }
    }
    
    // MARK: - Current Level Tests
    
    func testCurrentLevelAtExactThresholds() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 0).level, 1, "0 seeds should be Level 1")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 3).level, 2, "3 seeds should be Level 2")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 10).level, 3, "10 seeds should be Level 3")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 80).level, 7, "80 seeds should be Level 7")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 1210).level, 20, "1210 seeds should be Level 20")
    }
    
    func testCurrentLevelBetweenThresholds() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 1).level, 1, "1 seed should be Level 1")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 5).level, 2, "5 seeds should be Level 2")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 100).level, 7, "100 seeds should be Level 7")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 500).level, 14, "500 seeds should be Level 14")
    }
    
    func testCurrentLevelAboveMaxLevel() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 2000).level, 20, "Seeds above max should still be Level 20")
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: 10000).level, 20, "Very high seeds should still be Level 20")
    }
    
    // MARK: - Next Level Tests
    
    func testNextLevelProgression() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.nextLevel(for: 0)?.level, 2, "From Level 1, next should be Level 2")
        XCTAssertEqual(AccountSeedLevelSystem.nextLevel(for: 3)?.level, 3, "From Level 2, next should be Level 3")
        XCTAssertEqual(AccountSeedLevelSystem.nextLevel(for: 100)?.level, 8, "From Level 7, next should be Level 8")
    }
    
    func testNextLevelAtMaxLevel() {
        // Given / When / Then
        XCTAssertNil(AccountSeedLevelSystem.nextLevel(for: 1210), "At max level, next level should be nil")
        XCTAssertNil(AccountSeedLevelSystem.nextLevel(for: 2000), "Above max level, next level should be nil")
    }
    
    // MARK: - Progress Calculation Tests
    
    func testProgressAtLevelStart() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.progressToNextLevel(for: 3), 0.0, accuracy: 0.01, 
                      "Progress should be 0% when exactly at level threshold")
        XCTAssertEqual(AccountSeedLevelSystem.progressToNextLevel(for: 80), 0.0, accuracy: 0.01,
                      "Progress should be 0% when exactly at level threshold")
    }
    
    func testProgressMidLevel() {
        // Given
        // Level 2 (3 seeds) -> Level 3 (10 seeds) = 7 seed gap
        // With 5 seeds: (5-3)/(10-3) = 2/7 ≈ 0.286
        
        // When / Then
        XCTAssertEqual(AccountSeedLevelSystem.progressToNextLevel(for: 5), 2.0/7.0, accuracy: 0.01,
                      "Progress should be 2/7 with 5 seeds (Level 2 -> 3)")
        
        // Level 7 (80 seeds) -> Level 8 (110 seeds) = 30 seed gap  
        // With 100 seeds: (100-80)/(110-80) = 20/30 ≈ 0.667
        XCTAssertEqual(AccountSeedLevelSystem.progressToNextLevel(for: 100), 20.0/30.0, accuracy: 0.01,
                      "Progress should be 20/30 with 100 seeds (Level 7 -> 8)")
    }
    
    func testProgressAtMaxLevel() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.progressToNextLevel(for: 1210), 1.0, accuracy: 0.01,
                      "Progress should be 100% at max level")
        XCTAssertEqual(AccountSeedLevelSystem.progressToNextLevel(for: 2000), 1.0, accuracy: 0.01,
                      "Progress should be 100% above max level")
    }
    
    // MARK: - Level Up Detection Tests
    
    func testLevelUpDetection() {
        // Given / When / Then
        XCTAssertNil(AccountSeedLevelSystem.checkLevelUp(from: 5, to: 8), "No level up within same level")
        
        let levelUp = AccountSeedLevelSystem.checkLevelUp(from: 5, to: 15)
        XCTAssertNotNil(levelUp, "Should detect level up from 5 to 15 seeds")
        XCTAssertEqual(levelUp?.level, 3, "Should level up to Level 3")
        
        let bigLevelUp = AccountSeedLevelSystem.checkLevelUp(from: 50, to: 200)
        XCTAssertNotNil(bigLevelUp, "Should detect level up from 50 to 200 seeds")
        XCTAssertEqual(bigLevelUp?.level, 10, "Should level up to Level 10")
    }
    
    func testNoLevelUpWhenDecreasing() {
        // Given / When / Then
        XCTAssertNil(AccountSeedLevelSystem.checkLevelUp(from: 100, to: 50), 
                    "Should not detect level up when seeds decrease")
    }
    
    func testNoLevelUpAtSameLevel() {
        // Given / When / Then
        XCTAssertNil(AccountSeedLevelSystem.checkLevelUp(from: 85, to: 105),
                    "Should not detect level up when staying at same level")
    }
    
    // MARK: - Localization Tests
    
    func testLevelNamesAreLocalized() {
        // Given / When / Then
        let level1 = AccountSeedLevelSystem.levels[0]
        XCTAssertFalse(level1.localizedName.isEmpty, "Level name should not be empty")
        XCTAssertNotEqual(level1.localizedName, level1.nameKey, "Localized name should differ from key")
        
        let level20 = AccountSeedLevelSystem.levels[19]
        XCTAssertFalse(level20.localizedName.isEmpty, "Level name should not be empty")
        XCTAssertNotEqual(level20.localizedName, level20.nameKey, "Localized name should differ from key")
    }
    
    // MARK: - Edge Cases
    
    func testNegativeSeedCount() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.currentLevel(for: -1).level, 1, "Negative seeds should default to Level 1")
        XCTAssertEqual(AccountSeedLevelSystem.progressToNextLevel(for: -1), -1.0/3.0, accuracy: 0.01,
                      "Negative seeds should calculate negative progress")
    }
    
    // MARK: - Specific Seed Requirements Tests
    
    func testSpecificSeedRequirements() {
        // Given / When / Then
        XCTAssertEqual(AccountSeedLevelSystem.levels[0].seedsRequired, 0, "Level 1 should require 0 seeds")
        XCTAssertEqual(AccountSeedLevelSystem.levels[1].seedsRequired, 3, "Level 2 should require 3 seeds")
        XCTAssertEqual(AccountSeedLevelSystem.levels[2].seedsRequired, 10, "Level 3 should require 10 seeds")
        XCTAssertEqual(AccountSeedLevelSystem.levels[6].seedsRequired, 80, "Level 7 should require 80 seeds")
        XCTAssertEqual(AccountSeedLevelSystem.levels[19].seedsRequired, 1200, "Level 20 should require 1200 seeds")
    }
    
    // MARK: - Manual Validation Helper
    
    func testValidateProgressCalculations() {
        // Given
        let testCases = [1, 3, 5, 10, 15, 25, 50, 100, 200, 500, 1000, 1200]
        
        // When / Then
        for seedCount in testCases {
            let current = AccountSeedLevelSystem.currentLevel(for: seedCount)
            let next = AccountSeedLevelSystem.nextLevel(for: seedCount)
            let progress = AccountSeedLevelSystem.progressToNextLevel(for: seedCount)
            
            // Validate that progress is between 0 and 1
            XCTAssertGreaterThanOrEqual(progress, 0.0, "Progress should be >= 0 for \(seedCount) seeds")
            XCTAssertLessThanOrEqual(progress, 1.0, "Progress should be <= 1 for \(seedCount) seeds")
            
            // Validate level consistency
            XCTAssertGreaterThan(current.level, 0, "Level should be positive for \(seedCount) seeds")
            XCTAssertLessThanOrEqual(current.level, 20, "Level should not exceed 20 for \(seedCount) seeds")
            
            if let nextLevel = next {
                XCTAssertEqual(nextLevel.level, current.level + 1, "Next level should be current + 1 for \(seedCount) seeds")
                print("Seeds: \(seedCount) | Level \(current.level) (\(current.localizedName)) | Progress to Level \(nextLevel.level): \(Int(progress * 100))%")
            } else {
                XCTAssertEqual(current.level, 20, "Should be at max level when next is nil for \(seedCount) seeds")
                print("Seeds: \(seedCount) | Level \(current.level) (\(current.localizedName)) | MAX LEVEL REACHED")
            }
        }
    }
}
