// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class UnleashCookieHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Cookie.setURLProvider(.production)
        MockUnleash.setLoaded(true)
    }

    override func tearDown() {
        super.tearDown()
        Cookie.resetURLProvider()
        MockUnleash.reset()
    }

    func testNoCookieWithoutLoadingUnleash() {
        MockUnleash.setLoaded(false)
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)
        XCTAssertNil(handler.makeCookie())
    }

    func testMakeCookieCreatesValidCookie() {
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create unleash cookie when mock is loaded")
            return
        }

        XCTAssertEqual(cookie.name, "ECUNL")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")

        XCTAssertFalse(cookie.value.isEmpty)
        XCTAssertEqual(cookie.value, cookie.value.lowercased())
    }

    func testMultipleCookiesHaveSameId() {
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)

        let cookie1 = handler.makeCookie()
        let cookie2 = handler.makeCookie()

        XCTAssertNotNil(cookie1)
        XCTAssertNotNil(cookie2)
        XCTAssertEqual(cookie1?.value, cookie2?.value)
    }

    // MARK: - Extract Value Tests

    func testExtractValueDoesNotModifyAnything() {
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)

        handler.extractValue("some-random-value")
        handler.extractValue("")
        handler.extractValue("invalid-uuid")

        // TODO: Check Unleash cookie is reset and overriden again
    }

    // MARK: - Cookie Properties Tests

    func testCookieNameIsCorrect() {
        let handler = UnleashCookieHandler(unleash: MockUnleash.self)
        XCTAssertEqual(handler.cookieName, "ECUNL")
    }
}

// MARK: - Integration Tests

extension UnleashCookieHandlerTests {
    
    func testMakeCookieCreatesValidCookieAfterUnleashStart() async {
        _ = try? await Unleash.start(appVersion: "1.0.0")

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

    func testMultipleCookiesHaveSameIdAcrossSessions() async {
        // Simulate Unleash being loaded
        _ = try? await Unleash.start(appVersion: "1.0.0")

        let handler = UnleashCookieHandler()

        let cookie1 = handler.makeCookie()
        XCTAssertNotNil(cookie1)

        // Force unloaded state and start again
        Unleash.clearInstanceModel()
        _ = try? await Unleash.start(appVersion: "1.0.0")

        let cookie2 = handler.makeCookie()

        XCTAssertNotNil(cookie2)
        XCTAssertEqual(cookie1?.value, cookie2?.value)
    }
}
