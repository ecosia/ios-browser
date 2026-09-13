// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class ImpactCacheTests: XCTestCase {

    private let cache = ImpactCache()

    override func setUp() {
        super.setUp()
        cache.clear()
    }

    override func tearDown() {
        cache.clear()
        super.tearDown()
    }

    func test_load_returnsNil_whenNothingCached() {
        XCTAssertNil(cache.load())
    }

    func test_save_thenLoad_returnsSameSnapshot() {
        let snapshot = ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6)

        cache.save(snapshot)

        XCTAssertEqual(cache.load(), snapshot)
    }

    func test_clear_removesCachedSnapshot() {
        cache.save(ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6))

        cache.clear()

        XCTAssertNil(cache.load())
    }

    func test_clearOnLogout_isEquivalentToClear() {
        cache.save(ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6))

        cache.clearOnLogout()

        XCTAssertNil(cache.load(), "clearOnLogout() should behave exactly like clear()")
    }
}
