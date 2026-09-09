// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

@MainActor final class TreesProjectionTests: XCTestCase {
    private var treesProjection: TreesProjection!

    override func setUp() {
        treesProjection = TreesProjection.shared
    }

    func testTreesAt() async {
        // Arrange
        let date = Date()
        let statistics = Statistics.shared
        statistics.treesPlanted = 10
        statistics.treesPlantedLastUpdated = date.addingTimeInterval(-100)
        statistics.timePerTree = 2

        // Act
        let result = await treesProjection.treesAt(date)

        // Assert
        XCTAssertEqual(Int(100/2 + 10-1), result)
    }

    func testTimerIsActive() async {
        // Arrange
        let timePerTree = 0.1
        Statistics.shared.timePerTree = timePerTree

        let exp = XCTestExpectation(description: "Wait for timer")
        let projection = TreesProjection()
        nonisolated(unsafe) var receivedCount: Int?

        // Act
        projection.subscribe(self) { count in
            receivedCount = count
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1)

        // Assert
        XCTAssertNotNil(receivedCount)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
