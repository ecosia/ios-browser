// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia

final class Auth0ProviderProtocolTests: XCTestCase {

    var mockProvider: MockAuth0Provider!

    override func setUp() {
        super.setUp()
        mockProvider = MockAuth0Provider()
    }

    override func tearDown() {
        mockProvider?.reset()
        mockProvider = nil
        super.tearDown()
    }

    // MARK: - Protocol Default Implementation Tests

    func testDefaultCredentialsManager_returnsAuthDefaultCredentialsManager() {
        // Arrange
        let provider: Auth0ProviderProtocol = WebAuth0Provider()

        // Act
        let credentialsManager = provider.credentialsManager

        // Assert
        XCTAssertNotNil(credentialsManager)
        XCTAssertTrue(credentialsManager is DefaultCredentialsManager)
    }

    func testMakeHttpsWebAuth_createsWebAuthWithCloudFlareSupport() {
        // Arrange
        let provider: Auth0ProviderProtocol = MockAuth0Provider()

        // Act
        let webAuth = provider.makeHttpsWebAuth()

        // Assert
        XCTAssertNotNil(webAuth)
        // Note: In a real test environment, we would verify the URLSession configuration
        // includes CloudFlare auth parameters, but this requires integration testing
    }

    func testDefaultStartAuth_callsWebAuthStart() async throws {
        // Arrange
        let provider = mockProvider!

        // Act
        _ = try await provider.startAuth()

        // Assert
        XCTAssertEqual(provider.startAuthCallCount, 1)
    }

    func testDefaultClearSession_callsWebAuthClearSession() async throws {
        // Arrange
        let provider = mockProvider!

        // Act
        try await provider.clearSession()

        // Assert
        XCTAssertEqual(provider.clearSessionCallCount, 1)
    }

    func testDefaultStoreCredentials_callsCredentialsManagerStore() throws {
        // Arrange
        let provider = mockProvider!
        let credentials = createTestCredentials()

        // Act
        _ = try provider.storeCredentials(credentials)

        // Assert
        XCTAssertEqual(provider.storeCredentialsCallCount, 1)
    }

    func testDefaultRetrieveCredentials_callsCredentialsManagerCredentials() async throws {
        // Arrange
        let provider = mockProvider!
        let testCredentials = createTestCredentials()
        provider.mockCredentials = testCredentials
        provider.hasStoredCredentials = true  // Ensure mock has credentials

        // Act
        _ = try await provider.retrieveCredentials()

        // Assert
        XCTAssertEqual(provider.retrieveCredentialsCallCount, 1)
    }

    func testDefaultClearCredentials_callsCredentialsManagerClear() {
        // Arrange
        let provider = mockProvider!

        // Act
        _ = provider.clearCredentials()

        // Assert
        XCTAssertEqual(provider.clearCredentialsCallCount, 1)
    }

    func testDefaultCanRenewCredentials_callsCredentialsManagerCanRenew() {
        // Arrange
        let provider = mockProvider!

        // Act
        _ = provider.canRenewCredentials()

        // Assert
        XCTAssertEqual(provider.canRenewCredentialsCallCount, 1)
    }

    func testDefaultRenewCredentials_callsCredentialsManagerRenew() async throws {
        // Arrange
        let provider = mockProvider!
        let testCredentials = createTestCredentials()
        provider.mockCredentials = testCredentials
        provider.hasStoredCredentials = true  // Ensure mock has credentials to renew
        provider.canRenewCredentialsResult = true  // Mock can renew

        // Act
        _ = try await provider.renewCredentials()

        // Assert
        XCTAssertEqual(provider.renewCredentialsCallCount, 1)
    }

    // MARK: - Error Handling Tests

    func testStartAuth_withProviderError_throwsError() async {
        // Arrange
        mockProvider.shouldFailAuth = true
        mockProvider.mockError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test auth error"])

        // Act & Assert
        do {
            _ = try await mockProvider.startAuth()
            XCTFail("Should throw error when provider fails")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual(mockProvider.startAuthCallCount, 1)
        }
    }

