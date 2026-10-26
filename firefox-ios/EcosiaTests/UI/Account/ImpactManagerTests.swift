// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
@testable import Ecosia
import XCTest

@MainActor
final class ImpactManagerTests: XCTestCase {

    private let auth = MockAuthSessionProvider(isLoggedIn: true, hasResolvedAuthState: true, accessToken: "token")
    private lazy var accountsProvider = MockAccountsProvider(result: .success(makeVisitResponse()))
    private lazy var manager = ImpactManager(accountsProvider: accountsProvider, auth: auth)
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        MockLoggedInImpactCache.reset()
        ImpactManager.loggedInImpactCacheType = MockLoggedInImpactCache.self
        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
    }

    override func tearDown() {
        cancellables = []
        ImpactManager.loggedInImpactCacheType = LoggedInImpactCache.self
        MockLoggedInImpactCache.reset()
        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        super.tearDown()
    }

    // MARK: - Register visit

    func test_userLoggedIn_registersVisitWithCurrentAccessToken() async {
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertEqual(accountsProvider.receivedAccessTokens, ["token"])
    }

    func test_registerVisitSuccess_appliesLevelAndProgress() async {
        accountsProvider.result = .success(makeVisitResponse(levelNumber: 3, earnedTowardsNextLevel: 50, toUnlockNextLevel: 200))
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertEqual(manager.currentLevelNumber, 3)
        XCTAssertEqual(manager.currentProgress, 0.25)
    }

    func test_registerVisitSuccess_withoutSeedIncrement_setsSeedCountImmediately() async {
        accountsProvider.result = .success(makeVisitResponse(seedBalance: 42))
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertEqual(manager.seedCount, 42)
    }

    func test_registerVisitSuccess_cachesSnapshot() async {
        accountsProvider.result = .success(makeVisitResponse(seedBalance: 42, levelNumber: 3, earnedTowardsNextLevel: 50, toUnlockNextLevel: 200))
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertEqual(MockLoggedInImpactCache.stored, ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.25))
    }

    func test_registerVisitFailure_setsRegisterVisitError() async {
        accountsProvider.result = .failure(URLError(.notConnectedToInternet))
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertTrue(manager.hasRegisterVisitError)
        XCTAssertNil(MockLoggedInImpactCache.stored)
    }

    func test_registerVisitSuccess_clearsPreviousRegisterVisitError() async {
        accountsProvider.result = .failure(URLError(.notConnectedToInternet))
        let failed = expectRegisterVisitToFinish()
        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [failed], timeout: 1)
        XCTAssertTrue(manager.hasRegisterVisitError, "Sanity check: the first visit failed")

        accountsProvider.result = .success(makeVisitResponse())
        let succeeded = expectRegisterVisitToFinish()
        manager.refreshSeedState()
        await fulfillment(of: [succeeded], timeout: 1)

        XCTAssertFalse(manager.hasRegisterVisitError)
    }

    func test_userLoggedIn_withoutAccessToken_doesNotRegisterVisit() async {
        auth.accessToken = nil

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await expectNoRegisterVisit()

        XCTAssertTrue(accountsProvider.receivedAccessTokens.isEmpty)
    }

    func test_userLoggedIn_withEmptyAccessToken_doesNotRegisterVisit() async {
        auth.accessToken = ""

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await expectNoRegisterVisit()

        XCTAssertTrue(accountsProvider.receivedAccessTokens.isEmpty)
    }

    // MARK: - Session changes while in flight

    func test_registerVisitResponse_isDiscarded_whenAccessTokenChangesInFlight() async {
        accountsProvider.result = .success(makeVisitResponse(seedBalance: 42, levelNumber: 3))
        accountsProvider.onRegisterVisit = { [auth] in auth.accessToken = "other-account-token" }
        let finished = expectRegisterVisitToFinish()
        finished.isInverted = true

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 0.5)

        XCTAssertEqual(manager.currentLevelNumber, 1)
        XCTAssertNil(MockLoggedInImpactCache.stored)
    }

    func test_registerVisitResponse_isDiscarded_whenLoggedOutInFlight() async {
        accountsProvider.result = .success(makeVisitResponse(seedBalance: 42, levelNumber: 3))
        accountsProvider.onRegisterVisit = { [auth] in auth.accessToken = nil }
        let finished = expectRegisterVisitToFinish()
        finished.isInverted = true

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 0.5)

        XCTAssertEqual(manager.currentLevelNumber, 1)
        XCTAssertNil(MockLoggedInImpactCache.stored)
    }

    // MARK: - Refresh before auth resolves

    func test_refreshSeedState_beforeAuthResolves_doesNotRegisterVisit() async {
        auth.hasResolvedAuthState = false

        manager.refreshSeedState()
        await expectNoRegisterVisit()

        XCTAssertTrue(accountsProvider.receivedAccessTokens.isEmpty)
    }

    func test_refreshSeedState_beforeAuthResolves_registersVisitOnAuthStateLoaded() async {
        auth.hasResolvedAuthState = false
        manager.refreshSeedState()
        auth.hasResolvedAuthState = true
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .authStateLoaded)
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertEqual(accountsProvider.receivedAccessTokens, ["token"])
    }

    func test_refreshSeedState_beforeAuthResolves_isReplayedOnlyOnce() async {
        auth.hasResolvedAuthState = false
        manager.refreshSeedState()
        auth.hasResolvedAuthState = true
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .authStateLoaded)
        manager.handleAuthStateChange(actionType: .authStateLoaded)
        await fulfillment(of: [finished], timeout: 1)
        await expectNoRegisterVisit()

        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 1)
    }

    func test_refreshSeedState_beforeAuthResolves_collectsDailySeedOnAuthStateLoaded_whenLoggedOut() {
        auth.isLoggedIn = false
        auth.accessToken = nil
        auth.hasResolvedAuthState = false
        manager.refreshSeedState()
        XCTAssertEqual(UserDefaultsSeedProgressManager.loadTotalSeedsCollected(), 0, "Sanity check: nothing collected before auth resolves")

        auth.hasResolvedAuthState = true
        manager.handleAuthStateChange(actionType: .authStateLoaded)

        XCTAssertEqual(UserDefaultsSeedProgressManager.loadTotalSeedsCollected(), 1)
    }

    func test_refreshSeedState_registersVisit_whenAuthResolvedWithoutNotification() async {
        auth.hasResolvedAuthState = false
        manager.refreshSeedState()
        auth.hasResolvedAuthState = true
        let finished = expectRegisterVisitToFinish()

        manager.refreshSeedState()
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertEqual(accountsProvider.receivedAccessTokens, ["token"])
    }

    func test_refreshSeedState_whenLoggedIn_registersVisitOnEveryCall() async {
        let finished = expectRegisterVisitToFinish(count: 2)

        manager.refreshSeedState()
        manager.refreshSeedState()
        await fulfillment(of: [finished], timeout: 1)

        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 2)
    }

    // MARK: - One visit per auth resolution

    func test_userLoggedInThenAuthStateLoaded_forSameResolution_registersOneVisit() async {
        auth.hasResolvedAuthState = false
        manager.refreshSeedState()
        auth.hasResolvedAuthState = true
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        manager.handleAuthStateChange(actionType: .authStateLoaded)
        await fulfillment(of: [finished], timeout: 1)
        await expectNoRegisterVisit()

        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 1)
    }

    func test_authStateLoadedThenUserLoggedIn_forSameResolution_registersOneVisit() async {
        auth.hasResolvedAuthState = false
        manager.refreshSeedState()
        auth.hasResolvedAuthState = true
        let finished = expectRegisterVisitToFinish()

        manager.handleAuthStateChange(actionType: .authStateLoaded)
        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [finished], timeout: 1)
        await expectNoRegisterVisit()

        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 1)
    }

    func test_userLoggedIn_afterLogout_registersVisitAgain() async {
        let firstLogin = expectRegisterVisitToFinish()
        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [firstLogin], timeout: 1)

        auth.isLoggedIn = false
        auth.accessToken = nil
        manager.handleAuthStateChange(actionType: .userLoggedOut)

        auth.isLoggedIn = true
        auth.accessToken = "second-token"
        let secondLogin = expectRegisterVisitToFinish()
        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [secondLogin], timeout: 1)

        XCTAssertEqual(accountsProvider.receivedAccessTokens, ["token", "second-token"])
    }

    func test_secondUserLoggedIn_withoutLogout_doesNotRegisterVisit() async {
        // Current behaviour, not a requirement: the resolution flag is only reset on logout.
        let firstLogin = expectRegisterVisitToFinish()
        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await fulfillment(of: [firstLogin], timeout: 1)

        manager.handleAuthStateChange(actionType: .userLoggedIn)
        await expectNoRegisterVisit()

        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 1)
    }

    // MARK: - Helpers

    /// `hasRegisterVisitError` is assigned on every completed visit, success or failure.
    private func expectRegisterVisitToFinish(count: Int = 1) -> XCTestExpectation {
        let finished = expectation(description: "Register visit finished")
        finished.expectedFulfillmentCount = count
        manager.$hasRegisterVisitError
            .dropFirst()
            .prefix(count)
            .sink { _ in finished.fulfill() }
            .store(in: &cancellables)
        return finished
    }

    private func expectNoRegisterVisit() async {
        let visited = expectation(description: "Register visit called")
        visited.isInverted = true
        accountsProvider.onRegisterVisit = { visited.fulfill() }
        await fulfillment(of: [visited], timeout: 0.5)
    }

    private func makeVisitResponse(
        seedBalance: Int = 10,
        levelNumber: Int = 1,
        earnedTowardsNextLevel: Int = 0,
        toUnlockNextLevel: Int = 100
    ) -> AccountVisitResponse {
        let timestamp = "2024-12-07T10:50:26Z"
        let level = AccountVisitResponse.Level(
            number: levelNumber,
            totalGrowthPointsRequired: 0,
            seedsRewardedForLevelUp: 1,
            growthPointsToUnlockNextLevel: toUnlockNextLevel,
            growthPointsEarnedTowardsNextLevel: earnedTowardsNextLevel
        )
        return AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: seedBalance,
                totalAmount: seedBalance,
                previousTotalAmount: seedBalance,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 0,
                totalAmount: 0,
                previousTotalAmount: 0,
                level: level,
                previousLevel: level,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )
    }
}
