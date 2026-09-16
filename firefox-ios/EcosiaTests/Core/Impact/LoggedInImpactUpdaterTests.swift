// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

@MainActor
final class LoggedInImpactUpdaterTests: XCTestCase {

    private var cache: MockImpactCache!
    private var accountsProvider: MockAccountsProvider!

    override func setUp() {
        super.setUp()
        cache = MockImpactCache()
        accountsProvider = MockAccountsProvider()
    }

    override func tearDown() {
        accountsProvider = nil
        cache = nil
        super.tearDown()
    }

    // MARK: - Reactive to login

    func test_userLoggedIn_triggersRegisterVisit_andPersistsTaggedResult() async {
        // Given a user who is already logged in with a known id when the updater starts observing
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a", accessToken: "token-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 17))
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)

        // When the login notification fires
        await waitForImpactCacheUpdate { postAuthStateChanged(.userLoggedIn) }

        // Then it registers a visit and persists the tagged result
        XCTAssertEqual(cache.stored?.seedCount, 17)
        XCTAssertEqual(cache.stored?.loggedInUserID, "auth0|user-a")
        XCTAssertEqual(accountsProvider.receivedAccessTokens, ["token-a"])
        _ = updater
    }

    func test_userLoggedIn_withNoUserIdYet_skipsFetch_untilProfileArrives() async {
        // Given: real login sets isLoggedIn=true, but with skipUserInfoFetch, userProfile stays nil
        let auth = ImpactTestAuth.makeLoggedOut()
        try? await auth.login()
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertNil(auth.userProfile, "Precondition: profile not fetched yet")

        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)

        postAuthStateChanged(.userLoggedIn)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(cache.savedSnapshots.isEmpty, "No user id yet - nothing should be fetched")

        // When the profile subsequently arrives
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 4))
        await waitForImpactCacheUpdate {
            auth.setUserProfileForTesting(UserProfile(name: "Late User", email: nil, picture: nil, sub: "auth0|late-user"))
        }

        XCTAssertEqual(cache.stored?.seedCount, 4)
        XCTAssertEqual(cache.stored?.loggedInUserID, "auth0|late-user")
        _ = updater
    }

    // MARK: - refresh() vs automatic dedup (regression: repeated profile updates used to refetch every time)

    func test_refresh_alwaysStartsFreshFetch_evenIfAlreadyAutoFetchedForSameUser() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a", accessToken: "token-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 5))
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)
        await waitForImpactCacheUpdate { postAuthStateChanged(.userLoggedIn) }
        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 1)

        // Regression: an ancillary profile update for the SAME user (e.g. an avatar change) used to
        // restart the fetch every single time - the root cause of a spurious failure toast right on
        // cold launch, when a second profile update raced the first attempt.
        auth.setUserProfileForTesting(UserProfile(name: "Updated Name", email: nil, picture: nil, sub: "auth0|user-a"))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 1, "An ancillary profile update for the same user must not refetch")

        // But an explicit refresh() (NTP appear / foreground) must always fetch again
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 8))
        await waitForImpactCacheUpdate { updater.refresh() }
        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 2)
        XCTAssertEqual(cache.stored?.seedCount, 8)
    }

    // MARK: - Logout cancels in-flight fetch

    func test_userLoggedOut_cancelsInFlightFetch_andDoesNotWriteAnything() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a", accessToken: "token-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 50))
        accountsProvider.delayNanoseconds = 300_000_000 // slow enough to cancel mid-flight
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)

        postAuthStateChanged(.userLoggedIn) // starts the slow fetch
        try? await Task.sleep(nanoseconds: 50_000_000) // let it actually start
        postAuthStateChanged(.userLoggedOut) // cancel before it resolves

        try? await Task.sleep(nanoseconds: 400_000_000) // longer than the original delay
        XCTAssertTrue(cache.savedSnapshots.isEmpty, "A cancelled fetch must never write - the old balance must not appear after logout")
        _ = updater
    }

    func test_cancelledFetch_doesNotPostFailureNotification() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a", accessToken: "token-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 1))
        accountsProvider.delayNanoseconds = 300_000_000
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)
        var failurePosted = false
        let observer = NotificationCenter.default.addObserver(forName: .EcosiaImpactUpdateFailed, object: nil, queue: .main) { _ in
            failurePosted = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        postAuthStateChanged(.userLoggedIn)
        try? await Task.sleep(nanoseconds: 50_000_000)
        postAuthStateChanged(.userLoggedOut)

        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertFalse(failurePosted, "A cancellation is an expected session change, not a failure worth surfacing to the user")
        _ = updater
    }

    // MARK: - Changing accounts mid-flight

    func test_switchingActiveUser_discardsStaleResponse_andPersistsNewUsersOwnFetch() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a", accessToken: "token-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 999))
        accountsProvider.delayNanoseconds = 200_000_000
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)

        postAuthStateChanged(.userLoggedIn) // starts a slow fetch for user-a
        try? await Task.sleep(nanoseconds: 50_000_000)

        // The active identity switches to a different user while user-a's request is still in flight
        accountsProvider.delayNanoseconds = 0
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 3))
        await waitForImpactCacheUpdate {
            auth.setUserProfileForTesting(UserProfile(name: "User B", email: nil, picture: nil, sub: "auth0|user-b"))
        }

        XCTAssertEqual(cache.stored?.seedCount, 3, "user-b's own fetch must win")
        XCTAssertEqual(cache.stored?.loggedInUserID, "auth0|user-b")

        try? await Task.sleep(nanoseconds: 300_000_000) // give user-a's original (stale) response time to resolve
        XCTAssertEqual(cache.stored?.seedCount, 3, "user-a's stale response must never overwrite user-b's real balance")
        _ = updater
    }

    // MARK: - Failure posts .EcosiaImpactUpdateFailed

    func test_registerVisitFailure_postsFailureNotification_andDoesNotWriteCache() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a", accessToken: "token-a")
        accountsProvider.result = .failure(URLError(.notConnectedToInternet))
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)

        await waitForImpactUpdateFailure { postAuthStateChanged(.userLoggedIn) }

        XCTAssertTrue(cache.savedSnapshots.isEmpty)
        _ = updater
    }

    // MARK: - No access token yet

    func test_noAccessToken_skipsFetch_silently() async {
        // A logged-in state with no access token yet (e.g. mid-renewal) must not attempt a visit or
        // surface an error - it's a transient state, not a failure.
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a", accessToken: "")
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: auth)

        postAuthStateChanged(.userLoggedIn)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(accountsProvider.receivedAccessTokens.isEmpty)
        XCTAssertTrue(cache.savedSnapshots.isEmpty)
        _ = updater
    }

    // MARK: - cachedSnapshot(for:) / debugApply

    func test_cachedSnapshot_returnsNil_whenCacheBelongsToADifferentUser() {
        cache.stored = ImpactSnapshot(seedCount: 10, currentLevelNumber: 1, currentProgress: 0, loggedInUserID: "auth0|user-a")
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: ImpactTestAuth.makeLoggedOut())

        XCTAssertNil(updater.cachedSnapshot(for: "auth0|user-b"))
    }

    func test_cachedSnapshot_returnsSnapshot_whenItBelongsToTheRequestedUser() {
        let snapshot = ImpactSnapshot(seedCount: 10, currentLevelNumber: 1, currentProgress: 0, loggedInUserID: "auth0|user-a")
        cache.stored = snapshot
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: ImpactTestAuth.makeLoggedOut())

        XCTAssertEqual(updater.cachedSnapshot(for: "auth0|user-a"), snapshot)
    }

    func test_debugApply_persistsResponseTaggedWithGivenUserID() async {
        let updater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: ImpactTestAuth.makeLoggedOut())
        let response = ImpactTestFixtures.visitResponse(seedCount: 12, levelNumber: 2, previousLevelNumber: 1)

        await waitForImpactCacheUpdate {
            updater.debugApply(response, userID: "auth0|user-a")
        }

        XCTAssertEqual(cache.stored?.seedCount, 12)
        XCTAssertEqual(cache.stored?.loggedInUserID, "auth0|user-a")
        XCTAssertEqual(cache.lastDidLevelUp, true)
    }
}
