// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class EcosiaAuthScopesTests: XCTestCase {

    private static let allConversationScopes =
        EcosiaAuthScopes.scopeString(from: EcosiaAuthScopes.conversationCases())

    func testOAuthScope_matchesExpectedScopeString() {
        XCTAssertEqual(
            EcosiaAuthScopes.oauthScope,
            "openid profile email offline_access read:impact write:impact " +
            "read:conversations write:conversations update:conversations delete:conversations"
        )
    }

    func testScopeString_whenGivenConversationCases_matchesExpectedScopeString() {
        XCTAssertEqual(
            EcosiaAuthScopes.scopeString(from: EcosiaAuthScopes.conversationCases()),
            "read:conversations write:conversations update:conversations delete:conversations"
        )
    }

    func testParseScopeString_whenGivenOAuthScope_returnsAllScopeValues() {
        XCTAssertEqual(
            EcosiaAuthScopes.parseScopeString(EcosiaAuthScopes.oauthScope),
            Set(EcosiaAuthScopes.allCases.map(\.rawValue))
        )
    }

    func testHasConversationScopes_whenScopesPresent_returnsTrue() {
        let token = Self.makeJWT(scope: "openid \(Self.allConversationScopes)")
        XCTAssertTrue(EcosiaAuthScopes.hasConversationScopes(in: token))
    }

    func testHasConversationScopes_whenScopesMissing_returnsFalse() {
        let token = Self.makeJWT(scope: "openid profile email")
        XCTAssertFalse(EcosiaAuthScopes.hasConversationScopes(in: token))
    }

    func testHasConversationScopes_whenGrantedScopeContainsConversationScopes_returnsTrueWithoutJWTScope() {
        let opaqueToken = "opaque-access-token"
        XCTAssertTrue(
            EcosiaAuthScopes.hasConversationScopes(
                in: opaqueToken,
                grantedScope: "openid \(Self.allConversationScopes)"
            )
        )
    }

    func testParseScopeClaim_whenScopeIsArray_returnsSet() {
        let token = Self.makeJWT(scopeArray: ["read:conversations", "write:conversations"])
        let scopes = EcosiaAuthScopes.parseScopeClaim(from: token)
        XCTAssertEqual(scopes, ["read:conversations", "write:conversations"])
    }

    private static func makeJWT(scope: String) -> String {
        let payload = #"{"scope":"\#(scope)"}"#
        return "header.\(base64URL(payload)).signature"
    }

    private static func makeJWT(scopeArray: [String]) -> String {
        let joined = scopeArray.map { "\"\($0)\"" }.joined(separator: ",")
        let payload = #"{"scope":[\#(joined)]}"#
        return "header.\(base64URL(payload)).signature"
    }

    private static func base64URL(_ string: String) -> String {
        Data(string.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
