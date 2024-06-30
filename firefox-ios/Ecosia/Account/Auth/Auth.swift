// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import WebKit
import Redux
import Common
import UIKit
import SwiftUI

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

    /// Posted when the entire authentication flow is complete (including invisible tab workflow)
    public static let EcosiaAuthFlowCompleted = Notification.Name("EcosiaEcosiaAuthFlowCompleted")
}

/// The `Auth` class manages user authentication, credential storage, and renewal using Auth0.
public class Auth {
    public static let shared = Auth()
    
    public static let defaultCredentialsManager: CredentialsManagerProtocol = DefaultCredentialsManager()
    public let auth0Provider: Auth0ProviderProtocol
    
    private(set) var idToken: String?
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    
    /// The current user's profile information extracted from the ID token
    public private(set) var userProfile: UserProfile?
    
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
            
            let didClear = auth0Provider.clearCredentials()
            if didClear {
                self.idToken = nil
                self.accessToken = nil
                self.refreshToken = nil
                self.userProfile = nil // Clear user profile
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
