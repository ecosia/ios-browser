// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import WebKit
import Common

/// The `Auth` class manages user authentication, credential storage, and renewal using Auth0.
public class Auth {

    public static let shared = Auth()

    public static let defaultCredentialsManager: CredentialsManagerProtocol = DefaultCredentialsManager()
    public let auth0Provider: Auth0ProviderProtocol
    private(set) var idToken: String?
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var ssoCredentials: SSOCredentials?

    /// Indicates whether the user is currently logged in.
    public private(set) var isLoggedIn: Bool = false

    /// Initializes a new instance of the `Auth` class with a specified authentication provider.
    ///
    /// - Parameter auth0Provider: An object conforming to `Auth0ProviderProtocol`.
    public init(auth0Provider: Auth0ProviderProtocol = WebAuth0Provider()) {
        self.auth0Provider = auth0Provider
        Task {
            await self.retrieveStoredCredentials()
        }
    }

    /// Logs in the user asynchronously and stores credentials if successful.
    /// - Throws: `LoginError.authenticationFailed` if Auth0 authentication fails,
    ///           `LoginError.credentialStorageError` if credential storage throws an error,
    ///           `LoginError.credentialStorageFailed` if credential storage returns false.
    public func login() async throws {
        // First, attempt authentication
        let credentials: Credentials
        do {
            credentials = try await auth0Provider.startAuth()
            print("\(#file).\(#function) - 👤 Auth - Authentication successful.")
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Authentication failed: \(error)")
            throw AuthError.authenticationFailed(error)
        }

        // Then, attempt to store credentials
        do {
            let didStore = try auth0Provider.storeCredentials(credentials)
            if didStore {
                setupTokensWithCredentials(credentials, settingLoggedInStateTo: true)
                print("\(#file).\(#function) - 👤 Auth - Login completed successfully.")
            } else {
                print("\(#file).\(#function) - 👤 Auth - Credential storage failed (returned false).")
                throw AuthError.credentialsStorageFailed
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Credential storage error: \(error)")
            throw AuthError.credentialsStorageError(error)
        }
    }

    /// Logs out the user with option to skip web logout (for web-initiated logout)
    /// - Parameter triggerWebLogout: Whether to clear the web session. Defaults to true.
    /// - Throws: `LogoutError.sessionClearingFailed` if both web session and credential clearing fail,
    ///           `LogoutError.credentialsClearingFailed` if only credential clearing fails.
    public func logout(triggerWebLogout: Bool = true) async throws {
        var sessionClearingError: Error?

        // First, try to clear the web session if requested
        if triggerWebLogout {
            do {
                try await auth0Provider.clearSession()
                print("\(#file).\(#function) - 👤 Auth - Web session cleared successfully.")
            } catch {
                sessionClearingError = error
                print("\(#file).\(#function) - 👤 Auth - Failed to clear web session: \(error)")
            }
        }

        // Then, try to clear stored credentials
        let credentialsCleared = auth0Provider.clearCredentials()

        if credentialsCleared {
            setupTokensWithCredentials(nil)
            print("\(#file).\(#function) - 👤 Auth - Credentials cleared successfully.")

            // If we had a session clearing error but credentials cleared successfully,
            // we still consider the logout successful since the user is logged out locally
            if let sessionError = sessionClearingError {
                print("\(#file).\(#function) - 👤 Auth - Logout completed with web session clearing warning: \(sessionError)")
            }
        } else {
            // If credentials clearing failed, throw appropriate error
            if let sessionError = sessionClearingError {
                // Both session and credentials clearing failed
                throw AuthError.sessionClearingFailed(sessionError)
            } else {
                // Only credentials clearing failed
                throw AuthError.credentialsClearingFailed
            }
        }

        // Then, try to clear stored credentials
        let credentialsCleared = auth0Provider.clearCredentials()

        if credentialsCleared {
            setupTokensWithCredentials(nil)
            print("\(#file).\(#function) - 👤 Auth - Credentials cleared successfully.")

            // If we had a session clearing error but credentials cleared successfully,
            // we still consider the logout successful since the user is logged out locally
            if let sessionError = sessionClearingError {
                print("\(#file).\(#function) - 👤 Auth - Logout completed with web session clearing warning: \(sessionError)")
            }
        } else {
            // If credentials clearing failed, throw appropriate error
            if let sessionError = sessionClearingError {
                // Both session and credentials clearing failed
                throw AuthError.sessionClearingFailed(sessionError)
            } else {
                // Only credentials clearing failed
                throw AuthError.credentialsClearingFailed
            }
        }
    }

    /// Retrieves stored credentials asynchronously, if available.
    public func retrieveStoredCredentials() async {
        do {
            let credentials = try await auth0Provider.retrieveCredentials()
            setupTokensWithCredentials(credentials, settingLoggedInStateTo: true)
            print("\(#file).\(#function) - 👤 Auth - Retrieved credentials: \(credentials)")
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Failed to retrieve credentials: \(error)")
        }
    }

    /// Renews credentials if they are renewable.
    public func renewCredentialsIfNeeded() async throws {
        guard auth0Provider.canRenewCredentials() else {
            print("\(#file).\(#function) - 👤 Auth - No renewable credentials available.")
            return
        }

        do {
            let credentials = try await auth0Provider.renewCredentials()
            setupTokensWithCredentials(credentials, settingLoggedInStateTo: true)
            print("\(#file).\(#function) - 👤 Auth - Renewed credentials: \(credentials)")
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Failed to renew credentials: \(error)")
            throw AuthError.credentialsRenewalFailed(error)
        }
    }

    /// Helper method to setup tokens and login flag
    private func setupTokensWithCredentials(_ credentials: Credentials?,
                                            settingLoggedInStateTo isLoggedIn: Bool = false) {
        self.idToken = credentials?.idToken
        self.accessToken = credentials?.accessToken
        self.refreshToken = credentials?.refreshToken
        self.isLoggedIn = isLoggedIn
    }
    
    public func getSessionTransferToken() async {
        guard isLoggedIn else {
            print("\(#file).\(#function) - 👤 Auth - User not logged in")
            return
        }
        ssoCredentials = await retrieveSSOCredentials()
        print("\(#file).\(#function) - 👤 Auth - Retrieved sessionToken \(ssoCredentials?.sessionTransferToken ?? "nil")")
    }

    /// Returns session token cookie if it can be retrieved
    public func getSessionTokenCookie() -> HTTPCookie? {
        guard isLoggedIn else {
            print("\(#file).\(#function) - 👤 Auth - \(isLoggedIn ? "User not logged in" : "Token missing")")
            return nil
        }
        print("[TEST] Auth - Making cookie for \(ssoCredentials?.sessionTransferToken ?? "nil")")
        return makeSessionTokenCookieWithSSOCredentials(ssoCredentials)
    }
}

extension Auth {

