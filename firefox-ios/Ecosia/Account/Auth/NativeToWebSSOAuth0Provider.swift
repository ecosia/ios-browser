// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0
import WebKit

// Ecosia: @unchecked Sendable because the struct stores protocol existentials
// (Auth0SettingsProviderProtocol, CredentialsManagerProtocol) that are not Sendable.
/// Native to Web SSO implementation of `Auth0ProviderProtocol` using Auth0's SDK and performing Native to Web SSO via REST API to perform the session token exchange.
public struct NativeToWebSSOAuth0Provider: Auth0ProviderProtocol, @unchecked Sendable {

    public let settings: Auth0SettingsProviderProtocol
    public let credentialsManager: CredentialsManagerProtocol
    private let environment: Environment

    enum NativeToWebSSOError: Error, Equatable {
        case invalidResponse
        case missingRefreshToken(String)
        case missingConfiguration(String)
    }

    public init(settings: Auth0SettingsProviderProtocol = DefaultAuth0SettingsProvider(),
                credentialsManager: CredentialsManagerProtocol? = nil,
                environment: Environment = .current) {
        self.settings = settings
        self.credentialsManager = credentialsManager ?? DefaultCredentialsManager(auth0SettingsProvider: settings)
        self.environment = environment
    }

    public var webAuth: WebAuth {
        configuredWebAuth(screenHint: .login)
    }

    public func startAuth(screenHint: AuthScreenHint) async throws -> Credentials {
        return try await configuredWebAuth(screenHint: screenHint).start()
    }

    private func configuredWebAuth(screenHint: AuthScreenHint) -> WebAuth {
        makeHttpsWebAuth()
            .useEphemeralSession()
            .audience(environment.urlProvider.authApiAudience.absoluteString)
            .scope(EcosiaAuthScopes.oauthScope)
            .parameters(["screen_hint": screenHint.rawValue])
    }

    /// Custom clearSession implementation that bypasses Auth0's default logout alert
    /// We provide immediate logout without any confirmation popups for better UX
    public func clearSession() async throws {
        // Skip calling webAuth.clearSession() to avoid Auth0's native logout alert
        // Logout happens immediately without any confirmation dialogs by clearing the auth session cookie
        await clearWebSessionCookies()
        EcosiaLogger.auth.info("\(Cookie.authSession.name) cookie cleared successfully")
    }

    /// Clears  all`EASC` (Ecosia Auth Session Cookie) cookies and any cookie scoped to the Auth0 tenant
    /// domain (e.g. `login.ecosia.org`) from the WKWebView's cookie store.
    ///
    /// The native login uses `.useEphemeralSession()` so it never leaves an Auth0 SSO session cookie behind, but the
    /// invisible tab used for session transfer runs on shared, persistent store so we must explictly clear the SSO cookie that is
    /// set by Auth0's custom domain - otherwise we risk silently re-using the previous user's still-valid Auth0 session.
    /// We don't know that cookie's name because it varies by tenant/SDK, so it's matched by domain instead.
    private func clearWebSessionCookies() async {
        let cookieStore = await WKWebsiteDataStore.default().httpCookieStore
        let auth0Domain = settings.domain
        let cookiesToClear = await cookieStore.allCookies().filter {
            $0.name == Cookie.authSession.name ||
            $0.domain == auth0Domain ||
            $0.domain == ".\(auth0Domain)" ||
            $0.domain.hasSuffix(".\(auth0Domain)")
        }
        for cookie in cookiesToClear {
            await cookieStore.deleteCookie(cookie)
        }
    }
}

extension NativeToWebSSOAuth0Provider {

    /// Requests the `session_token` with the `refresh_token`.
    ///
    /// - Returns: A `session_token` as `SessionToken` (a `String` type).
    /// - Throws: An error if the retrieval fails.
    public func getSSOCredentials() async throws -> SSOCredentials {
        let credentials = try await retrieveCredentials()
        guard let refreshToken = credentials.refreshToken else {
            throw NativeToWebSSOError.missingRefreshToken("Refresh token is missing. Please check your credentials.")
        }

        let configuration: URLSessionConfiguration = .default
        let ecosiaAuth0Session = URLSession(configuration: configuration.withCloudFlareAuthParameters())
        let ssoCredentials = try await Auth0
            .authentication(clientId: settings.id,
                            domain: settings.domain,
                            session: ecosiaAuth0Session)
            .ssoExchange(withRefreshToken: refreshToken)
            .start()
        persistRotatedRefreshToken(from: ssoCredentials, replacing: credentials)
        return ssoCredentials
    }

    /// With Refresh Token Rotation enabled the SSO exchange consumes the refresh token it is given and
    /// returns a new one. Storing it replaces the consumed token, otherwise the next renewal would present
    /// an already-used token, which Auth0 treats as reuse and answers by revoking the whole token family.
    /// Without rotation `ssoCredentials.refreshToken` is `nil` and the stored token is left untouched.
    func persistRotatedRefreshToken(from ssoCredentials: SSOCredentials, replacing credentials: Credentials) {
        guard let rotatedRefreshToken = ssoCredentials.refreshToken else { return }

        let updatedCredentials = Credentials(accessToken: credentials.accessToken,
                                             tokenType: credentials.tokenType,
                                             idToken: credentials.idToken,
                                             refreshToken: rotatedRefreshToken,
                                             expiresIn: credentials.expiresIn,
                                             scope: credentials.scope,
                                             recoveryCode: credentials.recoveryCode)
        guard credentialsManager.store(credentials: updatedCredentials) else {
            EcosiaLogger.auth.error("Failed to store rotated refresh token after SSO exchange")
            return
        }
        EcosiaLogger.auth.info("Stored rotated refresh token after SSO exchange")
    }

    /// Retrieves configuration values from the Auth0.plist file.
    ///
    /// - Parameter bundle: The bundle containing the Auth0.plist file. Defaults to `.ecosia`.
    /// - Returns: A tuple containing the `clientId` and `domain` if available, otherwise `nil`.
    func configurationValues(bundle: Bundle = .ecosia) -> (clientId: String, domain: String)? {
        guard let path = bundle.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            EcosiaLogger.auth.error("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
        }

        guard let clientId = values["ClientId"] as? String, let domain = values["Domain"] as? String else {
            EcosiaLogger.auth.error("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            return nil
        }
        return (clientId: clientId, domain: domain)
    }
}
