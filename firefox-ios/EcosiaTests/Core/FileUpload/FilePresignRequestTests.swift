// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class FilePresignRequestTests: XCTestCase {

    func testCookieHeaderValue_mergesStoredCookiesWithAuthSession() {
        let apiRoot = URL(string: "https://www.ecosia.org")!
        let storage = HTTPCookieStorage()
        let eaist = makeCookie(name: "EAIST", value: "waf-token", domain: "www.ecosia.org")
        let easc = makeCookie(name: Cookie.authSession.rawValue, value: "session-token", domain: "www.ecosia.org")
        storage.setCookie(eaist)
        storage.setCookie(easc)

        let header = FilePresignRequest.cookieHeaderValue(
            cookieStorage: storage,
            apiRoot: apiRoot,
            authSessionCookie: makeCookie(
                name: Cookie.authSession.rawValue,
                value: "refreshed-session",
                domain: "www.ecosia.org"
            )
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
        ])!
    }
}
