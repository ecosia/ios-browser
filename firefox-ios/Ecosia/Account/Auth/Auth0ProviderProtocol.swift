// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0

/// Protocol defining authentication operations for Auth0.
public protocol Auth0ProviderProtocol {

    /// The Auth0 configuration settings provider
    var settings: Auth0SettingsProviderProtocol { get }

    /// API audience used at login, when access tokens are audience-scoped.
    var authApiAudience: String? { get }

    /// The `CredentialsManager` final concrete type conforming to the protocol `CredentialsManaging` to use for storing and retrieving credentials.
    var credentialsManager: CredentialsManagerProtocol { get }

    /// The `WebAuth` instance to use for authentication
    var webAuth: WebAuth { get }

    /// Starts the authentication process asynchronously and returns credentials.
    ///
    /// - Parameter screenHint: The Auth0 Universal Login screen to present.
    /// - Returns: A `Credentials` object upon successful authentication.
    /// - Throws: An error if the authentication fails.
    func startAuth(screenHint: AuthScreenHint) async throws -> Credentials

    /// Clears the current authentication session asynchronously.
    ///
    /// - Throws: An error if the session clearing fails.
    func clearSession() async throws

    /// Stores the provided credentials securely.
    ///
    /// - Parameter credentials: The credentials to store.
    /// - Returns: A boolean indicating whether the credentials were successfully stored.
    /// - Throws: An error if storing credentials fails.
    @discardableResult
    func storeCredentials(_ credentials: Credentials) throws -> Bool

    /// Retrieves stored credentials asynchronously.
    ///
    /// - Returns: The stored `Credentials` object if available.
    /// - Throws: An error if retrieving credentials fails.
    func retrieveCredentials() async throws -> Credentials

    /// Clears stored credentials.
    ///
    /// - Returns: A boolean indicating whether the credentials were successfully cleared.
    @discardableResult
    func clearCredentials() -> Bool

    /// Checks if stored credentials can be renewed.
    ///
    /// - Returns: A boolean indicating if credentials are renewable.
    func canRenewCredentials() -> Bool

    /// Renews credentials asynchronously if possible.
    ///
    /// - Returns: A `Credentials` object upon successful renewal.
    /// - Throws: An error if the credential renewal fails.
    @discardableResult
    func renewCredentials() async throws -> Credentials

    /// Silently exchanges the refresh token for credentials that include the requested scopes.
    ///
    /// Uses `CredentialsManager` against `/oauth/token`. The manager persists renewed credentials automatically.
    @discardableResult
    func renewCredentials(withScope scope: String) async throws -> Credentials

    /// Interactive Web Auth to approve additional API scopes without signing out first.
    @discardableResult
    func startAuthForAdditionalScopes() async throws -> Credentials
}

extension Auth0ProviderProtocol {

    /// - Returns: An HTTPS `WebAuth`
    func makeHttpsWebAuth() -> WebAuth {
        let configuration: URLSessionConfiguration = .default
        let ecosiaAuth0Session = URLSession(configuration: configuration.withCloudFlareAuthParameters())
        return Auth0
            .webAuth(clientId: settings.id,
                     domain: settings.domain,
                     session: ecosiaAuth0Session)
            .useHTTPS()
    }
}

/// Default Protocol Implementation
extension Auth0ProviderProtocol {

    public var settings: Auth0SettingsProviderProtocol { DefaultAuth0SettingsProvider() }

    public var authApiAudience: String? { nil }

    public var credentialsManager: CredentialsManagerProtocol { EcosiaAuthenticationService.defaultCredentialsManager }

    public func startAuth(screenHint: AuthScreenHint) async throws -> Credentials {
        return try await webAuth.start()
    }

    public func startAuth() async throws -> Credentials {
        try await startAuth(screenHint: .login)
    }

    public func clearSession() async throws {
        try await webAuth.clearSession()
    }

    public func storeCredentials(_ credentials: Credentials) throws -> Bool {
        return credentialsManager.store(credentials: credentials)
    }

    public func retrieveCredentials() async throws -> Credentials {
        return try await credentialsManager.credentials()
    }

    public func clearCredentials() -> Bool {
        return credentialsManager.clear()
    }

    public func canRenewCredentials() -> Bool {
        return credentialsManager.canRenew()
    }

    public func renewCredentials() async throws -> Credentials {
        return try await credentialsManager.renew()
    }

    public func renewCredentials(withScope scope: String) async throws -> Credentials {
        if let audience = authApiAudience {
            let apiCredentials = try await credentialsManager.apiCredentials(forAudience: audience, scope: scope)
            let baseCredentials = try await credentialsManager.credentials()
            return Credentials(accessToken: apiCredentials.accessToken,
                               tokenType: apiCredentials.tokenType,
                               idToken: baseCredentials.idToken,
                               refreshToken: baseCredentials.refreshToken,
                               expiresIn: apiCredentials.expiresIn,
                               scope: apiCredentials.scope)
        }
        return try await credentialsManager.credentials(withScope: scope)
    }

    public func startAuthForAdditionalScopes() async throws -> Credentials {
        try await startAuth(screenHint: .login)
    }
}
