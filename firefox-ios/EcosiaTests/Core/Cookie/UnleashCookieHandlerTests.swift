// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class UnleashCookieHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.setURLProvider(.production)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    func testMakeCookieCreatesValidCookie() {
        let handler = UnleashCookieHandler()
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create unleash cookie")
            return
        }

        XCTAssertEqual(cookie.name, "ECUNL")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")

        XCTAssertFalse(cookie.value.isEmpty)
        XCTAssertEqual(cookie.value, cookie.value.lowercased())
    }

    func testMultipleCookiesHaveSameId() {
        let handler = UnleashCookieHandler()

        let cookie1 = handler.makeCookie()
        let cookie2 = handler.makeCookie()

        XCTAssertNotNil(cookie1)
        XCTAssertNotNil(cookie2)
        XCTAssertEqual(cookie1?.value, cookie2?.value)
    }

    // MARK: - Extract Value Tests

    func testExtractValueDoesNotModifyAnything() {
        let handler = UnleashCookieHandler()

        handler.extractValue("some-random-value")
        handler.extractValue("")
        handler.extractValue("invalid-uuid")

        // TODO: Check Unleash cookie is reset and overriden again
    }

    // MARK: - Cookie Properties Tests

    func testCookieNameIsCorrect() {
        let handler = UnleashCookieHandler()
        XCTAssertEqual(handler.cookieName, "ECUNL")
    }
}