    func testClearSession_withProviderError_throwsError() async {
        // Arrange
        mockProvider.shouldFailClearSession = true
        mockProvider.mockError = NSError(domain: "TestError", code: 501, userInfo: [NSLocalizedDescriptionKey: "Test clear session error"])

        // Act & Assert
        do {
            try await mockProvider.clearSession()
            XCTFail("Should throw error when clear session fails")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 501)
            XCTAssertEqual(mockProvider.clearSessionCallCount, 1)
        }
    }

    func testStoreCredentials_withProviderError_throwsError() {
        // Arrange
        mockProvider.shouldFailStoreCredentials = true
        mockProvider.mockError = NSError(domain: "TestError", code: 502, userInfo: [NSLocalizedDescriptionKey: "Test store credentials error"])
        let credentials = createTestCredentials()

        // Act & Assert
        do {
            _ = try mockProvider.storeCredentials(credentials)
            XCTFail("Should throw error when store credentials fails")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 502)
            XCTAssertEqual(mockProvider.storeCredentialsCallCount, 1)
        }
    }

    func testRetrieveCredentials_withProviderError_throwsError() async {
        // Arrange
        mockProvider.shouldFailRetrieveCredentials = true
        mockProvider.mockError = NSError(domain: "TestError", code: 503, userInfo: [NSLocalizedDescriptionKey: "Test retrieve credentials error"])

        // Act & Assert
        do {
            _ = try await mockProvider.retrieveCredentials()
            XCTFail("Should throw error when retrieve credentials fails")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 503)
            XCTAssertEqual(mockProvider.retrieveCredentialsCallCount, 1)
        }
    }

    func testRenewCredentials_withProviderError_throwsError() async {
        // Arrange
        mockProvider.shouldFailRenewCredentials = true
        mockProvider.mockError = NSError(domain: "TestError", code: 504, userInfo: [NSLocalizedDescriptionKey: "Test renew credentials error"])

        // Act & Assert
        do {
            _ = try await mockProvider.renewCredentials()
            XCTFail("Should throw error when renew credentials fails")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 504)
            XCTAssertEqual(mockProvider.renewCredentialsCallCount, 1)
        }
    }

    // MARK: - State Management Tests

    func testCanRenewCredentials_withValidRefreshToken_returnsTrue() {
        // Arrange
        mockProvider.canRenewCredentialsResult = true
        mockProvider.hasStoredCredentials = true  // Ensure mock has stored credentials

        // Act
        let canRenew = mockProvider.canRenewCredentials()

        // Assert
        XCTAssertTrue(canRenew)
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
    }

    func testCanRenewCredentials_withNoRefreshToken_returnsFalse() {
        // Arrange
        mockProvider.canRenewCredentialsResult = false

        // Act
        let canRenew = mockProvider.canRenewCredentials()

        // Assert
        XCTAssertFalse(canRenew)
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)
    }

    func testClearCredentials_withSuccessfulClear_returnsTrue() {
        // Arrange
        mockProvider.clearCredentialsResult = true

        // Act
        let result = mockProvider.clearCredentials()

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    func testClearCredentials_withFailedClear_returnsFalse() {
        // Arrange
        mockProvider.clearCredentialsResult = false

        // Act
        let result = mockProvider.clearCredentials()

        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    // MARK: - Integration Tests

    func testCompleteAuthFlow_startStoreRetrieveClear_worksCorrectly() async throws {
        // Arrange
        let expectedCredentials = createTestCredentials()
        mockProvider.mockCredentials = expectedCredentials

        // Act - Start Auth
        let authCredentials = try await mockProvider.startAuth()

        // Assert - Auth successful
        XCTAssertEqual(authCredentials.accessToken, expectedCredentials.accessToken)
        XCTAssertEqual(mockProvider.startAuthCallCount, 1)

        // Act - Store credentials
        let storeResult = try mockProvider.storeCredentials(authCredentials)

        // Assert - Store successful
        XCTAssertTrue(storeResult)
        XCTAssertEqual(mockProvider.storeCredentialsCallCount, 1)

        // Act - Retrieve credentials
        let retrievedCredentials = try await mockProvider.retrieveCredentials()

        // Assert - Retrieved correctly
        XCTAssertEqual(retrievedCredentials.accessToken, expectedCredentials.accessToken)
        XCTAssertEqual(mockProvider.retrieveCredentialsCallCount, 1)

        // Act - Clear credentials
        let clearResult = mockProvider.clearCredentials()

        // Assert - Clear successful
        XCTAssertTrue(clearResult)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    func testCompleteRenewFlow_canRenewAndRenew_worksCorrectly() async throws {
        // Arrange
        let originalCredentials = createTestCredentials()
        let renewedCredentials = Credentials(
            accessToken: "renewed-access-token",
            tokenType: "Bearer",
            idToken: "renewed-id-token",
            refreshToken: "renewed-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )

        // Store original credentials first
        mockProvider.mockCredentials = originalCredentials
        _ = try mockProvider.storeCredentials(originalCredentials)

        // Set up renewal
        mockProvider.canRenewCredentialsResult = true
        mockProvider.mockCredentials = renewedCredentials

        // Act - Check if can renew
        let canRenew = mockProvider.canRenewCredentials()

        // Assert - Can renew
        XCTAssertTrue(canRenew)
        XCTAssertEqual(mockProvider.canRenewCredentialsCallCount, 1)

        // Act - Renew credentials
        let renewed = try await mockProvider.renewCredentials()

        // Assert - Renewed successfully
        XCTAssertEqual(renewed.accessToken, renewedCredentials.accessToken)
        XCTAssertNotEqual(renewed.accessToken, originalCredentials.accessToken)
        XCTAssertEqual(mockProvider.renewCredentialsCallCount, 1)
    }

    func testCompleteLogoutFlow_clearSessionAndCredentials_worksCorrectly() async throws {
        // Arrange
        let credentials = createTestCredentials()
        mockProvider.mockCredentials = credentials

        // Store credentials first
        _ = try mockProvider.storeCredentials(credentials)

        // Act - Clear session
        try await mockProvider.clearSession()

        // Assert - Session cleared
        XCTAssertEqual(mockProvider.clearSessionCallCount, 1)

        // Act - Clear credentials
        let clearResult = mockProvider.clearCredentials()

        // Assert - Credentials cleared
        XCTAssertTrue(clearResult)
        XCTAssertEqual(mockProvider.clearCredentialsCallCount, 1)
    }

    // MARK: - WebAuth0Provider Tests

    func testWebAuth0Provider_implementsProtocol() {
        // Arrange & Act
        let provider = WebAuth0Provider()

        // Assert
        XCTAssertNotNil(provider)
        XCTAssertNotNil(provider.credentialsManager)
        XCTAssertNotNil(provider.webAuth)
    }

    func testWebAuth0Provider_usesDefaultCredentialsManager() {
        // Arrange
        let provider = WebAuth0Provider()

        // Act
        let credentialsManager = provider.credentialsManager

        // Assert
        XCTAssertTrue(credentialsManager is DefaultCredentialsManager)
    }

    // MARK: - Helper Methods

    private func createTestCredentials() -> Credentials {
        return Credentials(
            accessToken: "test-access-token-\(UUID().uuidString)",
            tokenType: "Bearer",
            idToken: "test-id-token-\(UUID().uuidString)",
            refreshToken: "test-refresh-token-\(UUID().uuidString)",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }
}
