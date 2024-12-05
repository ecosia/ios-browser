import XCTest
@testable import Core

final class ImagesTests: XCTestCase {
    private var session: MockURLSession!
    private var images: Images!

    override func setUp() {
        session = .init()
        images = .init(session)
    }

    func testDownload() {
        let expect = expectation(description: "")
        let url = URL(string: "avocado.com")!
        session.data = [.init("hello".utf8)]
        images.load(self, url: url) {
            XCTAssertEqual(url, $0.url)
            XCTAssertFalse($0.data.isEmpty)
            XCTAssertEqual(.main, Thread.current)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCache() {
        let expect = expectation(description: "")
        let url = URL(string: "avocado.com")!
        session.request = {
            XCTFail()
        }
        images.items.insert(.init(url, .init("hello".utf8)))
        images.load(self, url: url) { _ in
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
