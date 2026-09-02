// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class AuthSessionCookieHandlerTests: XCTestCase {

    func testClearFromSharedStorage_removesEASCCookie() {
        // Given: an EASC cookie (copied there by a previous file upload) alongside an unrelated cookie
        let storage = HTTPCookieStorage.shared
        let easc = makeCookie(name: Cookie.authSession.rawValue, value: "stale-session", domain: ".ecosia.org")
        let unrelated = makeCookie(name: "EAIST", value: "waf-token", domain: ".ecosia.org")
        storage.setCookie(easc)
        storage.setCookie(unrelated)
        defer {
            storage.deleteCookie(easc)
            storage.deleteCookie(unrelated)
        }

        // When
        AuthSessionCookieHandler.clearFromSharedStorage()

        // Then
        let remainingNames = (storage.cookies ?? []).map(\.name)
        XCTAssertFalse(remainingNames.contains(Cookie.authSession.rawValue))
        XCTAssertTrue(remainingNames.contains("EAIST"))
    }

    func testClearFromSharedStorage_withNoEASCCookie_leavesOtherCookiesUntouched() {
        // Given: no EASC cookie present, only an unrelated one
        let storage = HTTPCookieStorage.shared
        let unrelated = makeCookie(name: "EAIST", value: "waf-token", domain: ".ecosia.org")
        storage.setCookie(unrelated)
        defer { storage.deleteCookie(unrelated) }

        // When
        AuthSessionCookieHandler.clearFromSharedStorage()

        // Then
        let remainingNames = (storage.cookies ?? []).map(\.name)
        XCTAssertTrue(remainingNames.contains("EAIST"))
    }

    func testClearFromSharedStorage_withMultipleEASCCookiesAcrossDomains_removesAll() {
        // Given: EASC cookies under two different domains (e.g. staging + prod), both stale
        let storage = HTTPCookieStorage.shared
        let easc1 = makeCookie(name: Cookie.authSession.rawValue, value: "stale-1", domain: ".ecosia.org")
        let easc2 = makeCookie(name: Cookie.authSession.rawValue, value: "stale-2", domain: ".staging.ecosia.org")
        storage.setCookie(easc1)
        storage.setCookie(easc2)
        defer {
            storage.deleteCookie(easc1)
            storage.deleteCookie(easc2)
        }

        // When
        AuthSessionCookieHandler.clearFromSharedStorage()

        // Then
        let remaining = (storage.cookies ?? []).filter { $0.name == Cookie.authSession.rawValue }
        XCTAssertTrue(remaining.isEmpty)
    }

    private func makeCookie(name: String, value: String, domain: String) -> HTTPCookie {
        HTTPCookie(properties: [
            .name: name,
            .value: value,
            .domain: domain,
            .path: "/",
            .expires: Date(timeIntervalSinceNow: 60 * 60),
        ])!
    }
}
