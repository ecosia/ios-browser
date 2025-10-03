// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol AccountsProviderProtocol {
    func registerVisit(accessToken: String) async throws -> AccountVisitResponse
}

public struct AccountsProvider: AccountsProviderProtocol {

    public let accountsService: AccountsServiceProtocol
    private let useMockData: Bool

    public init(
        accountsService: AccountsServiceProtocol = AccountsService(),
        useMockData: Bool = false
    ) {
        self.accountsService = accountsService
        self.useMockData = useMockData
    }

    /// Registers a user visit and returns current balance.
    /// This endpoint automatically handles visit-based use cases and returns the current balance,
    /// including indicating if it has changed as a result of this call.
    /// - Parameter accessToken: Valid Auth0-issued JWT access token
    public func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        if useMockData {
            EcosiaLogger.accounts.info("Using mock response for testing")
            return createMockResponse()
        } else {
            return try await accountsService.registerVisit(accessToken: accessToken)
        }
    }

    // MARK: - Mock Response Generation

    private func createMockResponse() -> AccountVisitResponse {
        // Level thresholds matching backend specification
        let levelThresholds: [(level: Int, totalGrowthPointsRequired: Int, seedsRewardedForLevelUp: Int)] = [
            (1, 0, 0),
            (2, 75, 2),
            (3, 250, 7),
            (4, 500, 12),
            (5, 750, 18),
            (6, 1250, 25),
            (7, 2000, 33),
            (8, 2750, 42),
            (9, 3750, 52),
            (10, 5000, 63),
            (11, 6500, 75),
            (12, 8000, 88),
            (13, 10000, 101),
            (14, 12000, 116),
            (15, 14250, 131),
            (16, 17000, 147),
            (17, 19750, 164),
            (18, 23000, 182),
            (19, 26250, 200),
            (20, 30000, 220)
        ]

        // Generate random total growth points (0 to 35000)
        let totalGrowthPoints = Int.random(in: 0...35000)

        // Determine current level based on growth points
        var currentLevelIndex = 0
        for (index, threshold) in levelThresholds.enumerated() {
            if totalGrowthPoints >= threshold.totalGrowthPointsRequired {
                currentLevelIndex = index
            } else {
                break
            }
        }

        let currentLevel = levelThresholds[currentLevelIndex]
        let nextLevelIndex = min(currentLevelIndex + 1, levelThresholds.count - 1)
        let nextLevel = levelThresholds[nextLevelIndex]

        // Calculate growth points towards next level
        let growthPointsEarned = totalGrowthPoints - currentLevel.totalGrowthPointsRequired
        let growthPointsRequired = nextLevel.totalGrowthPointsRequired - currentLevel.totalGrowthPointsRequired

        // Simulate a visit that adds 25 growth points
        let growthPointsIncrement = 25
        let previousGrowthPoints = max(0, totalGrowthPoints - growthPointsIncrement)

        // Determine if user leveled up with this visit
        var previousLevelIndex = currentLevelIndex
        for (index, threshold) in levelThresholds.enumerated() {
            if previousGrowthPoints >= threshold.totalGrowthPointsRequired {
                previousLevelIndex = index
            } else {
                break
            }
        }
        let previousLevel = levelThresholds[previousLevelIndex]
        let didLevelUp = currentLevelIndex > previousLevelIndex

        // Calculate seeds
        let seedsIncrement = didLevelUp ? currentLevel.seedsRewardedForLevelUp : 1
        let currentSeeds = Int.random(in: 50...500)
        let previousSeeds = max(0, currentSeeds - seedsIncrement)

        let timestamp = ISO8601DateFormatter().string(from: Date())

        EcosiaLogger.accounts.info("""
            Mock response: Level \(currentLevel.level), \
            GP: \(totalGrowthPoints) (\(growthPointsEarned)/\(growthPointsRequired) to next), \
            Seeds: \(currentSeeds), \
            Level up: \(didLevelUp)
            """)

        return AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: currentSeeds,
                totalAmount: currentSeeds,
                previousTotalAmount: previousSeeds,
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: totalGrowthPoints,
                totalAmount: totalGrowthPoints,
                previousTotalAmount: previousGrowthPoints,
                level: AccountVisitResponse.Level(
                    number: currentLevel.level,
                    totalGrowthPointsRequired: currentLevel.totalGrowthPointsRequired,
                    seedsRewardedForLevelUp: currentLevel.seedsRewardedForLevelUp,
                    growthPointsToUnlockNextLevel: growthPointsRequired,
                    growthPointsEarnedTowardsNextLevel: growthPointsEarned
                ),
                previousLevel: AccountVisitResponse.Level(
                    number: previousLevel.level,
                    totalGrowthPointsRequired: previousLevel.totalGrowthPointsRequired,
                    seedsRewardedForLevelUp: previousLevel.seedsRewardedForLevelUp,
                    growthPointsToUnlockNextLevel: nextLevel.totalGrowthPointsRequired - previousLevel.totalGrowthPointsRequired,
                    growthPointsEarnedTowardsNextLevel: previousGrowthPoints - previousLevel.totalGrowthPointsRequired
                ),
                isModified: true,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )
    }
}
