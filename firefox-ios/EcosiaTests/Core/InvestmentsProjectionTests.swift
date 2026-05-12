// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

@MainActor final class InvestmentsProjectionTests: XCTestCase {
    private var investmentsProjection: InvestmentsProjection!

    override func setUp() {
        investmentsProjection = InvestmentsProjection.shared
    }

    func testTotalInvestedAt() async {
        // Arrange
        let date = Date()
        let statistics = Statistics.shared
        statistics.totalInvestments = 123456789
        statistics.totalInvestmentsLastUpdated = date.addingTimeInterval(-100)
        statistics.investmentPerSecond = 0.5

        // Act
        let result = await investmentsProjection.totalInvestedAt(date)

        // Assert
        XCTAssertEqual(Int(100*0.5 + 123456789), result)
    }

    func testTimerIsActive() async {
        // Arrange
        let investmentPerSecond = 1.0
        Statistics.shared.investmentPerSecond = investmentPerSecond

        let exp = XCTestExpectation(description: "Wait for timer")
        let projection = InvestmentsProjection()
        nonisolated(unsafe) var receivedAmount: Int?

        // Act
        projection.subscribe(self) { amount in
            receivedAmount = amount
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 2)

        // Assert
        XCTAssertNotNil(receivedAmount)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
