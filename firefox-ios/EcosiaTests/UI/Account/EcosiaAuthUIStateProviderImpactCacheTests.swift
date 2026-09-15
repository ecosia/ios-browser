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
    }

    override func tearDown() {
        EcosiaAuthUIStateProvider.loggedInImpactCacheType = LoggedInImpactCache.self
        MockLoggedInImpactCache.reset()
        super.tearDown()
    }

    // MARK: - resolveInitialImpactSnapshot (cold-init read)

    func test_resolveInitialSnapshot_returnsCachedValues_whenLoggedInAndCacheHit() {
        let snapshot = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        MockLoggedInImpactCache.save(snapshot)

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true, userId: "auth0|user-a")

        XCTAssertEqual(resolved, snapshot)
    }

    func test_resolveInitialSnapshot_prefersCachedSnapshot_whileAuthStateStillResolving() {
        // isLoggedIn/userId can still read false/nil at cold launch while auth state resolves
        // (the keychain/userinfo calls haven't completed yet) for a user who really is logged in.
        // A cached snapshot from last session must be shown immediately regardless, not the
        // logged-out number - otherwise a returning logged-in user sees exactly the flash this
        // resolver exists to prevent.
        let snapshot = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        MockLoggedInImpactCache.save(snapshot)

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: false, userId: nil)

        XCTAssertEqual(resolved, snapshot)
    }

    func test_resolveInitialSnapshot_returnsLocalManagerSnapshot_whenLoggedOutWithNoCache() {
        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: false, userId: nil)

        // Compared against a live call rather than a hardcoded literal, since
        // SeedProgressManager.calculateInnerProgress() depends on seedCounterConfig,
        // which other test files may have set - this stays correct regardless of test order.
        XCTAssertEqual(resolved, SeedProgressManager.currentSnapshot())
    }

    func test_resolveInitialSnapshot_returnsNil_whenLoggedInButNoCacheEntry() {
        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true, userId: "auth0|first-time-user")

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

    // MARK: - clearOnLogout shared vocabulary

    func test_clearOnLogout_isEquivalentToClear() {
        MockLoggedInImpactCache.save(ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8))

        MockLoggedInImpactCache.clearOnLogout()

        XCTAssertEqual(MockLoggedInImpactCache.clearCallCount, 1, "clearOnLogout() should delegate straight to clear()")
        XCTAssertNil(MockLoggedInImpactCache.load())
    }
}
