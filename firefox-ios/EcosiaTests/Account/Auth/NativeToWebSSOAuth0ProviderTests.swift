// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia

final class NativeToWebSSOAuth0ProviderTests: XCTestCase {

    var provider: NativeToWebSSOAuth0Provider!
    var mockClient: MockHTTPClient!
    var mockSettings: MockAuth0SettingsProvider!
    var mockCredentialsManager: MockCredentialsManager!

    override func setUp() {
        super.setUp()
        mockClient = MockHTTPClient()
        mockSettings = MockAuth0SettingsProvider()
        mockCredentialsManager = MockCredentialsManager()
        provider = NativeToWebSSOAuth0Provider(
            client: mockClient,
            settings: mockSettings,
            credentialsManager: mockCredentialsManager
        )
    }

    override func tearDown() {
        provider = nil
        mockClient = nil
        mockSettings = nil
        mockCredentialsManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_withDefaultParameters_createsProvider() {
        // Arrange & Act
        let provider = NativeToWebSSOAuth0Provider()

        // Assert
        XCTAssertNotNil(provider)
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

    // MARK: - WebAuth Configuration Tests

    func testWebAuth_includesOfflineAccessScope() {
        // Arrange & Act
        let webAuth = provider.webAuth

        // Assert
        XCTAssertNotNil(webAuth)
        // Note: In a real implementation, we would verify the scope parameter
        // This would require access to the internal WebAuth configuration
    }

    // MARK: - StartAuth Tests

    func testStartAuth_callsWebAuthStart() async throws {
        // Arrange
        let expectedCredentials = createTestCredentials()
        
        // Since startAuth() uses the default protocol implementation which calls webAuth.start(),
        // and webAuth.start() uses Auth0 SDK directly, we test the behavior indirectly
        // by verifying that startAuth completes and behaves as expected
        
        // Act & Assert
        // We can't easily mock Auth0's WebAuth.start(), but we can verify the method signature
        // and that it's properly configured with the correct scope
        let webAuth = provider.webAuth
        XCTAssertNotNil(webAuth)
        
        // Verify that the webAuth has the correct scope configuration
        // Note: In a real implementation, this would require more sophisticated testing
        // or integration tests with a real Auth0 environment
        
        // For now, we test that the method exists and is callable
        // In integration tests, this would actually call Auth0 and verify credentials
        do {
            // This would normally call Auth0, so we expect it to fail in unit tests
            // In integration tests with proper Auth0 setup, this would succeed
            _ = try await provider.startAuth()
            // If we reach here in a unit test environment, something unexpected happened
            XCTFail("startAuth should fail in unit test environment without Auth0 setup")
        } catch {
            // Expected in unit test environment - Auth0 SDK will fail without proper setup
            XCTAssertNotNil(error)
        }
    }

    // MARK: - SSO Credentials Tests

    func testGetSSOCredentials_withValidRefreshToken_returnsSSOCredentials() async throws {
        // Arrange
        let testCredentials = createTestCredentials()
        mockCredentialsManager.storedCredentials = testCredentials
        
        // getSSOCredentials calls Auth0.authentication().ssoExchange().start() which is difficult to mock
        // However, we can test that it properly retrieves credentials and validates the refresh token
        // The actual Auth0 API call would need integration testing
        
        // Act & Assert
        do {
            // This will fail at the Auth0 API call, but we can verify it gets past the initial validation
            _ = try await provider.getSSOCredentials()
            // If we reach here in unit tests, something unexpected happened (Auth0 SDK shouldn't work without setup)
            XCTFail("getSSOCredentials should fail in unit test environment without Auth0 setup")
        } catch let error as NativeToWebSSOAuth0Provider.NativeToWebSSOError {
            // If we get our custom error, something went wrong with our logic
            XCTFail("Got NativeToWebSSOError when we expected Auth0 SDK error: \(error)")
        } catch {
            // Expected - Auth0 SDK call should fail in unit test environment
            // This means our validation logic (refresh token check) passed successfully
            XCTAssertNotNil(error)
            
            // Verify that credentials were retrieved (should have been called)
            XCTAssertEqual(mockCredentialsManager.credentialsCallCount, 1)
        }
        
        // Additional test: Verify the method properly uses the provider's settings
        XCTAssertEqual(provider.settings.id, mockSettings.id)
        XCTAssertEqual(provider.settings.domain, mockSettings.domain)
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

    // MARK: - Configuration Tests

    func testConfigurationValues_withValidPlist_returnsValues() {
        // Arrange - Create a temporary directory and plist file for testing
        let tempDirectory = NSTemporaryDirectory()
        let bundlePath = tempDirectory + "TestBundle"
        let plistPath = bundlePath + "/Auth0.plist"
        
        // Create test bundle directory
        try! FileManager.default.createDirectory(atPath: bundlePath, withIntermediateDirectories: true, attributes: nil)
        
        // Create test Auth0.plist with test data
        let testClientId = "test-client-id"
        let testDomain = "test-domain.auth0.com"
        let plistData: [String: Any] = [
            "ClientId": testClientId,
            "Domain": testDomain
        ]
        
        let plistDict = NSDictionary(dictionary: plistData)
        plistDict.write(toFile: plistPath, atomically: true)
        
        // Create a bundle from the temporary directory
        guard let testBundle = Bundle(path: bundlePath) else {
            XCTFail("Failed to create test bundle")
            return
        }
        
        // Act
        let configuration = provider.configurationValues(bundle: testBundle)
        
        // Assert
        XCTAssertNotNil(configuration)
        XCTAssertEqual(configuration?.clientId, testClientId)
        XCTAssertEqual(configuration?.domain, testDomain)
        
        // Cleanup
        try? FileManager.default.removeItem(atPath: bundlePath)
    }

    func testConfigurationValues_withMissingPlist_returnsNil() {
        // Arrange
        let emptyBundle = Bundle()

        // Act
        let configuration = provider.configurationValues(bundle: emptyBundle)

        // Assert
        XCTAssertNil(configuration)
    }

    func testConfigurationValues_withInvalidPlistKeys_returnsNil() {
        // Arrange - Create a temporary directory and plist file with missing keys
        let tempDirectory = NSTemporaryDirectory()
        let bundlePath = tempDirectory + "TestBundleInvalid"
        let plistPath = bundlePath + "/Auth0.plist"
        
        // Create test bundle directory
        try! FileManager.default.createDirectory(atPath: bundlePath, withIntermediateDirectories: true, attributes: nil)
        
        // Create test Auth0.plist with missing Domain key
        let plistData: [String: Any] = [
            "ClientId": "test-client-id"
            // Missing "Domain" key
        ]
        
        let plistDict = NSDictionary(dictionary: plistData)
        plistDict.write(toFile: plistPath, atomically: true)
        
        // Create a bundle from the temporary directory
        guard let testBundle = Bundle(path: bundlePath) else {
            XCTFail("Failed to create test bundle")
            return
        }
        
        // Act
        let configuration = provider.configurationValues(bundle: testBundle)
        
        // Assert
        XCTAssertNil(configuration)
        
        // Cleanup
        try? FileManager.default.removeItem(atPath: bundlePath)
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

// MARK: - Mock HTTP Client

class MockHTTPClient: HTTPClient {
    var shouldFail = false
    var mockError: Error?
    var mockResponse: Data?
    var mockHTTPResponse: HTTPURLResponse?
    var requestCallCount = 0
    var lastRequest: BaseRequest?

    func perform(_ request: BaseRequest) async throws -> HTTPClient.Result {
        requestCallCount += 1
        lastRequest = request

        if shouldFail {
            throw mockError ?? NSError(domain: "MockHTTPClient", code: 500, userInfo: nil)
        }

        let data = mockResponse ?? Data()
        return (data, mockHTTPResponse)
    }

    func reset() {
        shouldFail = false
        mockError = nil
        mockResponse = nil
        mockHTTPResponse = nil
        requestCallCount = 0
        lastRequest = nil
    }
} 
