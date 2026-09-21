// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

@MainActor
final class EcosiaAuthUIStateProviderTests: XCTestCase {

    private var cache: MockImpactCache!
    private var accountsProvider: MockAccountsProvider!

    override func setUp() {
        super.setUp()
        cache = MockImpactCache()
        accountsProvider = MockAccountsProvider()
        // The once-per-day gate lives in real UserDefaults (not the injected cache), so it must be
        // cleared explicitly to keep tests from leaking daily-collection state into each other.
        LoggedOutSeedProgressManager(cache: cache, authenticationService: ImpactTestAuth.makeLoggedOut()).resetLastAppOpenDateForTesting()
    }

    override func tearDown() {
        LoggedOutSeedProgressManager(cache: cache, authenticationService: ImpactTestAuth.makeLoggedOut()).resetLastAppOpenDateForTesting()
        accountsProvider = nil
        cache = nil
        super.tearDown()
    }

    // MARK: - Brand new user (nothing cached, never logged in)

    func test_init_loggedOut_brandNewUser_startsAtZero() {
        let auth = ImpactTestAuth.makeLoggedOut()

        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        XCTAssertFalse(provider.isLoggedIn)
        XCTAssertEqual(provider.seedCount, 0)
        XCTAssertEqual(provider.currentLevelNumber, 1)
    }

    // MARK: - Cold app start with an existing logged-in session
    //
    // `makeColdLaunchLoggedIn` awaits the auth service settling into its logged-in state before
    // returning, which means (purely as a test-construction artifact) that transition's real
    // notification has already fired by the time the provider below starts observing - in the real
    // app the provider is already alive and observing well before credential retrieval resolves.
    // Re-posting `.userLoggedIn` compensates for that ordering gap.

