// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia

final class CredentialsChatThreadsOptOutTests: XCTestCase {

    func testMissingClaimDefaultsToFalse() throws {
        let credentials = try makeCredentials(claims: [
            "sub": "auth0|12345",
            "iat": Date().timeIntervalSince1970
        ])

        XCTAssertFalse(credentials.hasOptedOutOfChatThreads)
    }

    func testTrueClaimReturnsTrue() throws {
        let credentials = try makeCredentials(claims: [
            URLProvider.production.chatThreadsOptOutClaim: true
        ])

        XCTAssertTrue(credentials.hasOptedOutOfChatThreads(urlProvider: .production))
    }

    func testFalseClaimReturnsFalse() throws {
        let credentials = try makeCredentials(claims: [
            URLProvider.production.chatThreadsOptOutClaim: false
        ])

        XCTAssertFalse(credentials.hasOptedOutOfChatThreads(urlProvider: .production))
    }

    func testStagingClaimIsNotReadAsProduction() throws {
        let credentials = try makeCredentials(claims: [
            URLProvider.staging.chatThreadsOptOutClaim: true
        ])

        XCTAssertTrue(credentials.hasOptedOutOfChatThreads(urlProvider: .staging))
        XCTAssertFalse(credentials.hasOptedOutOfChatThreads(urlProvider: .production))
    }

    func testUndecodableIdTokenDefaultsToFalse() {
        let credentials = Credentials(
            accessToken: "access",
            tokenType: "Bearer",
            idToken: "not-a-jwt",
            refreshToken: "refresh",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid"
        )

        XCTAssertFalse(credentials.hasOptedOutOfChatThreads)
    }

    func testLogDetailsDescribeMissingAndPresentClaimsWithoutTheToken() throws {
        let token = "not-a-jwt"
        let undecodable = Credentials(
            accessToken: "access",
            tokenType: "Bearer",
            idToken: token,
            refreshToken: "refresh",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid"
        )
        XCTAssertTrue(undecodable.chatThreadsOptOutClaimLogDetails().contains("decode=failed"))
        XCTAssertFalse(undecodable.chatThreadsOptOutClaimLogDetails().contains(token))

        let missing = try makeCredentials(claims: ["sub": "auth0|12345"])
        XCTAssertTrue(missing.chatThreadsOptOutClaimLogDetails(urlProvider: .production).contains("present=false"))
        XCTAssertFalse(missing.chatThreadsOptOutClaimLogDetails().contains(missing.idToken))

        let optedOut = try makeCredentials(claims: [
            URLProvider.production.chatThreadsOptOutClaim: true
        ])
        let details = optedOut.chatThreadsOptOutClaimLogDetails(urlProvider: .production)
        XCTAssertTrue(details.contains("present=true"))
        XCTAssertTrue(details.contains("value=true"))
        XCTAssertTrue(details.contains(URLProvider.production.chatThreadsOptOutClaim))
        XCTAssertFalse(details.contains(optedOut.idToken))
    }

    private func makeCredentials(claims: [String: Any]) throws -> Credentials {
        Credentials(
            accessToken: "access",
            tokenType: "Bearer",
            idToken: try makeJWT(claims: claims),
            refreshToken: "refresh",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid"
        )
    }

    private func makeJWT(claims: [String: Any]) throws -> String {
        let header = #"{"alg":"RS256","typ":"JWT"}"#
        let payloadData = try JSONSerialization.data(withJSONObject: claims)
        let payload = try XCTUnwrap(String(data: payloadData, encoding: .utf8))

        func base64URLEncode(_ string: String) -> String {
            Data(string.utf8)
                .base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }

        return "\(base64URLEncode(header)).\(base64URLEncode(payload)).mock-signature"
    }
}
