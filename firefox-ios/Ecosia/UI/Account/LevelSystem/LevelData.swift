// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The current levelling system which will soon be replaced by the new one based on Growth Points
public struct AccountSeedLevel {
    public let level: Int
    public let nameKey: String
    public let seedsRequired: Int

    public init(level: Int, nameKey: String, seedsRequired: Int) {
        self.level = level
        self.nameKey = nameKey
        self.seedsRequired = seedsRequired
    }

    /// Localized name for the level
    public var localizedName: String {
        let matchingKey = String.Key.allCases.first {
            String(describing: $0) == nameKey
        }
        return String.localized(matchingKey ?? .ecocurious)
    }
}

public struct AccountSeedLevelSystem {

    /// All available levels in ascending order
    public static let levels: [AccountSeedLevel] = [
        AccountSeedLevel(level: 1, nameKey: "ecocurious", seedsRequired: 0),
        AccountSeedLevel(level: 2, nameKey: "greenExplorer", seedsRequired: 3),
        AccountSeedLevel(level: 3, nameKey: "planetPal", seedsRequired: 10),
        AccountSeedLevel(level: 4, nameKey: "seedlingSupporter", seedsRequired: 20),
        AccountSeedLevel(level: 5, nameKey: "biodiversityBeetle", seedsRequired: 30),
        AccountSeedLevel(level: 6, nameKey: "forestFriend", seedsRequired: 50),
        AccountSeedLevel(level: 7, nameKey: "wildlifeProtector", seedsRequired: 80),
        AccountSeedLevel(level: 8, nameKey: "ecoExplorer", seedsRequired: 110),
        AccountSeedLevel(level: 9, nameKey: "rainforestReviver", seedsRequired: 150),
        AccountSeedLevel(level: 10, nameKey: "planetProtector", seedsRequired: 200),
        AccountSeedLevel(level: 11, nameKey: "carbonNeutralizer", seedsRequired: 260),
        AccountSeedLevel(level: 12, nameKey: "seekerOfSustainability", seedsRequired: 320),
        AccountSeedLevel(level: 13, nameKey: "branchBuilder", seedsRequired: 400),
        AccountSeedLevel(level: 14, nameKey: "ecoEnthusiast", seedsRequired: 480),
        AccountSeedLevel(level: 15, nameKey: "carbonCutter", seedsRequired: 570),
        AccountSeedLevel(level: 16, nameKey: "seedSower", seedsRequired: 680),
        AccountSeedLevel(level: 17, nameKey: "emissionEliminator", seedsRequired: 790),
        AccountSeedLevel(level: 18, nameKey: "sustainabilitySage", seedsRequired: 920),
        AccountSeedLevel(level: 19, nameKey: "earthAdvocate", seedsRequired: 1050),
        AccountSeedLevel(level: 20, nameKey: "seedSuperstar", seedsRequired: 1200)
    ]

    /// Gets the current level for a given seed count
    public static func currentLevel(for seedCount: Int) -> AccountSeedLevel {
        for level in levels.reversed() {
            if seedCount >= level.seedsRequired {
                return level
            }
        }
        return levels[0]
    }

    /// Gets the next level for a given seed count
    public static func nextLevel(for seedCount: Int) -> AccountSeedLevel? {
        let current = currentLevel(for: seedCount)
        let currentIndex = levels.firstIndex { $0.level == current.level } ?? 0

        if currentIndex < levels.count - 1 {
            return levels[currentIndex + 1]
        }
        return nil
    }

    /// Calculates progress towards next level (0.0 to 1.0)
    public static func progressToNextLevel(for seedCount: Int) -> Double {
        let current = currentLevel(for: seedCount)
        guard let next = nextLevel(for: seedCount) else {
            return 1.0
        }

        let seedsInCurrentLevel = seedCount - current.seedsRequired
        let seedsNeededForNext = next.seedsRequired - current.seedsRequired

        return Double(seedsInCurrentLevel) / Double(seedsNeededForNext)
    }

    /// Checks if the user leveled up from oldSeedCount to newSeedCount
    public static func checkLevelUp(from oldSeedCount: Int, to newSeedCount: Int) -> AccountSeedLevel? {
        let oldLevel = currentLevel(for: oldSeedCount)
        let newLevel = currentLevel(for: newSeedCount)

        return newLevel.level > oldLevel.level ? newLevel : nil
    }
}
