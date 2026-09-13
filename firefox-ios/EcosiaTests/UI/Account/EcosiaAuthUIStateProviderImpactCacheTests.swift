// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

/// Records calls instead of touching real `UserDefaults`. Each test builds its own instance and
/// hands it to a fresh `ImpactManager`, so it never overlaps with `EcosiaAuthUIStateProvider.shared`'s
/// own (real, `ImpactCache`-backed) `ImpactManager` - even if `.shared` is alive
/// elsewhere in the test process and reacts to the same `NotificationCenter` post, it does so
/// through a completely different cache instance and never touches this one.
///
/// `@unchecked Sendable`: `ImpactCacheProtocol` requires `Sendable` since `ImpactManager` crosses
/// actor boundaries, but this mock's mutable state is only ever touched from one test's own
/// single-threaded flow (never actually shared across concurrency domains).
private final class MockImpactCache: ImpactCacheProtocol, @unchecked Sendable {
    private(set) var stored: ImpactSnapshot?
    private(set) var clearCallCount = 0
    var onClear: (() -> Void)?

    func load() -> ImpactSnapshot? {
        stored
    }

    func save(_ snapshot: ImpactSnapshot) {
        stored = snapshot
    }

    func clear() {
        clearCallCount += 1
        stored = nil
        onClear?()
    }
}

@MainActor
final class EcosiaAuthUIStateProviderImpactCacheTests: XCTestCase {

    // MARK: - loadSeeds (cold-init read)

    func test_loadSeeds_returnsCachedValues_whenCacheHit() {
        let mockCache = MockImpactCache()
        let impactManager = ImpactManager(cache: mockCache)
        let snapshot = ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8)
        mockCache.save(snapshot)

        let resolved = impactManager.loadSeeds(isLoggedIn: true, userId: "auth0|user-a")

        XCTAssertEqual(resolved, snapshot, "A cached snapshot must be returned as-is")
    }

    func test_loadSeeds_returnsZero_whenLoggedInButUserIdNotYetLoaded() {
        let mockCache = MockImpactCache()
        let impactManager = ImpactManager(cache: mockCache)
        // A real transient window: auth state has flipped to logged in, but the profile (and so
        // userId) hasn't arrived yet. This must show a neutral placeholder, not the guest's own
        // accumulated local seed count - which would otherwise flash under the new account.
        impactManager.debugAddLoggedOutSeeds(2)

        let resolved = impactManager.loadSeeds(isLoggedIn: true, userId: nil)

        XCTAssertEqual(resolved, .zero, "isLoggedIn=true with no userId yet must never show the guest's own snapshot")
    }

    func test_loadSeeds_returnsDefaultWithoutPersisting_whenNoCacheEntry() {
        let mockCache = MockImpactCache()
        let impactManager = ImpactManager(cache: mockCache)

        let resolved = impactManager.loadSeeds(isLoggedIn: true, userId: "auth0|first-time-user")

        XCTAssertEqual(resolved, .zero)
        let notPersistedMessage = "loadSeeds is a pure read - it must not write a placeholder into the cache; a fresh user's first seed should still animate in from 0 once updateSeeds fetches it"
        XCTAssertNil(mockCache.load(), notPersistedMessage)
    }

    // MARK: - debugUpdateBalance only persists while actually logged in with a known user id

    func test_debugUpdateBalance_persists_whenLoggedInWithUserId() {
        let mockCache = MockImpactCache()
        let impactManager = ImpactManager(cache: mockCache)
        let response = Self.makeVisitResponse(seedCount: 5, level: 2)

        let snapshot = impactManager.debugUpdateBalance(response, isLoggedIn: true, userId: "auth0|user-a")

        XCTAssertEqual(mockCache.load(), snapshot)
    }

    func test_debugUpdateBalance_doesNotPersist_whenLoggedOut() {
        let mockCache = MockImpactCache()
        let impactManager = ImpactManager(cache: mockCache)
        let response = Self.makeVisitResponse(seedCount: 5, level: 2)

        // A logged-in-shaped snapshot must never land in the guest's own local seed count - even
        // if debugUpdateBalance() is triggered while logged out.
        _ = impactManager.debugUpdateBalance(response, isLoggedIn: false, userId: nil)

        let guestSnapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        XCTAssertNotEqual(guestSnapshot.seedCount, 5, "A logged-out debug update must not corrupt the guest's local seed count")
    }

    func test_debugUpdateBalance_doesNotPersist_whenLoggedInButNoUserId() {
        let mockCache = MockImpactCache()
        let impactManager = ImpactManager(cache: mockCache)
        let response = Self.makeVisitResponse(seedCount: 5, level: 2)

        // A transient isLoggedIn=true/userId=nil state (profile not loaded yet) must not persist either.
        _ = impactManager.debugUpdateBalance(response, isLoggedIn: true, userId: nil)

        XCTAssertNil(mockCache.load(), "A nil userId must not be persisted")
    }

    // MARK: - Logout clears the cache (via the real notification flow)

    func test_userLoggedOutNotification_clearsImpactCache() {
        let mockCache = MockImpactCache()
        mockCache.save(ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8))

        let expectation = expectation(description: "impact cache cleared on logout")
        mockCache.onClear = { expectation.fulfill() }

        let provider = EcosiaAuthUIStateProvider(accountsProvider: AccountsProvider(), impactManager: ImpactManager(cache: mockCache))
        NotificationCenter.default.post(
            name: .EcosiaAuthStateChanged,
            object: nil,
            userInfo: ["actionType": EcosiaAuthActionType.userLoggedOut]
        )

        wait(for: [expectation], timeout: 2.0)
        // Exactly 1, not "at least 1": this mock is only reachable through this test's own
        // ImpactManager instance - EcosiaAuthUIStateProvider.shared (which may also be alive in
        // the test process and observe the same NotificationCenter post) holds its own separate
        // ImpactManager/ImpactCache pair and never touches this mock.
        XCTAssertEqual(mockCache.clearCallCount, 1)
        // Referenced here (rather than discarded right after creation) so ARC keeps `provider`,
        // and therefore its notification observers, alive for the whole wait above.
        XCTAssertNotNil(provider)
    }

    // MARK: - clearOnLogout shared vocabulary

    func test_clearOnLogout_isEquivalentToClear() {
        let mockCache = MockImpactCache()
        mockCache.save(ImpactSnapshot(seedCount: 120, currentLevelNumber: 4, currentProgress: 0.8))

        mockCache.clearOnLogout()

        XCTAssertEqual(mockCache.clearCallCount, 1, "clearOnLogout() should delegate straight to clear()")
        XCTAssertNil(mockCache.load())
    }

    // MARK: - Fixtures

    private static func makeVisitResponse(seedCount: Int, level: Int) -> AccountVisitResponse {
        let timestamp = "2024-12-07T10:50:26Z"
        let noProgressLevel = AccountVisitResponse.Level(
            number: level,
            totalGrowthPointsRequired: 0,
            seedsRewardedForLevelUp: 0,
            growthPointsToUnlockNextLevel: 0,
            growthPointsEarnedTowardsNextLevel: 0
        )
        return AccountVisitResponse(
            seeds: AccountVisitResponse.Seeds(
                balanceAmount: seedCount,
                totalAmount: seedCount,
                previousTotalAmount: seedCount,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            ),
            growthPoints: AccountVisitResponse.GrowthPoints(
                balanceAmount: 0,
                totalAmount: 0,
                previousTotalAmount: 0,
                level: noProgressLevel,
                previousLevel: noProgressLevel,
                isModified: false,
                lastVisitAt: timestamp,
                updatedAt: timestamp
            )
        )
    }
}
