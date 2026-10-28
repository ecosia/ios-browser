// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia
// swiftlint:disable implicitly_unwrapped_optional

@MainActor
final class SessionTransferTokenTests: XCTestCase {

    var auth: EcosiaAuthenticationService!
    var credentialsManager: MockCredentialsManager!

    override func setUp() async throws {
        try await super.setUp()
        credentialsManager = MockCredentialsManager()
        let provider = NativeToWebSSOAuth0Provider(settings: MockAuth0SettingsProvider(),
                                                   credentialsManager: credentialsManager)
        auth = EcosiaAuthenticationService(auth0Provider: provider)
        auth.skipUserInfoFetch = true
        await auth.retrieveStoredCredentials()
    }

    override func tearDown() async throws {
        auth = nil
        credentialsManager = nil
        try await super.tearDown()
    }

    func testGetSessionTransferToken_whenExchangeSucceeds_returnsRetrieved() async {
        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .retrieved)
        XCTAssertNotNil(auth.getSessionTokenCookie())
    }

    func testGetSessionTransferToken_whenRefreshTokenIsRejected_returnsRefreshTokenRejected() async {
        credentialsManager.shouldFailSSOCredentials = true
        credentialsManager.mockError = AuthenticationError(
            info: ["error": "invalid_grant", "error_description": "Unknown or invalid refresh token."],
            statusCode: 403
        )

        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .refreshTokenRejected)
        XCTAssertNil(auth.getSessionTokenCookie())
    }

    func testGetSessionTransferToken_whenExchangeFailsForOtherReasons_returnsUnavailable() async {
        credentialsManager.shouldFailSSOCredentials = true
        credentialsManager.mockError = URLError(.notConnectedToInternet)

        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .unavailable)
        XCTAssertNil(auth.getSessionTokenCookie())
    }

    func testGetSessionTransferToken_whenLoggedOut_returnsUnavailable() async throws {
        try await auth.logout(triggerWebLogout: false)

        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(credentialsManager.ssoCredentialsCallCount, 0)
    }

    func testGetSessionTransferToken_withNoRefreshToken_returnsRefreshTokenRejected() async {
        credentialsManager.shouldFailSSOCredentials = true
        credentialsManager.mockError = CredentialsManagerError.noRefreshToken

        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .refreshTokenRejected)
    }

    func testGetSessionTransferToken_withNoCredentials_returnsRefreshTokenRejected() async {
        credentialsManager.shouldFailSSOCredentials = true
        credentialsManager.mockError = CredentialsManagerError.noCredentials

        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .refreshTokenRejected)
    }

    func testGetSessionTransferToken_withOtherCredentialsManagerError_returnsUnavailable() async {
        credentialsManager.shouldFailSSOCredentials = true
        credentialsManager.mockError = CredentialsManagerError.renewFailed

        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .unavailable)
    }

    func testGetSessionTransferToken_withOtherAuthenticationErrorCode_returnsUnavailable() async {
        credentialsManager.shouldFailSSOCredentials = true
        credentialsManager.mockError = AuthenticationError(info: ["error": "access_denied"], statusCode: 403)

        let result = await auth.getSessionTransferToken()

        XCTAssertEqual(result, .unavailable)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
