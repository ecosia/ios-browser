// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// Default implementation of `Auth0ProviderProtocol` using Auth0's SDK.
public struct DefaultAuth0Provider: Auth0ProviderProtocol {

    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication(bundle: .ecosia),
                                                        storage: EcosiaKeychainStorage())

    public init() {}

    /// Starts the authentication process asynchronously and returns credentials.
    ///
    /// - Returns: A `Credentials` object upon successful authentication.
    /// - Throws: An error if the authentication fails.
    public func startAuth() async throws -> Credentials {
        return try await httpsWebAuth()
            .start()
    }

    /// Clears the current authentication session asynchronously.
    ///
    /// - Throws: An error if the session clearing fails.
    public func clearSession() async throws {
        try await httpsWebAuth()
            .clearSession()
    }

    /// Stores the provided credentials securely.
    ///
    /// - Parameter credentials: The credentials to store.
    /// - Returns: A boolean indicating whether the credentials were successfully stored.
    public func storeCredentials(_ credentials: Credentials) throws -> Bool {
        return credentialsManager.store(credentials: credentials)
    }

    /// Retrieves stored credentials asynchronously.
    ///
    /// - Returns: The stored `Credentials` object if available.
    /// - Throws: An error if retrieving credentials fails.
    public func retrieveCredentials() async throws -> Credentials {
        return try await credentialsManager.credentials()
    }

    /// Clears stored credentials.
    ///
    /// - Returns: A boolean indicating whether the credentials were successfully cleared.
    public func clearCredentials() -> Bool {
        return credentialsManager.clear()
    }

    /// Checks if stored credentials can be renewed.
    ///
    /// - Returns: A boolean indicating if credentials are renewable.
    public func canRenewCredentials() -> Bool {
        return credentialsManager.canRenew()
    }

    /// Renews credentials asynchronously if possible.
    ///
    /// - Returns: A `Credentials` object upon successful renewal.
    /// - Throws: An error if the credential renewal fails.
    public func renewCredentials() async throws -> Credentials {
        return try await credentialsManager.renew()
    }
}

extension DefaultAuth0Provider {

    /// Helper function
    /// - Returns: An HTTPS `WebAuth`
    private func httpsWebAuth() -> WebAuth {
        Auth0
            .webAuth(bundle: .ecosia)
            .useHTTPS()
    }
}
