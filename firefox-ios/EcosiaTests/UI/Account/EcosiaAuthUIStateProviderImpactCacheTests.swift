// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

@MainActor
final class EcosiaAuthUIStateProviderImpactCacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockLoggedInImpactCache.reset()
        ImpactManager.loggedInImpactCacheType = MockLoggedInImpactCache.self
        EcosiaAuthenticationService.wasLoggedIn = false
    }

    override func tearDown() {
        ImpactManager.loggedInImpactCacheType = LoggedInImpactCache.self
        MockLoggedInImpactCache.reset()
        EcosiaAuthenticationService.wasLoggedIn = false
        super.tearDown()
    }

    // MARK: - resolveInitialImpactSnapshot (cold-init read)

    func test_resolveInitialSnapshot_returnsCachedValues_whenLoggedInAndCacheHit() {
        let snapshot = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        MockLoggedInImpactCache.save(snapshot)

        let resolved = ImpactManager.resolveInitialImpactSnapshot(isLoggedIn: true)

        XCTAssertEqual(resolved, snapshot)
    }

    func test_resolveInitialSnapshot_prefersCachedSnapshot_whileAuthStateStillResolving() {
        // isLoggedIn can still read false at cold launch while auth state resolves (the keychain
        // check hasn't completed yet) for a user who really is logged in. A cached snapshot from
        // last session must be shown immediately regardless of that stale reading - otherwise a
        // returning logged-in user sees exactly the flash this resolver exists to prevent.
        let snapshot = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        MockLoggedInImpactCache.save(snapshot)

        let resolved = ImpactManager.resolveInitialImpactSnapshot(isLoggedIn: false)

        XCTAssertEqual(resolved, snapshot)
    }

    func test_resolveInitialSnapshot_returnsLocalManagerSnapshot_whenLoggedOutWithNoCache() {
        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        UserDefaultsSeedProgressManager.addSeeds(2)

        let resolved = ImpactManager.resolveInitialImpactSnapshot(isLoggedIn: false)

        XCTAssertEqual(resolved?.seedCount, 2)
        XCTAssertEqual(resolved?.currentLevelNumber, 1)
    }

    func test_resolveInitialSnapshot_returnsNil_whenLoggedInButNoCacheEntry() {
        let resolved = ImpactManager.resolveInitialImpactSnapshot(isLoggedIn: true)

        XCTAssertNil(resolved)
    }

    // MARK: - Logout clears the cache (via the auth event stream)

    func test_loggedOutEvent_clearsLoggedInImpactCache() {
        MockLoggedInImpactCache.save(ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8))
        let auth = MockAuthSessionProvider(hasResolvedAuthState: true)
        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider(), auth: auth)

        withExtendedLifetime(provider) {
            auth.send(.loggedOut)
        }

        XCTAssertEqual(MockLoggedInImpactCache.clearCallCount, 1)
    }

    // MARK: - Auth events move the published isLoggedIn mirror

    func test_authEvents_updateIsLoggedIn() {
        let auth = MockAuthSessionProvider()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider(), auth: auth)

        auth.send(.stateResolved(isLoggedIn: true))
        XCTAssertTrue(provider.isLoggedIn)

        auth.send(.loggedOut)
        XCTAssertFalse(provider.isLoggedIn)

        auth.send(.loggedIn)
        XCTAssertTrue(provider.isLoggedIn)
    }

    // MARK: - stateResolved refreshes published state from the current snapshot

    func test_stateResolvedEvent_refreshesAwayFromStaleCachedSnapshot_onceCacheIsCleared() {
        // Simulates init() running while a previous account's snapshot was still cached (the
        // async gap before EcosiaAuthenticationService's own clear completes) - the provider
        // should move off that stale value once .stateResolved confirms logged-out and the
        // cache is (by then, cleared by the service itself) empty.
        MockLoggedInImpactCache.save(ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8))
        let auth = MockAuthSessionProvider()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider(), auth: auth)
        XCTAssertEqual(provider.seedCount, 120, "Sanity check: init picked up the stale cache")

        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        UserDefaultsSeedProgressManager.addSeeds(2)
        MockLoggedInImpactCache.reset() // Simulates EcosiaAuthenticationService already clearing it

        auth.send(.stateResolved(isLoggedIn: false))

        XCTAssertEqual(provider.seedCount, 2)
        XCTAssertEqual(provider.currentLevelNumber, 1)
    }

    func test_stateResolvedEvent_isNoOp_forAnOrdinaryGuest() {
        // A guest resolves to .stateResolved(isLoggedIn: false) on every single cold launch too -
        // this must not disturb their own accumulated local progress.
        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        UserDefaultsSeedProgressManager.addSeeds(1)

        let auth = MockAuthSessionProvider()
        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider(), auth: auth)

        auth.send(.stateResolved(isLoggedIn: false))

        XCTAssertEqual(provider.seedCount, 1)
    }
}
