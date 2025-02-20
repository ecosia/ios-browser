// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// A wrapper class for `CredentialsManager` conforming to `CredentialsManaging`.
///
/// This class allows `CredentialsManager` to be injected as a dependency
/// and enables testing by replacing it with a mock implementation.
final class CredentialsManagerWrapper: CredentialsManaging {

    /// The underlying `CredentialsManager` instance.
    private let manager: CredentialsManager

    /// Initializes the wrapper with a given `CredentialsManager`.
    ///
    /// - Parameter manager: The `CredentialsManager` to wrap.
    init(manager: CredentialsManager) {
        self.manager = manager
    }

    func store(credentials: Credentials) -> Bool {
        return manager.store(credentials: credentials)
    }

    func credentials() async throws -> Credentials {
        return try await manager.credentials()
    }

    func clear() -> Bool {
        return manager.clear()
    }

    func canRenew() -> Bool {
        return manager.canRenew()
    }

    func renew() async throws -> Credentials {
        return try await manager.renew()
    }
}
