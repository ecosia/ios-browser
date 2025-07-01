// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class Auth0SettingsProviderTests: XCTestCase {

    var settingsProvider: DefaultAuth0SettingsProvider!

    override func setUp() {
        super.setUp()
        settingsProvider = DefaultAuth0SettingsProvider()
    }

    override func tearDown() {
        settingsProvider = nil
        super.tearDown()
    }

    // MARK: - Client ID Tests

    func testClientId_withValidEnvironmentVariable_returnsCorrectValue() {
        // Arrange
        // Environment variables should be set up in the test scheme
        // For this test, we'll assume AUTH0_CLIENT_ID is available

        // Act
        let clientId = settingsProvider.id

        // Assert
        XCTAssertFalse(clientId.isEmpty, "Client ID should not be empty")
        XCTAssertTrue(clientId.count > 10, "Client ID should be a meaningful length")
    }

    // MARK: - Domain Tests

    func testDomain_withValidEnvironmentVariable_returnsCorrectValue() {
        // Arrange
        // Environment variables should be set up in the test scheme

        // Act
        let domain = settingsProvider.domain

        // Assert
        XCTAssertFalse(domain.isEmpty, "Domain should not be empty")
        XCTAssertTrue(domain.contains("."), "Domain should contain a dot")
        XCTAssertTrue(domain.contains("auth0.com"), "Domain should contain auth0.com")
    }

    // MARK: - Cookie Domain Tests

    func testCookieDomain_withValidEnvironmentVariable_returnsCorrectValue() {
        // Arrange
        // Environment variables should be set up in the test scheme

        // Act
        let cookieDomain = settingsProvider.cookieDomain

        // Assert
        XCTAssertFalse(cookieDomain.isEmpty, "Cookie domain should not be empty")
        XCTAssertTrue(cookieDomain.contains("."), "Cookie domain should contain a dot")
    }

    // MARK: - Protocol Conformance Tests

    func testAuth0SettingsProviderProtocol_conformance_implementsAllRequiredProperties() {
        // Arrange
        let provider: Auth0SettingsProviderProtocol = DefaultAuth0SettingsProvider()

        // Act & Assert
        XCTAssertNotNil(provider.id)
        XCTAssertNotNil(provider.domain)
        XCTAssertNotNil(provider.cookieDomain)
    }

    // MARK: - Mock Settings Provider Tests

    func testMockAuth0SettingsProvider_providesTestValues() {
        // Arrange
        let mockProvider = MockAuth0SettingsProvider()

        // Act & Assert
        XCTAssertEqual(mockProvider.domain, "test.auth0.com")
        XCTAssertEqual(mockProvider.id, "mock-client-id")
        XCTAssertEqual(mockProvider.cookieDomain, "test.ecosia.org")
    }
}
