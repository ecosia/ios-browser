// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// OAuth scopes requested during native Auth0 authentication.
public enum EcosiaAuthScopes: String, CaseIterable {
    case openid
    case profile
    case email
    case offlineAccess = "offline_access"
    case impactRead = "read:impact"
    case impactWrite = "write:impact"
    case conversationsRead = "read:conversations"
    case conversationsWrite = "write:conversations"
    case conversationsUpdate = "update:conversations"
    case conversationsDelete = "delete:conversations"

    public static let scopeSeparator = " "

    public static let oauthScope = scopeString(from: allCases)

    public static func conversationCases() -> [EcosiaAuthScopes] {
        [
            conversationsRead,
            conversationsWrite,
            conversationsUpdate,
            conversationsDelete
        ]
    }

    public static let conversationScopes: Set<String> = Set(conversationCases().map(\.rawValue))

    public static func scopeString<S: Sequence>(from scopes: S) -> String where S.Element == EcosiaAuthScopes {
        scopes.map(\.rawValue).joined(separator: scopeSeparator)
    }

    public static func hasConversationScopes(in accessToken: String, grantedScope: String? = nil) -> Bool {
        if let grantedScope, conversationScopes.isSubset(of: parseScopeString(grantedScope)) {
            return true
        }
        guard let grantedScopes = parseScopeClaim(from: accessToken) else { return false }
        return conversationScopes.isSubset(of: grantedScopes)
    }

    public static func parseScopeString(_ scope: String) -> Set<String> {
        Set(scope.split(separator: " ").map(String.init))
    }

    public static func parseScopeClaim(from accessToken: String) -> Set<String>? {
        guard let payload = jwtPayload(from: accessToken) else { return nil }
        if let scope = payload["scope"] as? String {
            return Set(scope.split(separator: " ").map(String.init))
        }
        if let scopes = payload["scope"] as? [String] {
            return Set(scopes)
        }
        return nil
    }

    private static func jwtPayload(from token: String) -> [String: Any]? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - base64.count % 4
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
        }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}
