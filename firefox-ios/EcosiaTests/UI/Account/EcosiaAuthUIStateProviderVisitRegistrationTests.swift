// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

private struct StubAuthState: EcosiaAuthStateReading {
    var isLoggedIn = true
    var hasResolvedAuthState = true
    var accessToken: String? = "access-token"
    var userProfile: UserProfile?
}

private actor VisitRecorder {
    private(set) var tokens: [String] = []

    func record(_ accessToken: String) {
        tokens.append(accessToken)
    }
}

private struct RecordingAccountsProvider: AccountsProviderProtocol {
    let recorder = VisitRecorder()
    var onRegister: (@Sendable () -> Void)?

    func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        await recorder.record(accessToken)
        onRegister?()
        return .stub
    }
}

private extension AccountVisitResponse {
    static var stub: AccountVisitResponse {
        let timestamp = "2026-09-22T10:00:00Z"
        let level = Level(number: 1,
                          totalGrowthPointsRequired: 0,
                          seedsRewardedForLevelUp: 1,
                          growthPointsToUnlockNextLevel: 75,
                          growthPointsEarnedTowardsNextLevel: 25)
        return AccountVisitResponse(
            seeds: Seeds(balanceAmount: 3,
                         totalAmount: 3,
                         previousTotalAmount: 3,
                         isModified: false,
                         lastVisitAt: timestamp,
                         updatedAt: timestamp),
            growthPoints: GrowthPoints(balanceAmount: 25,
                                       totalAmount: 25,
                                       previousTotalAmount: 25,
                                       level: level,
                                       previousLevel: level,
                                       isModified: false,
                                       lastVisitAt: timestamp,
                                       updatedAt: timestamp)
        )
    }
}

@MainActor
final class EcosiaAuthUIStateProviderVisitRegistrationTests: XCTestCase {

    private func authStateLoadedNotification() -> Notification {
        Notification(name: .EcosiaAuthStateChanged,
                     object: nil,
                     userInfo: ["actionType": EcosiaAuthActionType.authStateLoaded])
    }

    // MARK: - The explicit post-authentication entry point

    func test_handleSuccessfulAuthentication_registersVisitWithCurrentToken() async {
        let registered = expectation(description: "visit registered")
        let accounts = RecordingAccountsProvider(onRegister: { registered.fulfill() })
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accounts,
                                                 authState: StubAuthState())

        provider.handleSuccessfulAuthentication()

        await fulfillment(of: [registered], timeout: 1)
        let recorded = await accounts.recorder.tokens
        XCTAssertEqual(recorded, ["access-token"])
    }

    func test_handleSuccessfulAuthentication_doesNotRegisterVisit_withoutAnAccessToken() async {
        let registered = expectation(description: "visit registered")
        registered.isInverted = true
        let accounts = RecordingAccountsProvider(onRegister: { registered.fulfill() })
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accounts,
                                                 authState: StubAuthState(accessToken: nil))

        provider.handleSuccessfulAuthentication()

        await fulfillment(of: [registered], timeout: 0.5)
        let recorded = await accounts.recorder.tokens
        XCTAssertTrue(recorded.isEmpty)
    }

    // MARK: - Refreshes wait for an in-flight authentication

    func test_refreshSeedState_doesNotRegisterVisit_whileAuthenticationIsInFlight() async {
        // userLoggedIn lands as soon as native Auth0 auth completes, so a foreground or NTP
        // appearance during the web session transfer must not register the visit early.
        let registered = expectation(description: "visit registered")
        registered.isInverted = true
        let accounts = RecordingAccountsProvider(onRegister: { registered.fulfill() })
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accounts,
                                                 authState: StubAuthState())

        provider.setAuthenticationInFlight(true)
        provider.refreshSeedState()

        await fulfillment(of: [registered], timeout: 0.5)
        let recorded = await accounts.recorder.tokens
        XCTAssertTrue(recorded.isEmpty)
    }

    func test_refreshSeedState_registersVisit_onceAuthenticationCompletes() async {
        let registered = expectation(description: "visit registered")
        let accounts = RecordingAccountsProvider(onRegister: { registered.fulfill() })
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accounts,
                                                 authState: StubAuthState())

        provider.setAuthenticationInFlight(true)
        provider.refreshSeedState()
        provider.setAuthenticationInFlight(false)
        provider.refreshSeedState()

        await fulfillment(of: [registered], timeout: 1)
        let recorded = await accounts.recorder.tokens
        XCTAssertEqual(recorded.count, 1)
    }

    // MARK: - One launch resolution registers one visit, however many windows

    func test_authStateLoaded_registersASingleVisit_whenDispatchedPerWindow() async {
        // dispatchAuthState posts the notification once per registered browser window, and this
        // provider is a single observer of all of them.
        let registered = expectation(description: "visit registered")
        let accounts = RecordingAccountsProvider(onRegister: { registered.fulfill() })
        let provider = EcosiaAuthUIStateProvider(
            accountsProvider: accounts,
            authState: StubAuthState(hasResolvedAuthState: false)
        )

        provider.refreshSeedState() // Defers: auth state has not resolved yet

        await provider.handleAuthStateChange(authStateLoadedNotification())
        await provider.handleAuthStateChange(authStateLoadedNotification())

        await fulfillment(of: [registered], timeout: 1)
        let recorded = await accounts.recorder.tokens
        XCTAssertEqual(recorded.count, 1)
    }
}