    /// Retrieves the session token if the `auth0Provider` is of type `NativeToWebSSOAuth0Provider`.
    /// This method ensures that the session token is only retrieved for the specific provider type.
    /// - Note: This method performs a type check and calls `getSessionToken` on the provider if the type matches.
    private func retrieveSSOCredentials() async -> SSOCredentials? {
        if let authProvider = auth0Provider as? NativeToWebSSOAuth0Provider {
            do {
                return try await authProvider.getSSOCredentials()
            } catch {
                print("\(#file).\(#function) - 👤 Auth - Failed to retrieve SSO Credentials: \(error)")
            }
        }
        return nil
    }

    private func makeSessionTokenCookieWithSSOCredentials(_ ssoCredentials: SSOCredentials?) -> HTTPCookie? {
        guard let ssoCredentials else {
            print("\(#file).\(#function) - 👤 Auth - No SSO credentials available to create cookie")
            return nil
        }
        return HTTPCookie(properties: [
            .domain: auth0Provider.credentialsManager.auth0SettingsProvider.domain,
            .path: "/",
            .name: "auth0_session_transfer_token",
            .value: ssoCredentials.sessionTransferToken,
            .expires: ssoCredentials.expiresIn,
            .secure: true
        ])
    }

    public func setSessionTokenCookieForURL(_ url: URL, webView: WKWebView) {
        guard Auth.shared.isLoggedIn,
              let sessionTokenCookie = getSessionTokenCookie() else {
            print("No session token available or user not logged in")
            return
        }

        print("Setting session token cookie for URL: \(url.absoluteString)")

        // Set the session token cookie
        webView.configuration.websiteDataStore.httpCookieStore.setCookie(sessionTokenCookie)
        print("Session token cookie set successfully")
    }
}
