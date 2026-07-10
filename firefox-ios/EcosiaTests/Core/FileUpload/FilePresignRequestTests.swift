// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class FilePresignRequestTests: XCTestCase {

    func testCookieHeaderValue_mergesStoredCookiesWithAuthSession() throws {
        let apiRoot = try XCTUnwrap(URL(string: "https://api.ecosia.org"))
        let storage = HTTPCookieStorage.shared
        let eaist = makeCookie(name: "EAIST", value: "waf-token", domain: ".ecosia.org")
        let easc = makeCookie(name: Cookie.authSession.rawValue, value: "session-token", domain: ".ecosia.org")
        storage.setCookie(eaist)
        storage.setCookie(easc)
        let refreshedCookie = makeCookie(
            name: Cookie.authSession.rawValue,
            value: "refreshed-session",
            domain: ".ecosia.org"
        )
        defer {
            storage.deleteCookie(eaist)
            storage.deleteCookie(easc)
            storage.deleteCookie(refreshedCookie)
        }

        let header = FilePresignRequest.cookieHeaderValue(
            cookieStorage: storage,
            apiRoot: apiRoot,
            authSessionCookie: refreshedCookie
        )

        XCTAssertEqual(
            header,
            "EAIST=waf-token; EASC=refreshed-session"
        )
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
