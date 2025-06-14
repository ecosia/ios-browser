// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import WebKit

// MARK: - Auth Notifications
extension Notification.Name {
    /// Posted when user successfully logs in and session token is ready
    public static let EcosiaAuthDidLoginWithSessionToken = Notification.Name("EcosiaEcosiaAuthDidLoginWithSessionToken")

    /// Posted when user logs out and session should be cleared
    public static let EcosiaAuthDidLogout = Notification.Name("EcosiaEcosiaAuthDidLogout")
}

/// The `Auth` class manages user authentication, credential storage, and renewal using Auth0.
public class Auth {
    public static var shared = Auth()

    public static let defaultCredentialsManager: CredentialsManagerProtocol = DefaultCredentialsManager()
    public let auth0Provider: Auth0ProviderProtocol

    private(set) var idToken: String?
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var ssoCredentials: SSOCredentials?
    public var currentSessionToken: String? { ssoCredentials?.sessionTransferToken }

    /// Indicates whether the user is currently logged in.
    public private(set) var isLoggedIn: Bool = false

    /// Initializes a new instance of the `Auth` class with a specified authentication provider.
    ///
    /// - Parameter auth0Provider: An object conforming to `Auth0ProviderProtocol`.
    public init(auth0Provider: Auth0ProviderProtocol = NativeToWebSSOAuth0Provider()) {
        self.auth0Provider = auth0Provider
        Task {
            await self.retrieveStoredCredentials()
        }
    }

    /// Logs in the user asynchronously and stores credentials if successful.
    public func login() async {
        do {
            let credentials = try await auth0Provider.startAuth()
            let didStore = try auth0Provider.storeCredentials(credentials)
            if didStore {
                isLoggedIn = true
                print("\(#file).\(#function) - 👤 Auth - Credentials stored successfully.")

                // Automatically get session token and trigger authentication flow
                await performPostLoginAuthentication()
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Login failed with error: \(error)")
        }
    }

    /// Handles post-login authentication flow: gets session token and notifies observers
    private func performPostLoginAuthentication() async {
        await getSessionTransferToken()

        // Post notification that successful login occurred with session token ready
        await MainActor.run {
            NotificationCenter.default.post(
                name: .EcosiaAuthDidLoginWithSessionToken,
                object: nil,
                userInfo: ["sessionToken": currentSessionToken as Any]
            )
        }
    }

    /// Logs out the user asynchronously and clears stored credentials.
    public func logout() async {
        do {
            try await auth0Provider.clearSession()
            let didClear = auth0Provider.clearCredentials()
            if didClear {
                self.idToken = nil
                self.accessToken = nil
                self.refreshToken = nil
                self.ssoCredentials = nil
                isLoggedIn = false
                print("\(#file).\(#function) - 👤 Auth - Session and credentials cleared.")

                // Notify that logout occurred
                await postLogoutNotification()
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Logout failed with error: \(error)")
        }
    }

    /// Posts logout notification to notify observers that user logged out
    private func postLogoutNotification() async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .EcosiaAuthDidLogout,
                object: nil
            )
        }
    }

    /// Retrieves stored credentials asynchronously, if available.
    public func retrieveStoredCredentials() async {
        do {
            let credentials = try await auth0Provider.retrieveCredentials()
            self.idToken = credentials.idToken
            self.accessToken = credentials.accessToken
            self.refreshToken = credentials.refreshToken
            print("\(#file).\(#function) - 👤 Auth - Retrieved credentials: \(credentials)")
            isLoggedIn = true
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Failed to retrieve credentials: \(error)")
        }
    }

    /// Renews credentials if they are renewable.
    public func renewCredentialsIfNeeded() async {
        guard auth0Provider.canRenewCredentials() else {
            print("\(#file).\(#function) - 👤 Auth - No renewable credentials available.")
            return
        }

        do {
            let credentials = try await auth0Provider.renewCredentials()
            self.idToken = credentials.idToken
            self.accessToken = credentials.accessToken
            self.refreshToken = credentials.refreshToken
            print("\(#file).\(#function) - 👤 Auth - Renewed credentials: \(credentials)")
            isLoggedIn = true
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Failed to renew credentials: \(error)")
        }
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
        return makeSessionTokenCookie(ssoCredentials: ssoCredentials)
    }

    // TODO: We'll need this in the future for syncs with web, not used now
//    /// Clears the auth cookie in WKWebView.
//    private func clearAuthCookieInWebView() {
//        // Implement the logic to clear the auth cookie in your WKWebView instances
//        let dataStore = WKWebsiteDataStore.default()
//        dataStore.fetchDataRecords(ofTypes: [WKWebsiteDataTypeCookies]) { records in
//            let authCookieRecords = records.filter { $0.displayName.contains(Environment.current.urlProvider.root.baseURL!.absoluteString) }
//            dataStore.removeData(ofTypes: [WKWebsiteDataTypeCookies], for: authCookieRecords) {
//                print("Auth cookie cleared in WKWebView.")
//            }
//        }
//    }
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

    private func makeSessionTokenCookie(_ urlProvider: URLProvider = Environment.current.urlProvider, ssoCredentials: SSOCredentials?) -> HTTPCookie? {
        guard let ssoCredentials else {
            print("\(#file).\(#function) - 👤 Auth - No SSO credentials available to create cookie")
            return nil
        }
        return HTTPCookie(properties: [
            .domain: "login.ecosia-staging.xyz",
            .path: "/",
            .name: "auth0_session_transfer_token",
            .value: ssoCredentials.sessionTransferToken,
            .expires: ssoCredentials.expiresIn,
            .secure: true
        ])
    }
}
