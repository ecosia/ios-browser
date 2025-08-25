// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
import WebKit

final class CookieTests: XCTestCase {

    var urlProvider: URLProvider = .production

    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.setURLProvider(urlProvider)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    // MARK: - Base Cookie logic

    func testCookieInitFromHTTPCookie() {
        let validCookie = HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "test"])!
        let invalidDomainCookie = HTTPCookie(properties: [.name: "ECFG", .domain: ".google.com", .path: "/", .value: "test"])!
        let invalidNameCookie = HTTPCookie(properties: [.name: "INVALID", .domain: ".ecosia.org", .path: "/", .value: "test"])!

        XCTAssertNotNil(Cookie(validCookie))
        XCTAssertEqual(Cookie(validCookie), .main)

        XCTAssertNil(Cookie(invalidDomainCookie))
        XCTAssertNil(Cookie(invalidNameCookie))
    }

    func testCookieInitFromString() {
        XCTAssertEqual(Cookie("ECFG"), .main)
        XCTAssertEqual(Cookie("ECCC"), .consent)
        XCTAssertEqual(Cookie("ECUNL"), .unleash)
        XCTAssertNil(Cookie("INVALID"))
    }

    func testMakeRequiredCookies() async {
        _ = try? await Unleash.start(appVersion: "1.0.0") // Pre-requirement for ECUNL
        User.shared.cookieConsentValue = "eampg"

        let standardCookies = Cookie.makeRequiredCookies(isPrivate: false)
        let privateCookies = Cookie.makeRequiredCookies(isPrivate: true)

        XCTAssertTrue(standardCookies.contains { $0.name == Cookie.main.name })
        XCTAssertTrue(privateCookies.contains { $0.name == Cookie.main.name })

        XCTAssertTrue(standardCookies.contains { $0.name == Cookie.consent.name })
        XCTAssertTrue(privateCookies.contains { $0.name == Cookie.consent.name })

        XCTAssertTrue(standardCookies.contains { $0.name == Cookie.unleash.name })
        XCTAssertTrue(privateCookies.contains { $0.name == Cookie.unleash.name })
    }

    // MARK: - Integration Tests with handlers

    func testReceivedCookiesIntegration() {
        // Test that received cookies are properly routed to the correct handlers
        User.shared.searchCount = 0
        User.shared.cookieConsentValue = nil

        let cookies = [
            HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.org", .path: "/", .value: "t=100:cid=test-user"])!,
            HTTPCookie(properties: [.name: "ECCC", .domain: ".ecosia.org", .path: "/", .value: "eampg"])!,
            HTTPCookie(properties: [.name: "ECUNL", .domain: ".ecosia.org", .path: "/", .value: "test-unleash-id"])!
        ]

        Cookie.received(cookies, in: MockHTTPCookieStore())

        XCTAssertEqual(User.shared.searchCount, 100)
        XCTAssertEqual(User.shared.id, "test-user")

        XCTAssertEqual(User.shared.cookieConsentValue, "eampg")

        // TODO: Check Unleash cookie is reset and overriden again
    }

    func testReceivedInvalidDomainCookies() {
        User.shared.searchCount = 3

        Cookie.received([HTTPCookie(properties: [.name: "ECFG", .domain: ".ecosia.it", .path: "/", .value: "t=9999"])!], in: MockHTTPCookieStore())

        XCTAssertEqual(User.shared.searchCount, 3)
    }

    func testReceivedInvalidNameCookies() {
        User.shared.searchCount = 3

        Cookie.received([HTTPCookie(properties: [.name: "Unknown", .domain: ".ecosia.org", .path: "/", .value: "t=9999"])!], in: MockHTTPCookieStore())

        XCTAssertEqual(User.shared.searchCount, 3)
    }

    // MARK: - Cookie Type API Tests

    func testCookieTypeBasicCreation() async {
        _ = try? await Unleash.start(appVersion: "1.0.0") // Pre-requirement for ECUNL
        User.shared.cookieConsentValue = "notnull"
        let mainCookie = Cookie.main.makeCookie()
        let consentCookie = Cookie.consent.makeCookie()
        let unleashCookie = Cookie.unleash.makeCookie()

        XCTAssertNotNil(mainCookie)
        XCTAssertEqual(mainCookie?.name, "ECFG")

        XCTAssertNotNil(consentCookie)
        XCTAssertEqual(consentCookie?.name, "ECCC")

        XCTAssertNotNil(unleashCookie)
        XCTAssertEqual(unleashCookie?.name, "ECUNL")
    }

    func testMakeMainModes() {
        User.shared.id = "test-user"
        User.shared.searchCount = 42

        guard let standardCookie = Cookie.makeMain(mode: .standard),
              let incognitoCookie = Cookie.makeMain(mode: .incognito) else {
            XCTFail("Failed to create main cookies")
            return
        }

        XCTAssertEqual(standardCookie.name, "ECFG")
        XCTAssertEqual(incognitoCookie.name, "ECFG")

        let standardValues = parseMainCookieValue(standardCookie.value)
        let incognitoValues = parseMainCookieValue(incognitoCookie.value)

        XCTAssertNotNil(standardValues["cid"])
        XCTAssertNotNil(standardValues["t"])
        XCTAssertNil(incognitoValues["cid"])
        XCTAssertNil(incognitoValues["t"])
    }

    // MARK: - URLProvider Integration Tests

    func testURLProviderStaging() {
        let customProvider = URLProvider.staging
        Cookie.setURLProvider(customProvider)
        let someCookie = Cookie.consent.makeCookie()
        XCTAssertEqual(someCookie?.domain, ".ecosia-staging.xyz")
    }
}

// MARK: - Helper Methods
extension CookieTests {

    /// Helper method to parse main cookie value into dictionary
    private func parseMainCookieValue(_ value: String) -> [String: String] {
        return value.components(separatedBy: ":").map { $0.components(separatedBy: "=") }.reduce(into: [String: String]()) {
            guard $1.count == 2 else { return }
            $0[$1[0]] = $1[1]
        }
    }
}
