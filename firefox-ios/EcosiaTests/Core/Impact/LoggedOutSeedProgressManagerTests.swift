// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

@MainActor
final class LoggedOutSeedProgressManagerTests: XCTestCase {

    private var cache: MockImpactCache!
    private var manager: LoggedOutSeedProgressManager!

    override func setUp() {
        super.setUp()
        cache = MockImpactCache()
        manager = LoggedOutSeedProgressManager(cache: cache, authenticationService: ImpactTestAuth.makeLoggedOut())
        // The once-per-day gate lives in real UserDefaults (not the injected cache), so it must be
        // cleared explicitly to keep tests from leaking daily-collection state into each other.
        manager.resetLastAppOpenDateForTesting()
    }

    override func tearDown() {
        manager.resetLastAppOpenDateForTesting()
        manager = nil
        cache = nil
        super.tearDown()
    }

    // MARK: - load (brand new user)

    func test_load_returnsZero_whenNothingCached() {
        let snapshot = manager.load()

        XCTAssertEqual(snapshot.seedCount, 0)
        XCTAssertEqual(snapshot.currentLevelNumber, 1)
        XCTAssertNil(snapshot.loggedInUserID)
    }

    func test_load_returnsZero_whenCacheHoldsALoggedInUsersSnapshot() {
        // Given the shared slot currently holds a logged-in user's data
        cache.stored = ImpactSnapshot(seedCount: 500, currentLevelNumber: 8, currentProgress: 0.9, loggedInUserID: "auth0|someone-else")

        // When the guest reads its own progress
        let snapshot = manager.load()

        // Then it must never see the logged-in user's numbers
        XCTAssertEqual(snapshot.seedCount, 0)
        XCTAssertNil(snapshot.loggedInUserID)
    }

    // MARK: - collectDailySeedIfDue

    func test_collectDailySeedIfDue_collectsOnFirstCall() {
        manager.collectDailySeedIfDue()

        XCTAssertEqual(manager.load().seedCount, 1)
        XCTAssertEqual(cache.lastSeedsIncrement, 1)
    }

    func test_collectDailySeedIfDue_isNoOp_onSecondCallSameDay() {
        manager.collectDailySeedIfDue()
        let writeCountAfterFirstCall = cache.savedSnapshots.count

        manager.collectDailySeedIfDue()

        XCTAssertEqual(manager.load().seedCount, 1, "A second collection on the same day must not add another seed")
        XCTAssertEqual(cache.savedSnapshots.count, writeCountAfterFirstCall, "No write should happen at all for an already-collected day")
    }

    func test_collectDailySeedIfDue_isNoOp_whenActuallyLoggedIn() async {
        let loggedInAuth = await ImpactTestAuth.makeLoggedIn()
        let manager = LoggedOutSeedProgressManager(cache: cache, authenticationService: loggedInAuth)

        manager.collectDailySeedIfDue()

        XCTAssertTrue(cache.savedSnapshots.isEmpty, "Must never write the guest's cache while genuinely logged in")
    }

    func test_collectDailySeedIfDue_doesNotAnimate_onceAlreadyAtCap() {
        // Given the guest is already at the cap (via a debug add, which doesn't touch the daily gate)
        manager.addDebugSeeds(LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)

        // When a due collection can't add anything more
        manager.collectDailySeedIfDue()

        XCTAssertEqual(manager.load().seedCount, LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)
        XCTAssertNil(cache.lastSeedsIncrement, "No animation should fire when the cap absorbs the entire addition")
    }

    // MARK: - addDebugSeeds

    func test_addDebugSeeds_bypassesDailyGate_andCanBeCalledRepeatedly() {
        manager.addDebugSeeds(1)
        manager.addDebugSeeds(1)

        XCTAssertEqual(manager.load().seedCount, 2, "addDebugSeeds must not be limited by the once-per-day gate")
    }

    func test_addDebugSeeds_capsAtMaxSeedsForLoggedOutUsers() {
        manager.addDebugSeeds(LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers + 10)

        XCTAssertEqual(manager.load().seedCount, LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)
    }

    func test_addDebugSeeds_isNoOp_whenActuallyLoggedIn() async {
        let loggedInAuth = await ImpactTestAuth.makeLoggedIn()
        let manager = LoggedOutSeedProgressManager(cache: cache, authenticationService: loggedInAuth)

        _ = manager.addDebugSeeds(1)

        XCTAssertTrue(cache.savedSnapshots.isEmpty)
    }

    // MARK: - reset (logout regression: land on 0, then immediately collect back to 1)

    func test_reset_zeroesSnapshotAndAllowsImmediateCollection() {
        manager.addDebugSeeds(LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers)

        manager.reset()

        XCTAssertEqual(manager.load().seedCount, 0, "reset() must land on exactly 0")

        manager.collectDailySeedIfDue()

        XCTAssertEqual(
            manager.load().seedCount,
            1,
            "Immediately after reset(), a collection must succeed - regression test for logout leaving the guest stuck at 0"
        )
    }

    func test_reset_doesNotAnimate() {
        manager.addDebugSeeds(2)

        manager.reset()

        XCTAssertNil(cache.lastSeedsIncrement, "A reset is not an earned seed and must never animate")
    }
}
// swiftlint:enable implicitly_unwrapped_optional
