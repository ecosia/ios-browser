// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import WebKit

/// The `Auth` class manages user authentication, credential storage, and renewal using Auth0.
public class Auth {
    public let auth0Provider: Auth0ProviderProtocol

    private(set) var idToken: String?
    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    /// Indicates whether the user is currently logged in.
    public private(set) var isLoggedIn: Bool = false

    /// Initializes a new instance of the `Auth` class with a specified authentication provider.
    ///
    /// - Parameter auth0Provider: An object conforming to `Auth0ProviderProtocol`.
    public init(auth0Provider: Auth0ProviderProtocol = DefaultAuth0Provider()) {
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
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Login failed with error: \(error)")
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
                isLoggedIn = false
                print("\(#file).\(#function) - 👤 Auth - Session and credentials cleared.")
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Logout failed with error: \(error)")
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

    /// Clears the auth cookie in WKWebView.
    private func clearAuthCookieInWebView() {
        // Implement the logic to clear the auth cookie in your WKWebView instances
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: [WKWebsiteDataTypeCookies]) { records in
            let authCookieRecords = records.filter { $0.displayName.contains(Environment.current.urlProvider.root.baseURL!.absoluteString) }
            dataStore.removeData(ofTypes: [WKWebsiteDataTypeCookies], for: authCookieRecords) {
                print("Auth cookie cleared in WKWebView.")
            }
        }
    }
}
