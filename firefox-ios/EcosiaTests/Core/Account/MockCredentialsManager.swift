// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0
@testable import Ecosia

/// A mock implementation of `CredentialsManaging` for unit testing.
final class MockCredentialsManager: CredentialsManaging {

    /// The stored credentials, if any.
    private var storedCredentials: Credentials?

    /// Determines if operations should fail for testing error scenarios.
    var shouldFail = false

    @discardableResult
    func store(credentials: Credentials) -> Bool {
        if shouldFail { return false }
        storedCredentials = credentials
        return true
    }

    func credentials() async throws -> Credentials {
        if let credentials = storedCredentials {
            return credentials
        } else {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }

    @discardableResult
    func clear() -> Bool {
        storedCredentials = nil
        return true
    }

    func canRenew() -> Bool {
        return storedCredentials?.refreshToken != nil
    }

    func renew() async throws -> Credentials {
        if let credentials = storedCredentials, credentials.refreshToken != nil {
            return credentials
        } else {
            throw NSError(domain: "MockError", code: 2, userInfo: nil)
        }
    }
}
