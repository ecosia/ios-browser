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
            // `User.shared` is a shared, `nonisolated(unsafe)` singleton and this test class
            // runs alongside other tests, so unrelated concurrent mutations can fire this
            // notification with a value other than the one this test set. Only settle on the
            // value we're actually waiting for instead of asserting on the first callback.
            guard items == 2 else { return }
            MainActor.assumeIsolated { counter.unsubscribe(self) }
            expect.fulfill()
        }
        User.shared.searchCount = 2
        // It could already be 2 from another test, so we have to post directly just in case 
        NotificationCenter.default.post(name: .searchesCounterChanged, object: nil)
        waitForExpectations(timeout: 1)
    }
}
