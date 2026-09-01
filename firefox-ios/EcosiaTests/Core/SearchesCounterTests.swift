// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

@MainActor
final class SearchesCounterTests: XCTestCase, @unchecked Sendable {
    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    func testSubscribeAndReceive() {
        let expect = expectation(description: "")
        let counter = SearchesCounter()

        counter.subscribeAndReceive(self) { items in
            let state = MainActor.assumeIsolated { counter.state }
            XCTAssertEqual(state, User.shared.searchCount)
            MainActor.assumeIsolated { counter.unsubscribe(self) }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSubscribe() {
        let expect = expectation(description: "")
        let counter = SearchesCounter()

        counter.subscribe(self) { items in
            let state = MainActor.assumeIsolated { counter.state }
            XCTAssertEqual(state, 2)
            MainActor.assumeIsolated { counter.unsubscribe(self) }
            expect.fulfill()
        }
        User.shared.searchCount = 2
        waitForExpectations(timeout: 1)
    }
}
