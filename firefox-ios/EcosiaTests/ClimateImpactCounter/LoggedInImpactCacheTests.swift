// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class LoggedInImpactCacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        LoggedInImpactCache.clear()
    }

    override func tearDown() {
        LoggedInImpactCache.clear()
        super.tearDown()
    }

    func test_load_returnsNil_whenNothingCached() {
        XCTAssertNil(LoggedInImpactCache.load())
    }

    func test_save_thenLoad_returnsSameSnapshot() {
        let snapshot = ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6)

        LoggedInImpactCache.save(snapshot)

        XCTAssertEqual(LoggedInImpactCache.load(), snapshot)
    }

    func test_clear_removesCachedSnapshot() {
        LoggedInImpactCache.save(ImpactSnapshot(seedCount: 42, currentLevelNumber: 3, currentProgress: 0.6))

        LoggedInImpactCache.clear()

        XCTAssertNil(LoggedInImpactCache.load())
    }
}