    func test_coldLaunch_withStoredSession_resolvesToServerBalance_withoutFalseAnimation() async {
        // Given a device that already has a valid session stored from a previous launch
        let auth = await ImpactTestAuth.makeColdLaunchLoggedIn(sub: "auth0|returning-user", accessToken: "stored-token")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 250, levelNumber: 6))

        // When the app cold-starts and constructs its account/impact state
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)
        XCTAssertTrue(provider.isLoggedIn, "Cold launch must resolve isLoggedIn synchronously from the retrieved session")

        // Then the real balance is fetched and applied shortly after, without a false animation
        postAuthStateChanged(.userLoggedIn)
        await waitUntil { provider.seedCount == 250 }

        XCTAssertEqual(provider.currentLevelNumber, 6)
        XCTAssertNil(provider.balanceIncrement, "Revealing a pre-existing balance on cold launch must not animate as a fresh earn")
    }

    // MARK: - Cold-launch flicker: optimistic same-frame guess from the shared cache

    func test_coldLaunch_optimisticallyShowsCachedLoggedInBalance_beforeAuthResolves() {
        // Given a device with a plausibly-stored session (a refresh token exists) and a cache still
        // tagged to that user from last time - constructed synchronously, with nothing awaited, so
        // EcosiaAuthenticationService's own async credential-retrieval Task from its init has had no
        // chance to run yet: isLoggedIn is still false, exactly like the real cold-launch window.
        let mockProvider = MockAuth0Provider()
        mockProvider.hasStoredCredentials = true
        let auth = EcosiaAuthenticationService(auth0Provider: mockProvider)
        auth.skipUserInfoFetch = true
        XCTAssertFalse(auth.isLoggedIn, "Precondition: isLoggedIn hasn't resolved yet")
        XCTAssertTrue(auth.hasStoredSession, "Precondition: a session is plausibly stored")
        cache.stored = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.5, loggedInUserID: "auth0|returning-user")

        // When the provider resolves its initial state
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        // Then it shows the cached logged-in balance immediately, not the guest's zero
        XCTAssertEqual(provider.seedCount, 120)
        XCTAssertEqual(provider.currentLevelNumber, 4)
    }

    func test_coldLaunch_withNoStoredSession_doesNotGuessLoggedIn_evenIfCacheIsStale() {
        // A stale logged-in-tagged cache entry (e.g. left behind by a crash) must not be trusted if
        // there's no plausible stored session backing it up.
        let auth = ImpactTestAuth.makeLoggedOut() // hasStoredCredentials defaults to false
        XCTAssertFalse(auth.hasStoredSession)
        cache.stored = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.5, loggedInUserID: "auth0|stale-user")

        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        XCTAssertEqual(provider.seedCount, 0)
    }

    func test_coldLaunch_confirmedLoggedOut_clearsStaleLoggedInCacheEntry() async {
        // Given a stale logged-in-tagged cache entry - however it got there (a wrong optimistic
        // guess, or a previous run that never cleanly logged out)
        cache.stored = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.5, loggedInUserID: "auth0|stale-user")
        let auth = ImpactTestAuth.makeLoggedOut()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        // When the cold-launch credential check confirms we're not actually logged in
        postAuthStateChanged(.authStateLoaded)
        await waitUntil { self.cache.stored?.loggedInUserID == nil }

        // Then the stale entry is cleared and the guest state takes over
        XCTAssertNil(cache.stored?.loggedInUserID)
        XCTAssertEqual(provider.seedCount, 0)
    }

    func test_coldLaunch_asGuest_authStateLoaded_doesNotWipeExistingGuestProgress() async {
        // Regression guard: `.authStateLoaded` fires on EVERY cold launch, logged-in or logged-out.
        // The fix for the stale-guess case above must not reset a guest's own real local progress
        // just because they happen to also be logged out (the overwhelmingly common case).
        cache.stored = ImpactSnapshot(seedCount: 2, currentLevelNumber: 1, currentProgress: 0.4, loggedInUserID: nil)
        let auth = ImpactTestAuth.makeLoggedOut()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)
        XCTAssertEqual(provider.seedCount, 2)

        postAuthStateChanged(.authStateLoaded)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(provider.seedCount, 2, "A guest's existing local progress must never be wiped by a routine authStateLoaded(false)")
    }

    // MARK: - Regression: logout lands on 0, then immediately collects back to 1

    func test_logout_resetsToZero_thenImmediatelyCollectsTodaysSeed() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        try? await auth.logout() // must actually flip isLoggedIn - the notification alone is not the source of truth
        postAuthStateChanged(.userLoggedOut)
        await waitUntil { !provider.isLoggedIn && provider.seedCount == 1 }

        XCTAssertEqual(provider.seedCount, 1, "Logout must not leave the guest stuck at 0 - regression test")
    }

    // MARK: - Regression: no false "+N" animation when a login reveals a pre-existing balance

    func test_login_revealsExistingBalance_withoutFalseIncrementAnimation() async {
        // Given a guest who already has 1 locally-collected seed from a previous day (seeded
        // directly, rather than via refreshSeedState()'s own animated +1 collection, so that
        // animation's own transient balanceIncrement can't be mistaken for one caused by the login
        // below)
        let auth = ImpactTestAuth.makeLoggedOut()
        cache.stored = ImpactSnapshot(seedCount: 1, currentLevelNumber: 1, currentProgress: 0.1, loggedInUserID: nil)
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)
        XCTAssertEqual(provider.seedCount, 1)

        // When that same session logs into an existing account with a much larger real balance, and
        // the backend reports nothing was earned as part of THIS visit (isModified: false) -
        // revealing a pre-existing balance, not a fresh earn.
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 250, seedsModified: false))
        await ImpactTestAuth.logIn(auth, sub: "auth0|existing-user")
        postAuthStateChanged(.userLoggedIn)
        await waitUntil { provider.seedCount == 250 }

        XCTAssertNil(provider.balanceIncrement, "Regression: revealing a pre-existing balance must not fire the +N animation")
        XCTAssertTrue(provider.isLoggedIn)
    }

    // MARK: - Brand new logged-in user (first ever visit, zero balance)

    func test_brandNewLoggedInUser_startsAtZero_noFalseAnimation() async {
        let auth = ImpactTestAuth.makeLoggedOut()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 0, seedsModified: false))
        await ImpactTestAuth.logIn(auth, sub: "auth0|brand-new-user")
        postAuthStateChanged(.userLoggedIn)

        // seedCount starts at 0 already (guest default), so wait on the identity tag landing
        // instead of a seedCount change.
        await waitUntil { self.cache.stored?.loggedInUserID == "auth0|brand-new-user" }

        XCTAssertEqual(provider.seedCount, 0)
        XCTAssertNil(provider.balanceIncrement)
    }

    // MARK: - Changing accounts mid-session

    func test_switchingAccounts_discardsOldUsersBalance_andShowsNewUsersOwnBalance() async {
        let auth = ImpactTestAuth.makeLoggedOut()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        // User A logs in and their balance is fetched and cached
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 40))
        await ImpactTestAuth.logIn(auth, sub: "auth0|user-a")
        postAuthStateChanged(.userLoggedIn)
        await waitUntil { provider.seedCount == 40 }

        // User A logs out, then user B logs in on the same device
        try? await auth.logout()
        postAuthStateChanged(.userLoggedOut)
        await waitUntil { !provider.isLoggedIn }

        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 7))
        await ImpactTestAuth.logIn(auth, sub: "auth0|user-b")
        postAuthStateChanged(.userLoggedIn)
        await waitUntil { provider.isLoggedIn && provider.seedCount == 7 }

        // User B must never see user A's balance, even transiently
        XCTAssertEqual(provider.seedCount, 7)
        XCTAssertEqual(cache.stored?.loggedInUserID, "auth0|user-b")
    }

    // MARK: - registerVisit failure/success toggles hasRegisterVisitError

    func test_registerVisitFailure_setsHasRegisterVisitError() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        accountsProvider.result = .failure(URLError(.notConnectedToInternet))
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        postAuthStateChanged(.userLoggedIn)
        await waitUntil { provider.hasRegisterVisitError }

        XCTAssertTrue(provider.hasRegisterVisitError)
    }

    func test_registerVisitSuccess_clearsHasRegisterVisitError() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 5))
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        postAuthStateChanged(.userLoggedIn)
        await waitUntil { provider.seedCount == 5 }

        XCTAssertFalse(provider.hasRegisterVisitError)
    }

    // MARK: - refreshSeedState() branches correctly

    func test_refreshSeedState_loggedIn_registersVisit() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 9))
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        provider.refreshSeedState()
        await waitUntil { provider.seedCount == 9 }

        XCTAssertEqual(accountsProvider.receivedAccessTokens.count, 1)
    }

    func test_refreshSeedState_loggedOut_collectsLocalSeed_withoutHittingNetwork() async {
        let auth = ImpactTestAuth.makeLoggedOut()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        provider.refreshSeedState()
        await waitUntil { provider.seedCount == 1 }

        XCTAssertTrue(accountsProvider.receivedAccessTokens.isEmpty, "Logged-out refresh must never hit the network")
    }

    // MARK: - isRelevant() filtering across seedCount x isLoggedIn combinations

    func test_apply_ignoresSnapshot_taggedForADifferentLoggedInUser() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)
        let before = provider.seedCount

        postImpactCacheUpdated(snapshot: ImpactSnapshot(seedCount: 999, currentLevelNumber: 1, currentProgress: 0, loggedInUserID: "auth0|someone-else"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(provider.seedCount, before, "A snapshot tagged for a different user must never be applied")
    }

    func test_apply_ignoresGuestSnapshot_whileLoggedIn() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)
        let before = provider.seedCount

        postImpactCacheUpdated(snapshot: .loggedOutZero)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(provider.seedCount, before, "A guest-tagged snapshot must never overwrite a logged-in user's balance")
    }

    func test_apply_acceptsSnapshot_matchingCurrentLoggedInUser() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        postImpactCacheUpdated(snapshot: ImpactSnapshot(seedCount: 30, currentLevelNumber: 2, currentProgress: 0.2, loggedInUserID: "auth0|user-a"))
        await waitUntil { provider.seedCount == 30 }

        XCTAssertEqual(provider.currentLevelNumber, 2)
    }

    func test_apply_ignoresLoggedInSnapshot_whileLoggedOut() async {
        let auth = ImpactTestAuth.makeLoggedOut()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        postImpactCacheUpdated(snapshot: ImpactSnapshot(seedCount: 500, currentLevelNumber: 9, currentProgress: 0.5, loggedInUserID: "auth0|user-a"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(provider.seedCount, 0, "A logged-in-tagged snapshot must never surface while logged out")
    }

    // MARK: - Level up animation only fires on the writer's own signal, never from a diff

    func test_apply_triggersLevelUpAnimation_whenWriterSaysSo() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 10, levelNumber: 3, previousLevelNumber: 2))
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        let levelUpExpectation = expectation(forNotification: .EcosiaAccountLevelUp, object: nil)
        postAuthStateChanged(.userLoggedIn)

        await fulfillment(of: [levelUpExpectation], timeout: 2)
        XCTAssertEqual(provider.currentLevelNumber, 3)
    }

    func test_apply_doesNotTriggerLevelUpAnimation_whenLevelUnchanged() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        accountsProvider.result = .success(ImpactTestFixtures.visitResponse(seedCount: 10, levelNumber: 2, previousLevelNumber: 2))
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        var levelUpFired = false
        let observer = NotificationCenter.default.addObserver(forName: .EcosiaAccountLevelUp, object: nil, queue: .main) { _ in
            levelUpFired = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        postAuthStateChanged(.userLoggedIn)
        await waitUntil { provider.seedCount == 10 }

        XCTAssertFalse(levelUpFired)
    }

    // MARK: - Debug methods

    func test_debugUpdateBalance_appliesSynthesizedResponse_whenLoggedIn() async {
        let auth = await ImpactTestAuth.makeLoggedIn(sub: "auth0|user-a")
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        provider.debugUpdateBalance(ImpactTestFixtures.visitResponse(seedCount: 77, previousSeedCount: 70, seedsModified: true))
        await waitUntil { provider.seedCount == 77 }

        XCTAssertEqual(cache.stored?.loggedInUserID, "auth0|user-a")
    }

    func test_debugUpdateBalance_isNoOp_whenLoggedOut() {
        let auth = ImpactTestAuth.makeLoggedOut()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: accountsProvider, cache: cache, authenticationService: auth)

        provider.debugUpdateBalance(ImpactTestFixtures.visitResponse(seedCount: 77))

        XCTAssertTrue(cache.savedSnapshots.isEmpty)
    }

    // MARK: - Helpers

    private func postImpactCacheUpdated(snapshot: ImpactSnapshot, seedsIncrement: Int? = nil, didLevelUp: Bool = false) {
        var userInfo: [String: Any] = [
            ImpactCache.snapshotUserInfoKey: snapshot,
            ImpactCache.didLevelUpUserInfoKey: didLevelUp
        ]
        if let seedsIncrement {
            userInfo[ImpactCache.seedsIncrementUserInfoKey] = seedsIncrement
        }
        NotificationCenter.default.post(name: .EcosiaImpactCacheUpdated, object: nil, userInfo: userInfo)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
