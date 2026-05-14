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

    func testInit_withSettingsButNoCredentialsManager_createsCredentialsManagerWithSettings() {
        // Arrange
        let customSettings = MockAuth0SettingsProvider()

        // Act
        let provider = NativeToWebSSOAuth0Provider(settings: customSettings)

        // Assert
        XCTAssertNotNil(provider.credentialsManager)
    }

    // MARK: - SSO Credentials Tests

    func testGetSSOCredentials_withValidRefreshToken_returnsSSOCredentials() async throws {
        // Ecosia: This test calls Auth0.authentication().ssoExchange().start() which makes a real
        // network request with no timeout, causing it to hang indefinitely in unit test environments.
        // Proper fix requires injecting a mock URLSession / Auth0 authentication dependency.
        // Tracked in MOB-4384.
        throw XCTSkip("Hangs: real Auth0 network call with no timeout — tracked in MOB-4384")
    }

    func testGetSSOCredentials_withMissingRefreshToken_throwsError() async {
        // Arrange
        let credentialsWithoutRefreshToken = Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: nil, // Missing refresh token
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
        mockCredentialsManager.storedCredentials = credentialsWithoutRefreshToken

        // Act & Assert
        do {
            _ = try await provider.getSSOCredentials()
            XCTFail("Expected error to be thrown for missing refresh token")
        } catch let error as NativeToWebSSOAuth0Provider.NativeToWebSSOError {
            if case .missingRefreshToken(let message) = error {
                XCTAssertEqual(message, "Refresh token is missing. Please check your credentials.")
            } else {
                XCTFail("Expected missingRefreshToken error, got: \(error)")
            }
        } catch {
            XCTFail("Expected NativeToWebSSOError, got: \(error)")
        }
    }

    func testGetSSOCredentials_withCredentialsRetrievalFailure_throwsError() async {
        // Arrange
        mockCredentialsManager.shouldFailCredentials = true
        mockCredentialsManager.mockError = NSError(
            domain: "TestError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve credentials"]
        )

        // Act & Assert
        do {
            _ = try await provider.getSSOCredentials()
            XCTFail("Expected error to be thrown for credentials retrieval failure")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 500)
        }
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

    // MARK: - Error Handling Tests

    func testNativeToWebSSOError_equatableConformance() {
        // Arrange
        let error1 = NativeToWebSSOAuth0Provider.NativeToWebSSOError.invalidResponse
        let error2 = NativeToWebSSOAuth0Provider.NativeToWebSSOError.invalidResponse
        let error3 = NativeToWebSSOAuth0Provider.NativeToWebSSOError.missingRefreshToken("test")
        let error4 = NativeToWebSSOAuth0Provider.NativeToWebSSOError.missingRefreshToken("test")
        let error5 = NativeToWebSSOAuth0Provider.NativeToWebSSOError.missingRefreshToken("different")

        // Act & Assert
        XCTAssertEqual(error1, error2)
        XCTAssertEqual(error3, error4)
        XCTAssertNotEqual(error3, error5)
        XCTAssertNotEqual(error1, error3)
    }

    // MARK: - Helper Methods

    private func createTestCredentials() -> Credentials {
        return Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email offline_access"
        )
    }
}
// swiftlint:enable implicitly_unwrapped_optional
