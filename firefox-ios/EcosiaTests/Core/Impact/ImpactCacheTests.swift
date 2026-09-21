// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

@MainActor
final class ImpactCacheTests: XCTestCase {

    private let cache = ImpactCache()

    override func setUp() {
        super.setUp()
        cache.resetForTesting()
    }

    override func tearDown() {
        cache.resetForTesting()
        super.tearDown()
    }

    // MARK: - load

    func test_load_returnsNil_whenNothingCached() {
        XCTAssertNil(cache.load())
    }

    func test_save_thenLoad_returnsSameSnapshot() {
        let snapshot = ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6, loggedInUserID: "auth0|user-a")

        self.cache.save(snapshot, seedsIncrement: 1, didLevelUp: false)

        XCTAssertEqual(cache.load(), snapshot)
    }

    func test_save_withNilLoggedInUserID_isReadBackAsGuestSnapshot() {
        let snapshot = ImpactSnapshot(seedCount: 2, currentLevelNumber: 1, currentProgress: 0.4, loggedInUserID: nil)

        self.cache.save(snapshot, seedsIncrement: nil, didLevelUp: false)

        XCTAssertNil(cache.load()?.loggedInUserID)
    }

    func test_save_overwritesLoggedInUserID_whenIdentityChanges() {
        cache.save(
            ImpactSnapshot(seedCount: 10, currentLevelNumber: 1, currentProgress: 0, loggedInUserID: "auth0|user-a"),
            seedsIncrement: nil,
            didLevelUp: false
        )

        cache.save(
            ImpactSnapshot(seedCount: 99, currentLevelNumber: 4, currentProgress: 0.5, loggedInUserID: "auth0|user-b"),
            seedsIncrement: nil,
            didLevelUp: false
        )

        XCTAssertEqual(cache.load()?.loggedInUserID, "auth0|user-b")
        XCTAssertEqual(cache.load()?.seedCount, 99)
    }

    func test_save_removesLoggedInUserID_whenWritingGuestSnapshotOverLoggedInOne() {
        cache.save(
            ImpactSnapshot(seedCount: 10, currentLevelNumber: 3, currentProgress: 0.5, loggedInUserID: "auth0|user-a"),
            seedsIncrement: nil,
            didLevelUp: false
        )

        cache.save(.loggedOutZero, seedsIncrement: nil, didLevelUp: false)

        XCTAssertNil(cache.load()?.loggedInUserID)
        XCTAssertEqual(cache.load()?.seedCount, 0)
    }

    // MARK: - save posts .EcosiaImpactCacheUpdated

    func test_save_postsNotification_withSnapshot() async {
        let snapshot = ImpactSnapshot(seedCount: 5, currentLevelNumber: 1, currentProgress: 0.1, loggedInUserID: nil)

        let userInfo = await waitForImpactCacheUpdate {
            self.cache.save(snapshot, seedsIncrement: nil, didLevelUp: false)
        }

        XCTAssertEqual(userInfo?[ImpactCache.snapshotUserInfoKey] as? ImpactSnapshot, snapshot)
    }

    func test_save_notification_carriesSeedsIncrement_whenProvided() async {
        let userInfo = await waitForImpactCacheUpdate {
            self.cache.save(ImpactSnapshot(seedCount: 3, currentLevelNumber: 1, currentProgress: 0.1), seedsIncrement: 3, didLevelUp: false)
        }

        XCTAssertEqual(userInfo?[ImpactCache.seedsIncrementUserInfoKey] as? Int, 3)
    }

    func test_save_notification_omitsSeedsIncrementKey_whenNil() async {
        let userInfo = await waitForImpactCacheUpdate {
            self.cache.save(ImpactSnapshot(seedCount: 3, currentLevelNumber: 1, currentProgress: 0.1), seedsIncrement: nil, didLevelUp: false)
        }

        XCTAssertNil(userInfo?[ImpactCache.seedsIncrementUserInfoKey])
    }

    func test_save_notification_carriesDidLevelUp() async {
        let userInfo = await waitForImpactCacheUpdate {
            self.cache.save(ImpactSnapshot(seedCount: 3, currentLevelNumber: 2, currentProgress: 0.1), seedsIncrement: nil, didLevelUp: true)
        }

        XCTAssertEqual(userInfo?[ImpactCache.didLevelUpUserInfoKey] as? Bool, true)
    }
}
