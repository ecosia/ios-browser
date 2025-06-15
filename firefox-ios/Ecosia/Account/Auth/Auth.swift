// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import WebKit
import Redux
import Common
import UIKit

// MARK: - User Profile Model
public struct UserProfile {
    public let name: String?
    public let email: String?
    public let picture: String?
    public let sub: String?

    public init(name: String?, email: String?, picture: String?, sub: String?) {
        self.name = name
        self.email = email
        self.picture = picture
        self.sub = sub
    }
}

// MARK: - Authentication Action Types for Redux
public enum EcosiaAuthActionType: String, CaseIterable {
    case authStateLoaded
    case userLoggedIn
    case userLoggedOut
}

// MARK: - Auth Notifications
extension Notification.Name {
    /// Posted when user successfully logs in and session token is ready
    public static let EcosiaAuthDidLoginWithSessionToken = Notification.Name("EcosiaEcosiaAuthDidLoginWithSessionToken")

    /// Posted when user logs out and session should be cleared
    public static let EcosiaAuthDidLogout = Notification.Name("EcosiaEcosiaAuthDidLogout")

    /// Posted when user should logout from web
    public static let EcosiaAuthShouldLogoutFromWeb = Notification.Name("EcosiaEcosiaAuthShouldLogoutFromWeb")

    /// Posted when credentials have been retrieved and auth state is ready
    public static let EcosiaAuthStateReady = Notification.Name("EcosiaEcosiaAuthStateReady")

    /// Posted when auth state should be dispatched to Redux store
    public static let EcosiaAuthReduxDispatch = Notification.Name("EcosiaEcosiaAuthReduxDispatch")
}

/// The `Auth` class manages user authentication, credential storage, and renewal using Auth0.
public class Auth {
    public static let shared = Auth()

    public static let defaultCredentialsManager: CredentialsManagerProtocol = DefaultCredentialsManager()
    public let auth0Provider: Auth0ProviderProtocol

    private(set) var idToken: String?
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var ssoCredentials: SSOCredentials?
    public var currentSessionToken: String? { ssoCredentials?.sessionTransferToken }

    /// The current user's profile information extracted from the ID token
    public private(set) var userProfile: UserProfile?

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
                // Set credential properties FIRST
                self.idToken = credentials.idToken
                self.accessToken = credentials.accessToken
                self.refreshToken = credentials.refreshToken
                isLoggedIn = true
                print("\(#file).\(#function) - 👤 Auth - Credentials stored successfully.")

                // Now extract user profile (self.accessToken is available)
                self.extractUserProfile(from: credentials.idToken)

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

            // Dispatch login state to Redux store
            dispatchAuthStateToRedux(isLoggedIn: true, actionType: .userLoggedIn)
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

            let didClear = auth0Provider.clearCredentials()
            if didClear {
                self.idToken = nil
                self.accessToken = nil
                self.refreshToken = nil
                self.ssoCredentials = nil
                self.userProfile = nil // Clear user profile
                isLoggedIn = false
                print("\(#file).\(#function) - 👤 Auth - Session and credentials cleared.")

                // Post logout notification to trigger web logout if needed
                if triggerWebLogout {
                    await postWebLogoutNotification()
                }
                // Notify that logout occurred
                await postLogoutNotification()
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Logout failed with error: \(error)")
        }
    }

    /// Posts logout notification to trigger web logout
    private func postWebLogoutNotification() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .EcosiaAuthShouldLogoutFromWeb, object: nil)
        }
    }

    /// Posts logout notification and triggers web logout
    @MainActor
    private func postLogoutNotification() {
        NotificationCenter.default.post(name: .EcosiaAuthDidLogout, object: nil)

        // Dispatch logout state to Redux store
        dispatchAuthStateToRedux(isLoggedIn: false, actionType: .userLoggedOut)
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

            // Now extract user profile (self.accessToken is available)
            self.extractUserProfile(from: credentials.idToken)

            // Post notification that auth state is ready
            await postAuthStateReadyNotification()
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

            // Now extract user profile from renewed ID token (self.accessToken is available)
            self.extractUserProfile(from: credentials.idToken)
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

    /// Posts auth state ready notification
    private func postAuthStateReadyNotification() async {
        await MainActor.run {
            print("\(#file).\(#function) - 👤 Auth - Posting auth state ready notification")
            NotificationCenter.default.post(name: .EcosiaAuthStateReady, object: nil)

            // If user is logged in, also post login notification for UI consistency
            if isLoggedIn {
                NotificationCenter.default.post(
                    name: .EcosiaAuthDidLoginWithSessionToken,
                    object: nil,
                    userInfo: ["sessionToken": currentSessionToken as Any]
                )
            }

            // Dispatch authentication state to Redux store
            dispatchAuthStateToRedux(isLoggedIn: isLoggedIn, actionType: .authStateLoaded)
        }
    }

    /// Dispatches authentication state changes to Redux store via notification
    private func dispatchAuthStateToRedux(isLoggedIn: Bool, actionType: EcosiaAuthActionType) {
        // Post notification with auth state info for the bridge to handle
        let userInfo: [String: Any] = [
            "isLoggedIn": isLoggedIn,
            "actionType": actionType.rawValue
        ]
        NotificationCenter.default.post(name: .EcosiaAuthReduxDispatch, object: nil, userInfo: userInfo)
        print("🔄 Auth - Posted Redux dispatch notification for \(actionType)")
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

    /// Extracts user profile from ID token and optionally fetches additional info from Auth0
    private func extractUserProfile(from idToken: String) {
        // For now, create a basic profile with minimal info
        // TODO: Implement proper JWT decoding when JWT library is available
        self.userProfile = UserProfile(name: "User", email: nil, picture: nil, sub: nil)
        print("\(#file).\(#function) - 👤 Auth - Created basic user profile")

        // Try to fetch additional user info from Auth0 if we have an access token
        if let accessToken = self.accessToken {
            Task {
                await fetchUserInfoFromAuth0(accessToken: accessToken)
            }
        }
    }

    /// Fetches detailed user information from Auth0's userInfo endpoint
    private func fetchUserInfoFromAuth0(accessToken: String) async {
        do {
            let userInfo = try await Auth0
                .authentication(clientId: auth0Provider.credentialsManager.auth0SettingsProvider.id,
                               domain: auth0Provider.credentialsManager.auth0SettingsProvider.domain)
                .userInfo(withAccessToken: accessToken)
                .start()

            // Update user profile with actual data from Auth0
            self.userProfile = UserProfile(
                name: userInfo.name ?? userInfo.nickname,
                email: userInfo.email,
                picture: userInfo.picture?.absoluteString,
                sub: userInfo.sub
            )
            print("\(#file).\(#function) - 👤 Auth - Updated user profile with Auth0 data: name=\(userInfo.name ?? "nil"), email=\(userInfo.email ?? "nil"), picture=\(userInfo.picture?.absoluteString ?? "nil")")

            // Notify UI that profile was updated
            await MainActor.run {
                NotificationCenter.default.post(name: .EcosiaAuthStateReady, object: nil)
            }
        } catch {
            print("\(#file).\(#function) - 👤 Auth - Failed to fetch user info from Auth0: \(error)")
        }
    }
}
