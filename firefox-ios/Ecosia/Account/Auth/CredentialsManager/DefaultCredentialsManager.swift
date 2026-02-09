// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

struct DefaultCredentialsManager: CredentialsManagerProtocol {

    private let credentialManager: CredentialsManager

    init(auth0SettingsProvider: Auth0SettingsProviderProtocol = DefaultAuth0SettingsProvider()) {
        self.credentialManager = CredentialsManager(authentication: Auth0.authentication(clientId: auth0SettingsProvider.id,
                                                                                         domain: auth0SettingsProvider.domain))
        EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Credentials manager initialized")
    }

    func store(credentials: Auth0.Credentials) -> Bool {
        EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Storing credentials in keychain")
        let result = credentialManager.store(credentials: credentials)
        if result {
            EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Credentials stored successfully")
        } else {
            EcosiaLogger.auth.error("🔐 [CREDENTIALS-MGR] Failed to store credentials")
        }
        return result
    }

    func credentials() async throws -> Auth0.Credentials {
        EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Retrieving credentials from keychain")
        do {
            let credentials = try await credentialManager.credentials()
            EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Credentials retrieved successfully")
            EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR]   - Has refresh token: \(credentials.refreshToken != nil)")
            return credentials
        } catch {
            EcosiaLogger.auth.error("🔐 [CREDENTIALS-MGR] Failed to retrieve credentials: \(error)")
            throw error
        }
    }

    func clear() -> Bool {
        EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Clearing credentials from keychain")
        let result = credentialManager.clear()
        if result {
            EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Credentials cleared successfully")
        } else {
            EcosiaLogger.auth.notice("🔐 [CREDENTIALS-MGR] No credentials found to clear")
        }
        return result
    }

    func canRenew() -> Bool {
        let result = credentialManager.canRenew()
        EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Can renew credentials: \(result)")
        return result
    }

    func renew() async throws -> Auth0.Credentials {
        EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Renewing credentials using refresh token")
        do {
            let credentials = try await credentialManager.renew()
            EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR] Credentials renewed successfully")
            EcosiaLogger.auth.info("🔐 [CREDENTIALS-MGR]   - New access token expires in: \(credentials.expiresIn) seconds")
            return credentials
        } catch {
            EcosiaLogger.auth.error("🔐 [CREDENTIALS-MGR] Failed to renew credentials: \(error)")
            throw error
        }
    }
}
