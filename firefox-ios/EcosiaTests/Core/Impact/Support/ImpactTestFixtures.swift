// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import Auth0
import Foundation

enum ImpactTestFixtures {

    /// Builds an `AccountVisitResponse` with just the fields Impact tests care about.
    /// - `seedsModified` controls whether `response.seedsIncrement` reports a real change, matching
    ///   how the real backend only sets `isModified` when something genuinely happened during this
    ///   visit - a login that merely reveals a pre-existing balance must leave this `false`.
    /// - `previousLevelNumber` controls `response.didLevelUp`; defaults to `levelNumber` (no level up).
    static func visitResponse(
        seedCount: Int,
        previousSeedCount: Int? = nil,
        seedsModified: Bool = false,
        levelNumber: Int = 1,
        previousLevelNumber: Int? = nil
    ) -> AccountVisitResponse {
        let timestamp = "2024-12-07T10:50:26Z"
        func level(_ number: Int) -> AccountVisitResponse.Level {
            AccountVisitResponse.Level(
                number: number,
                totalGrowthPointsRequired: 100,
                seedsRewardedForLevelUp: 0,
                growthPointsToUnlockNextLevel: 100,
                growthPointsEarnedTowardsNextLevel: 10
            )
        }
        return AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: seedCount,
                totalAmount: seedCount,
                previousTotalAmount: previousSeedCount ?? seedCount,
                isModified: seedsModified,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 0,
                totalAmount: 0,
                previousTotalAmount: 0,
                level: level(levelNumber),
                previousLevel: level(previousLevelNumber ?? levelNumber),
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )
    }

    static func credentials(accessToken: String = "test-access-token") -> Credentials {
        Credentials(
            accessToken: accessToken,
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }
}
