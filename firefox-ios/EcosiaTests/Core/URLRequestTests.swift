// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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

    // MARK: - Ecosia app header

    func testAddEcosiaAppHeader() {
        // Given
        var request = URLRequest(url: ecosiaURL)

        // When
        request.addEcosiaAppHeader()

        // Then
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Ecosia-App"), "ios/\(AppInfo.ecosiaAppVersion)")
    }

    func testAddEcosiaAppHeaderUsesPlatformSlashMarketingVersion() throws {
        // Given
        var request = URLRequest(url: ecosiaURL)

        // When
        request.addEcosiaAppHeader()

        // Then
        let value = try XCTUnwrap(request.value(forHTTPHeaderField: "X-Ecosia-App"))
        let components = value.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        XCTAssertEqual(components.count, 2)
        XCTAssertEqual(components.first, "ios")
        XCTAssertFalse(try XCTUnwrap(components.last).isEmpty)
    }

    func testAddEcosiaAppHeaderIsIdempotent() {
        // Given
        var request = URLRequest(url: ecosiaURL)

        // When
        request.addEcosiaAppHeader()
        request.addEcosiaAppHeader()

        // Then
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Ecosia-App"), "ios/\(AppInfo.ecosiaAppVersion)")
    }

    func testEcosiaAppHeaderFieldName() {
        XCTAssertEqual(URLRequest.ecosiaAppHeaderField, "X-Ecosia-App")
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
