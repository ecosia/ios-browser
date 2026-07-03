// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Exchanges staging Cloudflare Access service-token credentials for a
/// `CF_Authorization` cookie and stores it in the WKWebView cookie jar.
///
/// AI chat calls `api.ecosia-staging.xyz` from JavaScript; `Tab.ecosiaUpdatedRequest`
/// only adds service-token headers to top-level navigations. Planting the cookie lets
/// fetch/XHR authenticate without patching page scripts.
///
/// Native `URLSession` uploads also call this on staging so presign POSTs carry the
/// cookie when Cloudflare Access rejects service-token headers alone.
///
/// Staging-only — production has no Cloudflare Access on the API host.
public enum CloudflareAccessCookieBootstrap {

    static let authorizationCookieName = "CF_Authorization"

    /// Fetches `CF_Authorization` via service-token headers and copies it into the
    /// default WK cookie store (and shared `HTTPCookieStorage` for consistency).
    @MainActor
    public static func syncAuthorizationCookieToWebView(
        environment: Environment = .current,
        cookieStore: CookieStoreProtocol = WKWebsiteDataStore.default().httpCookieStore
    ) async {
        guard environment == .staging, let auth = environment.cloudFlareAuth else {
            return
        }

        let apiURL = environment.urlProvider.apiRoot
        EcosiaLogger.network.info(
            "[CloudflareAccess] Bootstrapping \(authorizationCookieName) for \(apiURL.host ?? "api")"
        )

        do {
            guard let cookie = try await fetchAuthorizationCookie(apiURL: apiURL, auth: auth) else {
                EcosiaLogger.network.error(
                    "[CloudflareAccess] No \(authorizationCookieName) cookie returned from \(apiURL.absoluteString)"
                )
                return
            }

            HTTPCookieStorage.shared.setCookie(cookie)
            await cookieStore.setCookie(cookie)
            EcosiaLogger.network.info(
                "[CloudflareAccess] Stored \(authorizationCookieName) for domain=\(cookie.domain)"
            )
        } catch {
            EcosiaLogger.network.error(
                "[CloudflareAccess] Cookie bootstrap failed: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Private

    private static func fetchAuthorizationCookie(
        apiURL: URL,
        auth: Environment.CloudFlareAuth
    ) async throws -> HTTPCookie? {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request = request.withCloudFlareAuthParameters(auth: auth)

        let delegate = CookieCaptureDelegate()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = true
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)

        let (_, response) = try await session.data(for: request)
        session.invalidateAndCancel()

        var cookies = delegate.capturedCookies
        if let http = response as? HTTPURLResponse, let url = http.url {
            cookies.append(contentsOf: authorizationCookies(from: http, for: url))
        }
        cookies.append(contentsOf: HTTPCookieStorage.shared.cookies(for: apiURL) ?? [])

        return cookies.first(where: { $0.name == authorizationCookieName })
    }

    static func authorizationCookies(from response: HTTPURLResponse, for url: URL) -> [HTTPCookie] {
        let headerFields = stringHeaderFields(from: response.allHeaderFields)
        return HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            .filter { $0.name == authorizationCookieName }
    }

    static func stringHeaderFields(from allHeaderFields: [AnyHashable: Any]) -> [String: String] {
        allHeaderFields.reduce(into: [String: String]()) { fields, entry in
            guard let key = entry.key as? String,
                  let value = entry.value as? String else {
                return
            }
            fields[key] = value
        }
    }
}

// MARK: - Redirect cookie capture

private final class CookieCaptureDelegate: NSObject, URLSessionTaskDelegate {

    private(set) var capturedCookies: [HTTPCookie] = []

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        if let url = response.url {
            capturedCookies.append(
                contentsOf: CloudflareAccessCookieBootstrap.authorizationCookies(from: response, for: url)
            )
        }
        completionHandler(request)
    }
}
