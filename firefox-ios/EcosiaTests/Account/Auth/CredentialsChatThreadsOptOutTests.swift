// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
@testable import Ecosia

final class CredentialsChatThreadsOptOutTests: XCTestCase {

    private let chatThreadsOptOutClaim = "https://ecosia.org/chat_threads_opt_out"

    func testMissingClaimDefaultsToFalse() throws {
        let credentials = try makeCredentials(claims: [
            "sub": "auth0|12345",
            "iat": Date().timeIntervalSince1970
        ])

        XCTAssertFalse(credentials.hasOptedOutOfChatThreads)
    }

    func testTrueClaimReturnsTrue() throws {
        let credentials = try makeCredentials(claims: [
            chatThreadsOptOutClaim: true
        ])

        XCTAssertTrue(credentials.hasOptedOutOfChatThreads)
    }

    func testFalseClaimReturnsFalse() throws {
        let credentials = try makeCredentials(claims: [
            chatThreadsOptOutClaim: false
        ])

        XCTAssertFalse(credentials.hasOptedOutOfChatThreads)
    }

    func testStagingEnvironmentTokenUsesProductionClaimKey() throws {
        let credentials = try makeCredentials(claims: [
            chatThreadsOptOutClaim: true,
            "https://ecosia-staging.xyz/chat_threads_opt_out": false
        ])

        XCTAssertTrue(credentials.hasOptedOutOfChatThreads)
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
        XCTAssertTrue(missing.chatThreadsOptOutClaimLogDetails().contains("present=false"))
        XCTAssertFalse(missing.chatThreadsOptOutClaimLogDetails().contains(missing.idToken))

        let optedOut = try makeCredentials(claims: [
            chatThreadsOptOutClaim: true
        ])
        let details = optedOut.chatThreadsOptOutClaimLogDetails()
        XCTAssertTrue(details.contains("present=true"))
        XCTAssertTrue(details.contains("value=true"))
        XCTAssertTrue(details.contains(chatThreadsOptOutClaim))
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
