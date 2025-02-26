// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia

/// Test suite for the `NativeToWebSSOAuth0Provider` class, validating session token retrieval.
final class NativeToWebSSOAuth0ProviderTests: XCTestCase {
    private var provider: NativeToWebSSOAuth0Provider!
    private var mockHTTPClient: MockHTTPClient!
    private var mockCredentialsManager: MockCredentialsManager!

    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        mockCredentialsManager = MockCredentialsManager()
        provider = NativeToWebSSOAuth0Provider(client: mockHTTPClient,
                                               credentialsManager: mockCredentialsManager)
    }

    override func tearDown() {
        provider = nil
        mockHTTPClient = nil
        mockCredentialsManager = nil
        super.tearDown()
    }

    func test_get_session_token_success() async throws {
        // Arrange
        let expectedToken = "expected_session_token"
        let mockCredentials = Credentials(accessToken: "accessToken", refreshToken: "refreshToken")
        mockCredentialsManager.store(credentials: mockCredentials)

        let response  = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        mockHTTPClient.performResult = (try JSONEncoder().encode(TokenResponse(accessToken: expectedToken)), response)

        // Act
        let sessionToken = try await provider.getSessionToken()

        // Assert
        XCTAssertEqual(sessionToken, expectedToken)
    }

    func test_get_session_token_missing_refresh_token() async throws {
        // Arrange
        mockCredentialsManager.store(credentials: Credentials())

        // Act & Assert
        do {
            _ = try await provider.getSessionToken()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NativeToWebSSOAuth0Provider.NativeToWebSSOError,
                           .missingRefreshToken("Refresh token is missing. Please check your credentials."))
        }
    }

    func test_get_session_token_invalid_response() async throws {
        // Arrange
        let mockCredentials = Credentials(accessToken: "accessToken", refreshToken: "refreshToken")
        mockCredentialsManager.store(credentials: mockCredentials)

        let response  = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )
        mockHTTPClient.performResult = (Data(), response)

        // Act & Assert
        do {
            _ = try await provider.getSessionToken()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NativeToWebSSOAuth0Provider.NativeToWebSSOError, .invalidResponse)
        }
    }
}

final class NativeToWebSSOAuth0MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        return (mockData ?? Data(), mockResponse ?? URLResponse())
    }
}
