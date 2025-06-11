// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// Protocol defining authentication operations for Auth0.
public protocol Auth0ProviderProtocol {
    /// Starts the authentication process asynchronously and returns credentials.
    ///
    /// - Returns: A `Credentials` object upon successful authentication.
    /// - Throws: An error if the authentication fails.
    func startAuth() async throws -> Credentials

    /// Clears the current authentication session asynchronously.
    ///
    /// - Throws: An error if the session clearing fails.
    func clearSession() async throws

    /// Stores the provided credentials securely.
    ///
    /// - Parameter credentials: The credentials to store.
    /// - Returns: A boolean indicating whether the credentials were successfully stored.
    /// - Throws: An error if storing credentials fails.
    func storeCredentials(_ credentials: Credentials) throws -> Bool

    /// Retrieves stored credentials asynchronously.
    ///
    /// - Returns: The stored `Credentials` object if available.
    /// - Throws: An error if retrieving credentials fails.
    func retrieveCredentials() async throws -> Credentials

    /// Clears stored credentials.
    ///
    /// - Returns: A boolean indicating whether the credentials were successfully cleared.
    func clearCredentials() -> Bool

    /// Checks if stored credentials can be renewed.
    ///
    /// - Returns: A boolean indicating if credentials are renewable.
    func canRenewCredentials() -> Bool

    /// Renews credentials asynchronously if possible.
    ///
    /// - Returns: A `Credentials` object upon successful renewal.
    /// - Throws: An error if the credential renewal fails.
    func renewCredentials() async throws -> Credentials
}
