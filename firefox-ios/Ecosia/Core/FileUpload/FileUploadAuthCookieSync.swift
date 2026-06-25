// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Bridges `EASC` from the WKWebView cookie jar into `HTTPCookieStorage.shared`.
///
/// Native API calls (`URLSession`) do not see cookies that only exist in
/// `WKWebsiteDataStore`. The AI Worker presign route currently authenticates via
/// the `EASC` session cookie (web login), not the Auth0 Bearer token.
enum FileUploadAuthCookieSync {

    /// Copies `EASC` from WK into shared storage and returns it for explicit request headers.
    @discardableResult
    static func syncAuthSessionCookieToSharedStorage(
        urlProvider: URLProvider = Environment.current.urlProvider
    ) async -> HTTPCookie? {
        let webCookies = await webViewCookies()
        let easc = webCookies.first { $0.name == Cookie.authSession.rawValue }

        if let easc {
            HTTPCookieStorage.shared.setCookie(easc)
            EcosiaLogger.network.info(
                "[FileUpload] Synced EASC from WK cookie store to HTTPCookieStorage (domain=\(easc.domain))"
            )
        } else {
            EcosiaLogger.network.error(
                "[FileUpload] No EASC cookie in WK cookie store — presign may return 401 until web session is established"
            )
        }

        let sharedCookies = HTTPCookieStorage.shared.cookies(for: urlProvider.apiRoot) ?? []
        let sharedEASC = sharedCookies.contains { $0.name == Cookie.authSession.rawValue }
        EcosiaLogger.network.info(
            "[FileUpload] EASC in HTTPCookieStorage for api root: \(sharedEASC) (total cookies=\(sharedCookies.count))"
        )

        return easc ?? sharedCookies.first { $0.name == Cookie.authSession.rawValue }
    }

    private static func webViewCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
    }
}

enum FileUploadAuthDiagnostics {

    static func logAccessTokenScopes(_ accessToken: String) {
        guard let payload = jwtPayload(from: accessToken) else {
            EcosiaLogger.network.error("[FileUpload] Could not decode access token JWT payload")
            return
        }

        if let scope = payload["scope"] as? String {
            let hasWriteConversations = scope.contains("write:conversations")
            EcosiaLogger.network.info(
                "[FileUpload] Token scopes: \(scope) (write:conversations=\(hasWriteConversations))"
            )
            if !hasWriteConversations {
                EcosiaLogger.network.error(
                    "[FileUpload] Token is missing write:conversations — sign out and sign in again to refresh scopes"
                )
            }
        } else if let scopes = payload["scope"] as? [String] {
            let joined = scopes.joined(separator: " ")
            let hasWriteConversations = joined.contains("write:conversations")
            EcosiaLogger.network.info(
                "[FileUpload] Token scopes: \(joined) (write:conversations=\(hasWriteConversations))"
            )
        } else {
            EcosiaLogger.network.error("[FileUpload] Token payload has no scope claim")
        }
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
