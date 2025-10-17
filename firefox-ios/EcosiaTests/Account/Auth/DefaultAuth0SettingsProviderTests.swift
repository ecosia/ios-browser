// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class DefaultAuth0SettingsProviderTests: XCTestCase {

    var settingsProvider = DefaultAuth0SettingsProvider()

    // MARK: - Client ID Tests

    func testClientId_withValidEnvironmentVariable_returnsCorrectValue() {
        // Arrange
        // Build Settings variables should be set up in the test scheme
        // For this test, we'll assume AUTH0_CLIENT_ID is available

        // Act
        let clientId = settingsProvider.id

        // Assert
        XCTAssertFalse(clientId.isEmpty, "Client ID should not be empty")
    }

    // MARK: - Domain Tests

    func testDomain_returnsValueFromURLProvider() {
        // Arrange
        let expectedDomain = EcosiaEnvironment.current.urlProvider.auth0Domain

        // Act
        let domain = settingsProvider.domain

        // Assert
        XCTAssertEqual(domain, expectedDomain, "Domain should match the URLProvider auth0Domain")
        XCTAssertFalse(domain.isEmpty, "Domain should not be empty")
    }

    // MARK: - Cookie Domain Tests

    func testCookieDomain_returnsValueFromURLProvider() {
        // Arrange
        let expectedCookieDomain = EcosiaEnvironment.current.urlProvider.auth0CookieDomain

        // Act
        let cookieDomain = settingsProvider.cookieDomain

        // Assert
        XCTAssertEqual(cookieDomain, expectedCookieDomain, "Cookie domain should match the URLProvider auth0CookieDomain")
        XCTAssertFalse(cookieDomain.isEmpty, "Cookie domain should not be empty")
    }

    // MARK: - Protocol Conformance Tests
}
