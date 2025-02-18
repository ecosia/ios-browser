// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Combine
import Auth0
@testable import Core

/// Test suite for the `Auth` class, validating login, logout, credential storage, and renewal.
final class AuthTests: XCTestCase {
    private var auth: Auth!
    private var mockAuthProvider: MockAuth0Provider!

    override func setUp() {
        super.setUp()
        mockAuthProvider = MockAuth0Provider()
        auth = Auth(auth0Provider: mockAuthProvider)
    }

    override func tearDown() {
        auth = nil
        mockAuthProvider = nil
        super.tearDown()
    }

    /// Tests a successful login and credential storage.
    func test_login_success_stores_credentials() async {
        // Arrange
        mockAuthProvider.shouldSucceed = true

        // Act
        await auth.login()

        // Assert
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertTrue(mockAuthProvider.credentialsStored)
    }

    /// Tests a successful logout and credential clearing.
    func test_logout_clears_credentials() async {
        // Arrange
        mockAuthProvider.shouldSucceed = true

        // Act
        await auth.login()
        await auth.logout()

        // Assert
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertTrue(mockAuthProvider.credentialsCleared)
    }

    /// Tests retrieving stored credentials successfully.
    func test_retrieve_stored_credentials_success() async {
        // Arrange
        mockAuthProvider.credentialsToReturn = Credentials(accessToken: "mockAccessToken",
                                                           tokenType: "Bearer",
                                                           idToken: "mockIdToken",
                                                           refreshToken: "mockRefreshToken",
                                                           expiresIn: Date(),
                                                           scope: "openid profile email")

        // Act
        await auth.retrieveStoredCredentials()

        // Assert
        XCTAssertTrue(auth.isLoggedIn)
    }

    /// Tests renewing credentials successfully.
    func test_renew_credentials_success() async {
        // Arrange
        mockAuthProvider.shouldSucceed = true
        mockAuthProvider.canRenew = true

        // Act
        await auth.renewCredentialsIfNeeded()

        // Assert
        XCTAssertTrue(auth.isLoggedIn)
    }
}

/// Mock implementation of `Auth0ProviderProtocol` for testing purposes.
class MockAuth0Provider: Auth0ProviderProtocol {
    var shouldSucceed = true
    var credentialsStored = false
    var credentialsCleared = false
    var canRenew = false
    var credentialsToReturn: Credentials?

    func startAuth() async throws -> Credentials {
        if shouldSucceed {
            return Credentials(accessToken: "mockAccessToken", tokenType: "Bearer", idToken: "mockIdToken", refreshToken: "mockRefreshToken", expiresIn: Date(), scope: "openid profile email")
        } else {
            throw NSError(domain: "MockAuthError", code: 1, userInfo: nil)
        }
    }

    func clearSession() async throws {
        if !shouldSucceed {
            throw NSError(domain: "MockAuthError", code: 2, userInfo: nil)
        }
    }

    func storeCredentials(_ credentials: Credentials) throws -> Bool {
        if shouldSucceed {
            credentialsStored = true
            return true
        } else {
            throw NSError(domain: "MockAuthError", code: 3, userInfo: nil)
        }
    }

    func retrieveCredentials() async throws -> Credentials {
        if let credentials = credentialsToReturn {
            return credentials
        } else {
            throw NSError(domain: "MockAuthError", code: 4, userInfo: nil)
        }
    }

    func clearCredentials() -> Bool {
        credentialsCleared = true
        return true
    }

    func canRenewCredentials() -> Bool {
        return canRenew
    }

    func renewCredentials() async throws -> Credentials {
        if shouldSucceed {
            return Credentials(accessToken: "mockAccessToken", tokenType: "Bearer", idToken: "mockIdToken", refreshToken: "mockRefreshToken", expiresIn: Date(), scope: "openid profile email")
        } else {
            throw NSError(domain: "MockAuthError", code: 5, userInfo: nil)
        }
    }
}
