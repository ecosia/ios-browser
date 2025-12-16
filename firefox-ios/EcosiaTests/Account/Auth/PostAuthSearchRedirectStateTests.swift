// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class PostAuthSearchRedirectStateTests: XCTestCase {

    func testCaptureStoresValidSearchURL() {
        let sut = PostAuthSearchRedirectState()
        sut.capture(searchURLString: "https://www.ecosia.org/search?q=test")

        let result = sut.consumePendingURL()

        XCTAssertEqual(result, URL(string: "https://www.ecosia.org/search?q=test"))
    }

    func testCaptureIgnoresInvalidURL() {
        let sut = PostAuthSearchRedirectState()
        sut.capture(searchURLString: "not a url")

        XCTAssertNil(sut.consumePendingURL())
    }

    func testCaptureDoesNotOverrideExistingURL() {
        let sut = PostAuthSearchRedirectState()
        sut.capture(searchURLString: "https://www.ecosia.org/search?q=first")
        sut.capture(searchURLString: "https://www.ecosia.org/search?q=second")

        let result = sut.consumePendingURL()

        XCTAssertEqual(result, URL(string: "https://www.ecosia.org/search?q=first"))
    }

    func testConsumeClearsStoredURL() {
        let sut = PostAuthSearchRedirectState()
        sut.capture(searchURLString: "https://www.ecosia.org/search?q=foo")

        _ = sut.consumePendingURL()
        XCTAssertNil(sut.consumePendingURL())
    }

    func testPeekPendingURLDoesNotClearValue() {
        let sut = PostAuthSearchRedirectState()
        sut.capture(searchURLString: "https://www.ecosia.org/search?q=peek")

        XCTAssertEqual(sut.peekPendingURL(), URL(string: "https://www.ecosia.org/search?q=peek"))
        XCTAssertEqual(sut.consumePendingURL(), URL(string: "https://www.ecosia.org/search?q=peek"))
        XCTAssertNil(sut.peekPendingURL())
    }

    func testHasPendingURLReflectsState() {
        let sut = PostAuthSearchRedirectState()

        XCTAssertFalse(sut.hasPendingURL)
        sut.capture(searchURLString: "https://www.ecosia.org/search?q=flag")
        XCTAssertTrue(sut.hasPendingURL)

        _ = sut.consumePendingURL()
        XCTAssertFalse(sut.hasPendingURL)
    }
}
