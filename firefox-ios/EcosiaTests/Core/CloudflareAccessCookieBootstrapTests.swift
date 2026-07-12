// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class CloudflareAccessCookieBootstrapTests: XCTestCase {

    func testSyncAuthorizationCookieToWebView_noOpForProduction() async {
        let store = MockHTTPCookieStore()
        await CloudflareAccessCookieBootstrap.syncAuthorizationCookieToWebView(
            environment: .production,
            cookieStore: store
        )
        let cookies = await store.allCookies()
        XCTAssertTrue(cookies.isEmpty)
    }

    func testAuthorizationCookies_parsesSetCookieHeader() throws {
        let url = URL(string: "https://api.ecosia-staging.xyz/")!
        let jwt = "eyJ.test.token"
        let response = try makeHTTPResponse(
            url: url,
            statusCode: 200,
            headers: [
                "Set-Cookie": "CF_Authorization=\(jwt); Path=/; Secure; HttpOnly; SameSite=None",
            ]
        )

        let cookies = CloudflareAccessCookieBootstrap.authorizationCookies(from: response, for: url)

        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies[0].name, "CF_Authorization")
        XCTAssertEqual(cookies[0].value, jwt)
        XCTAssertEqual(cookies[0].domain, "api.ecosia-staging.xyz")
    }

    func testAuthorizationCookies_convertsAnyHashableHeaderFields() throws {
        let url = URL(string: "https://api.ecosia-staging.xyz/")!
        let jwt = "eyJ.test.token"
        let headerFields = CloudflareAccessCookieBootstrap.stringHeaderFields(from: [
            "Set-Cookie": "CF_Authorization=\(jwt); Path=/; Secure; HttpOnly; SameSite=None",
            NSString("Ignored"): "non-string-key"
        ])
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            .filter { $0.name == CloudflareAccessCookieBootstrap.authorizationCookieName }

        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies[0].value, jwt)
    }

    private func makeHTTPResponse(
        url: URL,
        statusCode: Int,
        headers: [String: String]
    ) throws -> HTTPURLResponse {
        try XCTUnwrap(
            HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)
        )
    }
}
