// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia
// swiftlint:disable implicitly_unwrapped_optional

@MainActor
final class NativeToWebSSOAuth0ProviderTests: XCTestCase {

    var provider: NativeToWebSSOAuth0Provider!
    var mockSettings: MockAuth0SettingsProvider!
    var mockCredentialsManager: MockCredentialsManager!

    override func setUp() {
        super.setUp()
        mockSettings = MockAuth0SettingsProvider()
        mockCredentialsManager = MockCredentialsManager()
        provider = NativeToWebSSOAuth0Provider(
            settings: mockSettings,
            credentialsManager: mockCredentialsManager
        )
    }

    // MARK: - Initialization Tests

    func testInit_withDefaultParameters_createsProvider() {
        // Arrange & Act
        let provider = NativeToWebSSOAuth0Provider()

        // Assert
        XCTAssertNotNil(provider.settings)
        XCTAssertNotNil(provider.credentialsManager)
        XCTAssertTrue(provider.settings is DefaultAuth0SettingsProvider)
        XCTAssertTrue(provider.credentialsManager is DefaultCredentialsManager)
    }

    func testInit_withSettingsButNoCredentialsManager_usesSharedCredentialsManager() {
        // Arrange
        let customSettings = MockAuth0SettingsProvider()

        // Act
        let provider = NativeToWebSSOAuth0Provider(settings: customSettings)

        // Assert
        // Ecosia: Must share the app-wide manager so SSO exchanges and renewals are serialized
        // on the same queue and see the same (rotated) refresh token.
        XCTAssertTrue(provider.credentialsManager is DefaultCredentialsManager)
    }

    // MARK: - SSO Credentials Tests

    func testGetSSOCredentials_returnsSSOCredentialsFromCredentialsManager() async throws {
        // Arrange
        let expectedSSOCredentials = SSOCredentials(
            sessionTransferToken: "test-session-transfer-token",
            issuedTokenType: "urn:auth0:params:oauth:token-type:session_transfer_token",
            expiresIn: Date().addingTimeInterval(60),
            idToken: "test-id-token",
            refreshToken: "test-rotated-refresh-token"
        )
        mockCredentialsManager.mockSSOCredentials = expectedSSOCredentials

        // Act
        let ssoCredentials = try await provider.getSSOCredentials()

        // Assert
        XCTAssertEqual(mockCredentialsManager.ssoCredentialsCallCount, 1)
        XCTAssertEqual(ssoCredentials.sessionTransferToken, expectedSSOCredentials.sessionTransferToken)
        XCTAssertEqual(ssoCredentials.expiresIn, expectedSSOCredentials.expiresIn)
        XCTAssertEqual(ssoCredentials.refreshToken, expectedSSOCredentials.refreshToken)
    }

    func testGetSSOCredentials_withMissingRefreshToken_propagatesCredentialsManagerError() async {
        // Arrange
        mockCredentialsManager.shouldFailSSOCredentials = true
        mockCredentialsManager.mockError = CredentialsManagerError.noRefreshToken

        // Act & Assert
        do {
            _ = try await provider.getSSOCredentials()
            XCTFail("Expected error to be thrown for missing refresh token")
        } catch {
            XCTAssertEqual(error as? CredentialsManagerError, .noRefreshToken)
        }
    }

    func testGetSSOCredentials_withSSOExchangeFailure_propagatesError() async {
        // Arrange
        mockCredentialsManager.shouldFailSSOCredentials = true
        mockCredentialsManager.mockError = NSError(
            domain: "TestError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Failed to exchange refresh token"]
        )

        // Act & Assert
        do {
            _ = try await provider.getSSOCredentials()
            XCTFail("Expected error to be thrown for SSO exchange failure")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 500)
        }
        XCTAssertEqual(mockCredentialsManager.ssoCredentialsCallCount, 1)
    }

    // MARK: - Protocol Conformance Tests

    func testProvider_conformsToAuth0ProviderProtocol() {
        // Arrange & Act
        let provider: Auth0ProviderProtocol = NativeToWebSSOAuth0Provider()

        // Assert
        XCTAssertNotNil(provider)
        XCTAssertNotNil(provider.settings)
        XCTAssertNotNil(provider.credentialsManager)
    }

    func testProvider_usesCorrectSettings() {
        // Arrange
        let customSettings = MockAuth0SettingsProvider()
        customSettings.id = "custom-client-id"
        customSettings.domain = "custom.auth0.com"
        customSettings.cookieDomain = "custom.ecosia.org"

        // Act
        let provider = NativeToWebSSOAuth0Provider(settings: customSettings)

        // Assert
        XCTAssertEqual(provider.settings.id, "custom-client-id")
        XCTAssertEqual(provider.settings.domain, "custom.auth0.com")
        XCTAssertEqual(provider.settings.cookieDomain, "custom.ecosia.org")
    }
}
// swiftlint:enable implicitly_unwrapped_optional
