// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0
@testable import Ecosia

/// Mock implementation of `Auth0ProviderProtocol` for testing purposes.
final class MockAuth0Provider: Auth0ProviderProtocol {
    var shouldSucceed = true
    var credentialsStored = false
    var credentialsCleared = false
    var canRenew = false
    let mockCredentialsManager = MockCredentialsManager()
    var credentialsManager: CredentialsManaging { mockCredentialsManager }

    func startAuth() async throws -> Credentials {
        if shouldSucceed {
            return Credentials(
                accessToken: "mockAccessToken",
                tokenType: "Bearer",
                idToken: "mockIdToken",
                refreshToken: "mockRefreshToken",
                expiresIn: Date(),
                scope: "openid profile email"
            )
        } else {
            throw NSError(domain: "MockAuthError", code: 1, userInfo: nil)
        }
    }

    @discardableResult
    func storeCredentials(_ credentials: Credentials) throws -> Bool {
        if shouldSucceed {
            credentialsManager.store(credentials: credentials)
            credentialsStored = true
            return true
        } else {
            throw NSError(domain: "MockAuthError", code: 3, userInfo: nil)
        }
    }

    func clearSession() async throws {
        if !shouldSucceed {
            throw NSError(domain: "MockAuthError", code: 2, userInfo: nil)
        }
    }

    func retrieveCredentials() async throws -> Credentials {
        if shouldSucceed {
            return try await credentialsManager.credentials()
        } else {
            throw NSError(domain: "MockAuthError", code: 2, userInfo: nil)
        }
    }

    @discardableResult
    func clearCredentials() -> Bool {
        credentialsCleared = true
        return true
    }

    func canRenewCredentials() -> Bool {
        return canRenew
    }

    @discardableResult
    func renewCredentials() async throws -> Credentials {
        if shouldSucceed {
            return Credentials(accessToken: "mockAccessToken",
                               tokenType: "Bearer",
                               idToken: "mockIdToken",
                               refreshToken: "mockRefreshToken",
                               expiresIn: Date(),
                               scope: "openid profile email")
        } else {
            throw NSError(domain: "MockAuthError", code: 5, userInfo: nil)
        }
    }
}
