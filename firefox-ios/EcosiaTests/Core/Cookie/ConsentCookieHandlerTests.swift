// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class ConsentCookieHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Cookie.setURLProvider(.production)

        User.shared.cookieConsentValue = nil
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    func testMakeCookieWithConsentValue() {
        User.shared.cookieConsentValue = "eampg"

        let handler = ConsentCookieHandler()
        guard let cookie = handler.makeCookie() else {
            XCTFail("Failed to create consent cookie")
            return
        }

        XCTAssertEqual(cookie.name, "ECCC")
        XCTAssertEqual(cookie.value, "eampg")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")
    }

    func testMakeCookieWithoutConsentValue() {
        User.shared.cookieConsentValue = nil

        let handler = ConsentCookieHandler()
        let cookie = handler.makeCookie()

        XCTAssertNil(cookie, "Cookie should not be created when consent value is nil")
    }

    func testMakeCookieWithEmptyConsentValue() {
        User.shared.cookieConsentValue = ""

        let handler = ConsentCookieHandler()
        let cookie = handler.makeCookie()

        XCTAssertEqual(cookie?.value, "")
    }

    func testExtractValueWithVariousConsentStrings() {
        let handler = ConsentCookieHandler()
        let testValues = [
            "e",
            "eampg",
            "ea",
            "eamp",
            "custom123"
        ]

        for value in testValues {
            handler.extractValue(value)
            XCTAssertEqual(User.shared.cookieConsentValue, value)
        }
    }

    func testCookieNameIsCorrect() {
        let handler = ConsentCookieHandler()
        XCTAssertEqual(handler.cookieName, "ECCC")
    }

    // MARK: - Integration Tests

    func testConsentCookieViaMainAPI() {
        User.shared.cookieConsentValue = "eampg"

        guard let cookie = Cookie.consent.makeCookie() else {
            XCTFail("Failed to create consent cookie via main API")
            return
        }

        XCTAssertEqual(cookie.name, "ECCC")
        XCTAssertEqual(cookie.value, "eampg")
    }

    func testConsentCookieInRequiredCookies() {
        User.shared.cookieConsentValue = "eampg"

        let cookies = Cookie.makeRequiredCookies(isPrivate: false)
        let consentCookies = cookies.filter { $0.name == "ECCC" }

        XCTAssertEqual(consentCookies.count, 1)
        XCTAssertEqual(consentCookies.first?.value, "eampg")
    }

    func testConsentCookieNotInRequiredCookiesWhenNil() {
        User.shared.cookieConsentValue = nil

        let cookies = Cookie.makeRequiredCookies(isPrivate: false)
        let consentCookies = cookies.filter { $0.name == "ECCC" }

        XCTAssertEqual(consentCookies.count, 0)
    }

    // MARK: - Analytics Consent Detection Tests

    func testAnalyticsConsentDetection() {
        let handler = ConsentCookieHandler()

        // Test values that should indicate analytics consent
        handler.extractValue("eampg")
        XCTAssertTrue(User.shared.hasAnalyticsCookieConsent)

        handler.extractValue("eamp")
        XCTAssertTrue(User.shared.hasAnalyticsCookieConsent)

        handler.extractValue("ea")
        XCTAssertTrue(User.shared.hasAnalyticsCookieConsent)

        // Test values that should NOT indicate analytics consent
        handler.extractValue("e")
        XCTAssertFalse(User.shared.hasAnalyticsCookieConsent)

        handler.extractValue("empg")
        XCTAssertFalse(User.shared.hasAnalyticsCookieConsent)

        handler.extractValue("")
        XCTAssertFalse(User.shared.hasAnalyticsCookieConsent)
    }
}
