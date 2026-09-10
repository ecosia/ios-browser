// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class UserDefaultsLoggedInImpactCacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaultsLoggedInImpactCache.clear()
    }

    override func tearDown() {
        UserDefaultsLoggedInImpactCache.clear()
        super.tearDown()
    }

    func test_load_returnsNil_whenNothingCached() {
        XCTAssertNil(UserDefaultsLoggedInImpactCache.load(forUserId: "user-a"))
    }

    func test_save_thenLoad_returnsSameSnapshot_forSameUser() {
        let snapshot = ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6)

        UserDefaultsLoggedInImpactCache.save(snapshot, userId: "user-a")

        XCTAssertEqual(UserDefaultsLoggedInImpactCache.load(forUserId: "user-a"), snapshot)
    }

    func test_load_returnsNil_forDifferentUser() {
        let snapshot = ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6)
        UserDefaultsLoggedInImpactCache.save(snapshot, userId: "user-a")

        XCTAssertNil(UserDefaultsLoggedInImpactCache.load(forUserId: "user-b"),
                     "A different account must never inherit another account's cached numbers")
    }

    func test_clear_removesCachedSnapshot() {
        UserDefaultsLoggedInImpactCache.save(
            ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6),
            userId: "user-a"
        )

        UserDefaultsLoggedInImpactCache.clear()

        XCTAssertNil(UserDefaultsLoggedInImpactCache.load(forUserId: "user-a"))
    }

    func test_clearOnLogout_isEquivalentToClear() {
        UserDefaultsLoggedInImpactCache.save(
            ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6),
            userId: "user-a"
        )

        UserDefaultsLoggedInImpactCache.clearOnLogout()

        XCTAssertNil(UserDefaultsLoggedInImpactCache.load(forUserId: "user-a"),
                     "clearOnLogout() is the shared vocabulary with SeedProgressManagerProtocol - should behave exactly like clear()")
    }
}
