// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

/// Records calls instead of touching real `UserDefaults`, so tests don't depend on
/// `EcosiaAuthenticationService.shared`'s live (unmockable) singleton state.
private final class MockLoggedInImpactCache: LoggedInImpactCacheProtocol {
    nonisolated(unsafe) static var stored: ImpactSnapshot?
    nonisolated(unsafe) static var clearCallCount = 0

    static func load() -> ImpactSnapshot? {
        stored
    }

    static func save(_ snapshot: ImpactSnapshot) {
        stored = snapshot
    }

    static func clear() {
        clearCallCount += 1
        stored = nil
    }

    static func reset() {
        stored = nil
        clearCallCount = 0
    }
}

@MainActor
final class EcosiaAuthUIStateProviderImpactCacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockLoggedInImpactCache.reset()
        EcosiaAuthUIStateProvider.loggedInImpactCacheType = MockLoggedInImpactCache.self
        EcosiaAuthenticationService.wasLoggedIn = false
    }

    override func tearDown() {
        EcosiaAuthUIStateProvider.loggedInImpactCacheType = LoggedInImpactCache.self
        MockLoggedInImpactCache.reset()
        EcosiaAuthenticationService.wasLoggedIn = false
        super.tearDown()
    }

    // MARK: - resolveInitialImpactSnapshot (cold-init read)

    func test_resolveInitialSnapshot_returnsCachedValues_whenLoggedInAndCacheHit() {
        let snapshot = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        MockLoggedInImpactCache.save(snapshot)

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true)

        XCTAssertEqual(resolved, snapshot)
    }

    func test_resolveInitialSnapshot_prefersCachedSnapshot_whileAuthStateStillResolving() {
        // isLoggedIn can still read false at cold launch while auth state resolves (the keychain
        // check hasn't completed yet) for a user who really is logged in. A cached snapshot from
        // last session must be shown immediately regardless of that stale reading - otherwise a
        // returning logged-in user sees exactly the flash this resolver exists to prevent.
        let snapshot = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        MockLoggedInImpactCache.save(snapshot)

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: false)

        XCTAssertEqual(resolved, snapshot)
    }

    func test_resolveInitialSnapshot_returnsLocalManagerSnapshot_whenLoggedOutWithNoCache() {
        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        UserDefaultsSeedProgressManager.addSeeds(2)

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: false)

        XCTAssertEqual(resolved?.seedCount, 2)
        XCTAssertEqual(resolved?.currentLevelNumber, 1)
    }

    func test_resolveInitialSnapshot_returnsNil_whenLoggedInButNoCacheEntry() {
        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true)

        XCTAssertNil(resolved)
    }

    // MARK: - Logout clears the cache (via the real notification flow)

    func test_userLoggedOutNotification_clearsLoggedInImpactCache() async {
        MockLoggedInImpactCache.save(ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8))

        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider())
        let notification = Notification(
            name: .EcosiaAuthStateChanged,
            object: nil,
            userInfo: ["actionType": EcosiaAuthActionType.userLoggedOut]
        )
        await provider.handleAuthStateChange(notification)

        XCTAssertEqual(MockLoggedInImpactCache.clearCallCount, 1)
    }

    // MARK: - authStateLoaded refreshes published state from the current snapshot

    func test_authStateLoadedNotification_refreshesAwayFromStaleCachedSnapshot_onceCacheIsCleared() async {
        // Simulates init() running while a previous account's snapshot was still cached (the
        // async gap before EcosiaAuthenticationService's own clear completes) - the provider
        // should move off that stale value once authStateLoaded confirms logged-out and the
        // cache is (by then, cleared by the service itself) empty.
        MockLoggedInImpactCache.save(ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8))
        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider())
        XCTAssertEqual(provider.seedCount, 120, "Sanity check: init picked up the stale cache")

        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        UserDefaultsSeedProgressManager.addSeeds(2)
        MockLoggedInImpactCache.reset() // Simulates EcosiaAuthenticationService already clearing it

        let notification = Notification(
            name: .EcosiaAuthStateChanged,
            object: nil,
            userInfo: ["actionType": EcosiaAuthActionType.authStateLoaded]
        )
        await provider.handleAuthStateChange(notification)

        XCTAssertEqual(provider.seedCount, 2)
        XCTAssertEqual(provider.currentLevelNumber, 1)
    }

    func test_authStateLoadedNotification_isNoOp_forAnOrdinaryGuest() async {
        // A guest resolves to authStateLoaded/isLoggedIn=false on every single cold launch too -
        // this must not disturb their own accumulated local progress.
        UserDefaultsSeedProgressManager.resetLocalSeedProgress()
        UserDefaultsSeedProgressManager.addSeeds(1)

        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider())
        let notification = Notification(
            name: .EcosiaAuthStateChanged,
            object: nil,
            userInfo: ["actionType": EcosiaAuthActionType.authStateLoaded]
        )
        await provider.handleAuthStateChange(notification)

        XCTAssertEqual(provider.seedCount, 1)
    }
}
