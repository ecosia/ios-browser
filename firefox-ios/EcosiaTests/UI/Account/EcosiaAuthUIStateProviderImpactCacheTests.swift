// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

/// Records calls instead of touching real `UserDefaults`, so tests don't depend on
/// `EcosiaAuthenticationService.shared`'s live (unmockable) singleton state.
private final class MockLoggedInImpactCache: LoggedInImpactCacheProtocol {
    nonisolated(unsafe) static var stored: [String: LoggedInImpactSnapshot] = [:]
    nonisolated(unsafe) static var clearCallCount = 0
    nonisolated(unsafe) static var onClear: (() -> Void)?

    static func load(forUserId userId: String) -> LoggedInImpactSnapshot? {
        stored[userId]
    }

    static func save(_ snapshot: LoggedInImpactSnapshot, userId: String) {
        stored[userId] = snapshot
    }

    static func clear() {
        clearCallCount += 1
        stored.removeAll()
        onClear?()
    }

    static func reset() {
        stored.removeAll()
        clearCallCount = 0
        onClear = nil
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
        EcosiaAuthUIStateProvider.loggedInImpactCacheType = UserDefaultsLoggedInImpactCache.self
        MockLoggedInImpactCache.reset()
        super.tearDown()
    }

    // MARK: - resolveInitialImpactSnapshot (cold-init read)

    func test_resolveInitialSnapshot_returnsCachedValues_whenLoggedInAndCacheHit() {
        let snapshot = LoggedInImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        MockLoggedInImpactCache.save(snapshot, userId: "auth0|user-a")

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true, userId: "auth0|user-a")

        XCTAssertEqual(resolved, snapshot, "A logged-in user with a cached snapshot must not fall back to the logged-out default")
    }

    func test_resolveInitialSnapshot_returnsNil_whenLoggedOut() {
        MockLoggedInImpactCache.save(
            LoggedInImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8),
            userId: "auth0|user-a"
        )

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: false, userId: "auth0|user-a")

        XCTAssertNil(resolved, "Logged-out users must keep using the local UserDefaultsSeedProgressManager value")
    }

    func test_resolveInitialSnapshot_returnsNil_whenNoUserId() {
        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true, userId: nil)

        XCTAssertNil(resolved)
    }

    func test_resolveInitialSnapshot_returnsNil_whenLoggedInButNoCacheEntry() {
        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true, userId: "auth0|first-time-user")

        XCTAssertNil(resolved)
    }

    func test_resolveInitialSnapshot_returnsNil_forDifferentUsersCachedEntry() {
        MockLoggedInImpactCache.save(
            LoggedInImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8),
            userId: "auth0|previous-user"
        )

        let resolved = EcosiaAuthUIStateProvider.resolveInitialImpactSnapshot(isLoggedIn: true, userId: "auth0|new-user")

        XCTAssertNil(resolved, "A newly logged-in account must not briefly show a previous account's numbers")
    }

    // MARK: - Logout clears the cache (via the real notification flow)

    func test_userLoggedOutNotification_clearsLoggedInImpactCache() {
        MockLoggedInImpactCache.save(
            LoggedInImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8),
            userId: "auth0|user-a"
        )

        let expectation = expectation(description: "logged-in impact cache cleared on logout")
        MockLoggedInImpactCache.onClear = { expectation.fulfill() }

        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider())
        NotificationCenter.default.post(
            name: .EcosiaAuthStateChanged,
            object: nil,
            userInfo: ["actionType": EcosiaAuthActionType.userLoggedOut]
        )

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(MockLoggedInImpactCache.clearCallCount, 1)
        // Referenced here (rather than discarded right after creation) so ARC keeps `provider`,
        // and therefore its notification observers, alive for the whole wait above.
        XCTAssertNotNil(provider)
    }
}
