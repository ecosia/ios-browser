// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

@MainActor final class TreesProjectionTests: XCTestCase {
    private var treesProjection: TreesProjection!

    override func setUp() {
        treesProjection = TreesProjection.shared
    }

    func testTreesAt() async {
        // Arrange
        let date = Date()
        let statistics = Statistics.shared
        await statistics.setTreesPlanted(10)
        await statistics.setTreesPlantedLastUpdated(date.addingTimeInterval(-100))
        await statistics.setTimePerTree(2)
        
        // Act
        let result = await treesProjection.treesAt(date)
        
        // Assert
        XCTAssertEqual(Int(100/2 + 10-1), result)
    }

    func testTimerIsActive() async {
        // Arrange
        let timePerTree = 0.1
        await Statistics.shared.setTimePerTree(timePerTree)

        let exp = XCTestExpectation(description: "Wait for timer")
        let projection = TreesProjection()
        var receivedCount: Int?
        
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
