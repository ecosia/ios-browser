// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Combine
import Auth0
@testable import Ecosia

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

    func test_login_success_stores_credentials() async {
        // Arrange
        mockAuthProvider.shouldSucceed = true

        // Act
        await auth.login()

        // Assert
        XCTAssertTrue(auth.isLoggedIn)
        XCTAssertTrue(mockAuthProvider.credentialsManager.store(credentials: Credentials(accessToken: "mockAccessToken", refreshToken: "mockRefreshToken")))
    }

    func test_logout_clears_credentials() async {
        // Arrange
        mockAuthProvider.shouldSucceed = true

        // Act
        await auth.login()
        await auth.logout()

        // Assert
        XCTAssertFalse(auth.isLoggedIn)
        XCTAssertTrue(mockAuthProvider.credentialsManager.clear())
    }

    func test_retrieve_stored_credentials_success() async {
        // Arrange
        let mockStoredCredentials = Credentials(
            accessToken: "mockAccessToken",
            tokenType: "Bearer",
            idToken: "mockIdToken",
            refreshToken: "mockRefreshToken",
            expiresIn: Date(),
            scope: "openid profile email"
        )

        // Act
        do {
            try mockAuthProvider.storeCredentials(mockStoredCredentials)
        } catch {
            XCTFail(error.localizedDescription)
        }

        await auth.retrieveStoredCredentials()

        // Assert
        XCTAssertTrue(auth.isLoggedIn)
    }

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
