// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class URLRequestTests: XCTestCase {

    private let ecosiaURL = URL(string: "https://www.ecosia.org/search")!

    // MARK: - Language-region header

    func testAddLanguageRegionHeader() {
        var request = URLRequest(url: ecosiaURL)
        request.addLanguageRegionHeader()

        let expected = Locale.current.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-ecosia-app-language-region"), expected)
    }

    func testAddLanguageRegionHeaderIsIdempotent() {
        var request = URLRequest(url: ecosiaURL)
        request.addLanguageRegionHeader()
        request.addLanguageRegionHeader()

        let expected = Locale.current.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-ecosia-app-language-region"), expected)
    }

    // MARK: - Cloudflare auth headers

    func testCloudFlareHeadersNotAddedWhenNoAuth() {
        var request = URLRequest(url: ecosiaURL)
        request.withCloudFlareAuthParameters(auth: nil)

        XCTAssertNil(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientId))
        XCTAssertNil(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientSecret))
    }

    func testCloudFlareHeadersAddedWhenAuthProvided() {
        var request = URLRequest(url: ecosiaURL)
        let auth = Environment.CloudFlareAuth(id: "test-client-id", secret: "test-client-secret")
        request.withCloudFlareAuthParameters(auth: auth)

        XCTAssertEqual(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientId), "test-client-id")
        XCTAssertEqual(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientSecret), "test-client-secret")
    }

    func testCloudFlareHeadersNotAddedForProductionEnvironment() {
        var request = URLRequest(url: ecosiaURL)
        request.withCloudFlareAuthParameters(environment: .production)

        XCTAssertNil(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientId))
        XCTAssertNil(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientSecret))
    }
}
