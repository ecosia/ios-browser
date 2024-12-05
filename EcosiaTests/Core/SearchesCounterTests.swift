@testable import Core
import XCTest

final class SearchesCounterTests: XCTestCase {
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
            XCTAssertEqual(counter.state, User.shared.searchCount)
            counter.unsubscribe(self)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testSubscribe() {
        let expect = expectation(description: "")
        let counter = SearchesCounter()

        counter.subscribe(self) { items in
            XCTAssertEqual(counter.state, 2)
            counter.unsubscribe(self)
            expect.fulfill()
        }
        User.shared.searchCount = 2
        waitForExpectations(timeout: 1)
    }
}
