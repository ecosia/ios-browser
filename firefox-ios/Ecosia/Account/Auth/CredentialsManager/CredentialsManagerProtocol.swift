// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// A protocol for managing authentication credentials.
public protocol CredentialsManagerProtocol {

    /// Stores the provided credentials securely.
    ///
    /// - Parameter credentials: The credentials to store.
    /// - Returns: A boolean indicating whether the credentials were successfully stored.
    @discardableResult
    func store(credentials: Credentials) -> Bool

    /// Retrieves stored credentials asynchronously.
    ///
    /// - Returns: The stored `Credentials` object if available.
    /// - Throws: An error if retrieving credentials fails.
    func credentials() async throws -> Credentials

    /// Clears stored credentials.
    ///
    /// - Returns: A boolean indicating whether the credentials were successfully cleared.
    @discardableResult
    func clear() -> Bool

    /// Checks if stored credentials can be renewed.
    ///
    /// - Returns: A boolean indicating if credentials are renewable.
    func canRenew() -> Bool

    /// Renews credentials asynchronously if possible.
    ///
    /// - Returns: A `Credentials` object upon successful renewal.
    /// - Throws: An error if the credential renewal fails.
    func renew() async throws -> Credentials

    /// Exchanges the stored refresh token for SSO credentials asynchronously, to perform Native to Web SSO.
    ///
    /// With refresh token rotation enabled, the exchange also returns a new refresh token, which is
    /// persisted in place of the spent one.
    ///
    /// - Returns: An `SSOCredentials` object containing the session transfer token.
    /// - Throws: An error if there are no stored credentials or refresh token, or if the exchange fails.
    func ssoCredentials() async throws -> SSOCredentials
}
