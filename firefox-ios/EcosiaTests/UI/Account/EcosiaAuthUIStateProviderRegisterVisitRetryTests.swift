// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

private final class MockAccountsProvider: AccountsProviderProtocol {
    nonisolated(unsafe) var callCount = 0
    private let failuresBeforeSuccess: Int
    private let alwaysFails: Bool

    init(failuresBeforeSuccess: Int = 0, alwaysFails: Bool = false) {
        self.failuresBeforeSuccess = failuresBeforeSuccess
        self.alwaysFails = alwaysFails
    }

    func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        callCount += 1
        if alwaysFails || callCount <= failuresBeforeSuccess {
            throw URLError(.notConnectedToInternet)
        }
        return .fixture()
    }
}

/// Records delays passed to `registerVisitRetrySleep`, instead of capturing a mutable local in a
/// closure crossing an `async` boundary.
private final class DelayRecorder {
    nonisolated(unsafe) static var delays: [TimeInterval] = []

    static func record(_ seconds: TimeInterval) {
        delays.append(seconds)
    }

    static func reset() {
        delays = []
    }
}

private extension AccountVisitResponse {
    static func fixture(seedCount: Int = 10, level: Int = 1) -> AccountVisitResponse {
        let levelInfo = Level(
            number: level,
            totalGrowthPointsRequired: 0,
            seedsRewardedForLevelUp: 0,
            growthPointsToUnlockNextLevel: 100,
            growthPointsEarnedTowardsNextLevel: 0
        )
        return AccountVisitResponse(
            seeds: Seeds(
                balanceAmount: seedCount,
                totalAmount: seedCount,
                previousTotalAmount: seedCount,
                isModified: false,
                lastVisitAt: "",
                updatedAt: ""
            ),
            growthPoints: GrowthPoints(
                balanceAmount: 0,
                totalAmount: 0,
                previousTotalAmount: 0,
                level: levelInfo,
                previousLevel: levelInfo,
                isModified: false,
                lastVisitAt: "",
                updatedAt: ""
            )
        )
    }
}

@MainActor
final class EcosiaAuthUIStateProviderRegisterVisitRetryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DelayRecorder.reset()
        // Skip real delays between retries; individual tests opt back into recording if needed.
        EcosiaAuthUIStateProvider.registerVisitRetrySleep = { _ in }
    }

    override func tearDown() {
        EcosiaAuthUIStateProvider.registerVisitRetrySleep = { seconds in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
        DelayRecorder.reset()
        super.tearDown()
    }

    func test_succeedsOnFirstAttempt_doesNotRetry() async {
        let mockProvider = MockAccountsProvider(failuresBeforeSuccess: 0)
        let provider = EcosiaAuthUIStateProvider(accountsProvider: mockProvider)

        await provider.performRegisterVisitWithRetry(accessToken: "token")

        XCTAssertEqual(mockProvider.callCount, 1)
        XCTAssertFalse(provider.hasRegisterVisitError)
    }

    func test_retriesAfterFailures_thenSucceedsWithinMaxAttempts() async {
        let mockProvider = MockAccountsProvider(failuresBeforeSuccess: 2)
        let provider = EcosiaAuthUIStateProvider(accountsProvider: mockProvider)

        await provider.performRegisterVisitWithRetry(accessToken: "token")

        XCTAssertEqual(mockProvider.callCount, 3, "Should retry through the first 2 failures before the 3rd (max) attempt succeeds")
        XCTAssertFalse(provider.hasRegisterVisitError)
        XCTAssertEqual(provider.seedCount, 10, "The eventually-successful response should still update state")
    }

    func test_givesUpAfterMaxAttempts_setsErrorState() async {
        let mockProvider = MockAccountsProvider(alwaysFails: true)
        let provider = EcosiaAuthUIStateProvider(accountsProvider: mockProvider)

        await provider.performRegisterVisitWithRetry(accessToken: "token")

        XCTAssertEqual(mockProvider.callCount, 3, "Should stop after the configured max attempts, not retry forever")
        XCTAssertTrue(provider.hasRegisterVisitError)
    }

    func test_usesExponentialBackoff_betweenRetries() async {
        EcosiaAuthUIStateProvider.registerVisitRetrySleep = { seconds in DelayRecorder.record(seconds) }
        let mockProvider = MockAccountsProvider(alwaysFails: true)
        let provider = EcosiaAuthUIStateProvider(accountsProvider: mockProvider)

        await provider.performRegisterVisitWithRetry(accessToken: "token")

        XCTAssertEqual(DelayRecorder.delays, [1.0, 2.0], "Delay should double after each failed attempt")
    }
}
