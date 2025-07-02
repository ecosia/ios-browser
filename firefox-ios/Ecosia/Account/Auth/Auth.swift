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
    public func login() async {
        do {
            // The onClose callback is now built into the webAuth property
            let credentials = try await auth0Provider.startAuth()

            let didStore = try auth0Provider.storeCredentials(credentials)
            if didStore {
                // Set credential properties FIRST
                self.idToken = credentials.idToken
                self.accessToken = credentials.accessToken
                self.refreshToken = credentials.refreshToken
                isLoggedIn = true
                print("\(#file).\(#function) - 👤 Auth - Credentials stored successfully.")
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Login failed with error: \(error)")
        }
    }

    /// Logs out the user by clearing stored credentials and session.
    public func logout() async {
        await logout(triggerWebLogout: true)
    }

    /// Logs out the user with option to skip web logout (for web-initiated logout)
    public func logout(triggerWebLogout: Bool = true) async {
        do {
            // Only clear Auth0 session if this is not web-initiated logout
            if triggerWebLogout {
                try await auth0Provider.clearSession()
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Logout failed with error: \(error)")
        }

        // Try to clear credentials - if this succeeds, we log out regardless of session clearing
        let credentialsCleared = auth0Provider.clearCredentials()

        if credentialsCleared {
            self.idToken = nil
            self.accessToken = nil
            self.refreshToken = nil
            isLoggedIn = false
            print("\(#file).\(#function) - 👤 Auth - Session and credentials cleared.")
        } else {
            // If we couldn't clear credentials, keep the user logged in
            print("\(#file).\(#function) - 👤 Auth - Failed to clear credentials, maintaining logged in state.")
        }
    }

    /// Retrieves stored credentials asynchronously, if available.
    public func retrieveStoredCredentials() async {
        do {
            let credentials = try await auth0Provider.retrieveCredentials()
            // Set credential properties FIRST
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
            // Set credential properties FIRST
            self.idToken = credentials.idToken
            self.accessToken = credentials.accessToken
            self.refreshToken = credentials.refreshToken
            print("\(#file).\(#function) - 👤 Auth - Renewed credentials: \(credentials)")

            isLoggedIn = true
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Failed to renew credentials: \(error)")
        }
    }
}
