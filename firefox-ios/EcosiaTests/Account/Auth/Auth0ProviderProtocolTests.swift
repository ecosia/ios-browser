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

    func testDefaultWebAuth_returnsAuth0WebAuth() {
        // Arrange
        let provider: Auth0ProviderProtocol = WebAuth0Provider()

        // Act
        let webAuth = provider.webAuth

        // Assert
        XCTAssertNotNil(webAuth)
        XCTAssertEqual(webAuth.clientId, "zNU6cgqji5cE9qPkkXIlqMJbIwTPShdU")
        XCTAssertEqual(webAuth.url.absoluteString, "https://ecosia-staging.eu.auth0.com/")
    }

    // MARK: - State Management Tests (Protocol Default Implementation Verification)

    func testDefaultStartAuth_callsWebAuthStart() async throws {
        // Arrange
        let provider = makeSUT()
        let mockWebAuth = provider.webAuth as? MockWebAuth
        mockWebAuth?.mockCredentials = createTestCredentials()

        // Act
        _ = try await provider.startAuth()

        // Assert
        XCTAssertEqual(mockWebAuth?.startCallCount, 1, "Protocol should delegate to webAuth.start()")
    }

    func testDefaultClearSession_callsWebAuthClearSession() async throws {
        // Arrange
        let provider = makeSUT()
        let mockWebAuth = provider.webAuth as? MockWebAuth

        // Act
        try await provider.clearSession()

        // Assert
        XCTAssertEqual(mockWebAuth?.clearSessionCallCount, 1, "Protocol should delegate to webAuth.clearSession()")
    }

    func testDefaultStoreCredentials_callsCredentialsManagerStore() throws {
        // Arrange
        let provider = makeSUT()
        let mockCredentialsManager = provider.credentialsManager as? MockCredentialsManager
        let testCredentials = createTestCredentials()

        // Act
        _ = try provider.storeCredentials(testCredentials)

        // Assert
        XCTAssertEqual(mockCredentialsManager?.storeCallCount, 1, "Protocol should delegate to credentialsManager.store()")
        XCTAssertEqual(mockCredentialsManager?.lastStoredCredentials?.accessToken, testCredentials.accessToken)
    }

    func testDefaultRetrieveCredentials_callsCredentialsManagerCredentials() async throws {
        // Arrange
        let provider = makeSUT()
        let mockCredentialsManager = provider.credentialsManager as? MockCredentialsManager
        mockCredentialsManager?.storedCredentials = createTestCredentials()

        // Act
        _ = try await provider.retrieveCredentials()

        // Assert
        XCTAssertEqual(mockCredentialsManager?.credentialsCallCount, 1, "Protocol should delegate to credentialsManager.credentials()")
    }

    func testDefaultClearCredentials_callsCredentialsManagerClear() {
        // Arrange
        let provider = makeSUT()
        let mockCredentialsManager = provider.credentialsManager as? MockCredentialsManager

        // Act
        let result = provider.clearCredentials()

        // Assert
        XCTAssertEqual(mockCredentialsManager?.clearCallCount, 1, "Protocol should delegate to credentialsManager.clear()")
        XCTAssertTrue(result)
    }

    func testDefaultCanRenewCredentials_callsCredentialsManagerCanRenew() {
        // Arrange
        let provider = makeSUT()
        let mockCredentialsManager = provider.credentialsManager as? MockCredentialsManager
        mockCredentialsManager?.canRenewResult = true

        // Act
        let result = provider.canRenewCredentials()

        // Assert
        XCTAssertEqual(mockCredentialsManager?.canRenewCallCount, 1, "Protocol should delegate to credentialsManager.canRenew")
        XCTAssertTrue(result)
    }

    func testDefaultRenewCredentials_callsCredentialsManagerRenew() async throws {
        // Arrange
        let provider = makeSUT()
        let mockCredentialsManager = provider.credentialsManager as? MockCredentialsManager
        let testCredentials = createTestCredentials()
        mockCredentialsManager?.storedCredentials = testCredentials

        // Act
        _ = try await provider.renewCredentials()

        // Assert
        XCTAssertEqual(mockCredentialsManager?.renewCallCount, 1, "Protocol should delegate to credentialsManager.renew()")
    }

    // MARK: - Mock Provider Tests (Legacy - for backward compatibility)

    func testMockProviderStartAuth_callsWebAuthStart() async throws {
        // Arrange
        let provider = mockProvider!

        // Act
        _ = try await provider.startAuth()

        // Assert
        XCTAssertEqual(provider.startAuthCallCount, 1)
    }

    func testMockProviderClearSession_callsWebAuthClearSession() async throws {
        // Arrange
        let provider = mockProvider!

        // Act
        try await provider.clearSession()

        // Assert
        XCTAssertEqual(provider.clearSessionCallCount, 1)
    }

    func testMockProviderStoreCredentials_callsCredentialsManagerStore() throws {
        // Arrange
        let provider = mockProvider!
        let credentials = createTestCredentials()

        // Act
        _ = try provider.storeCredentials(credentials)

        // Assert
        XCTAssertEqual(provider.storeCredentialsCallCount, 1)
    }

    func testMockProviderRetrieveCredentials_callsCredentialsManagerCredentials() async throws {
        // Arrange
        let provider = mockProvider!
        let testCredentials = createTestCredentials()
        provider.mockCredentials = testCredentials
        provider.hasStoredCredentials = true

        // Act
        _ = try await provider.retrieveCredentials()

        // Assert
        XCTAssertEqual(provider.retrieveCredentialsCallCount, 1)
    }

    func testMockProviderClearCredentials_callsCredentialsManagerClear() {
        // Arrange
        let provider = mockProvider!
        provider.hasStoredCredentials = true

        // Act
        let result = provider.clearCredentials()

        // Assert
        XCTAssertEqual(provider.clearCredentialsCallCount, 1)
        XCTAssertTrue(result)
    }

    func testMockProviderCanRenewCredentials_callsCredentialsManagerCanRenew() {
        // Arrange
        let provider = mockProvider!
        provider.hasStoredCredentials = true

        // Act
        let result = provider.canRenewCredentials()

        // Assert
        XCTAssertEqual(provider.canRenewCredentialsCallCount, 1)
        XCTAssertTrue(result)
    }

    func testMockProviderRenewCredentials_callsCredentialsManagerRenew() async throws {
        // Arrange
        let provider = mockProvider!
        let testCredentials = createTestCredentials()
        provider.mockCredentials = testCredentials
        provider.hasStoredCredentials = true

        // Act
        _ = try await provider.renewCredentials()

        // Assert
        XCTAssertEqual(provider.renewCredentialsCallCount, 1)
    }

    // MARK: - Error Handling Tests

    func testStartAuth_withError_throwsError() async {
        // Arrange
        let provider = mockProvider!
        let expectedError = NSError(domain: "TestError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        provider.shouldFailAuth = true
        provider.mockError = expectedError

        // Act & Assert
        do {
            _ = try await provider.startAuth()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(provider.startAuthCallCount, 1)
            XCTAssertEqual((error as NSError).code, expectedError.code)
        }
    }

    func testClearSession_withError_throwsError() async {
        // Arrange
        let provider = mockProvider!
        let expectedError = NSError(domain: "TestError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        provider.shouldFailClearSession = true
        provider.mockError = expectedError

        // Act & Assert
        do {
            try await provider.clearSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(provider.clearSessionCallCount, 1)
            XCTAssertEqual((error as NSError).code, expectedError.code)
        }
    }

    func testStoreCredentials_withError_throwsError() {
        // Arrange
        let provider = mockProvider!
        let credentials = createTestCredentials()
        let expectedError = NSError(domain: "TestError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        provider.shouldFailStoreCredentials = true
        provider.mockError = expectedError

        // Act & Assert
        do {
            _ = try provider.storeCredentials(credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(provider.storeCredentialsCallCount, 1)
            XCTAssertEqual((error as NSError).code, expectedError.code)
        }
    }

    func testRetrieveCredentials_withError_throwsError() async {
        // Arrange
        let provider = mockProvider!
        let expectedError = NSError(domain: "TestError", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        provider.shouldFailRetrieveCredentials = true
        provider.mockError = expectedError

        // Act & Assert
        do {
            _ = try await provider.retrieveCredentials()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(provider.retrieveCredentialsCallCount, 1)
            XCTAssertEqual((error as NSError).code, expectedError.code)
        }
    }

    func testRenewCredentials_withError_throwsError() async {
        // Arrange
        let provider = mockProvider!
        let expectedError = NSError(domain: "TestError", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        provider.shouldFailRenewCredentials = true
        provider.mockError = expectedError

        // Act & Assert
        do {
            _ = try await provider.renewCredentials()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(provider.renewCredentialsCallCount, 1)
            XCTAssertEqual((error as NSError).code, expectedError.code)
        }
    }

    // MARK: - Helper Methods

    private func createTestCredentials() -> Credentials {
        return Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }
}

// MARK: - TestableAuth0Provider

/// A minimal provider that relies on protocol default implementations for testing
class DefaultImplementationTestableProvider: Auth0ProviderProtocol {
    let webAuth: WebAuth
    let credentialsManager: CredentialsManagerProtocol

    init(webAuth: WebAuth, credentialsManager: CredentialsManagerProtocol) {
        self.webAuth = webAuth
        self.credentialsManager = credentialsManager
    }
}

extension Auth0ProviderProtocolTests {

    func makeSUT() -> Auth0ProviderProtocol {
        let mockWebAuth = MockWebAuth()
        let mockCredentialsManager = MockCredentialsManager()
        return DefaultImplementationTestableProvider(webAuth: mockWebAuth,
                                                     credentialsManager: mockCredentialsManager)
    }
}
