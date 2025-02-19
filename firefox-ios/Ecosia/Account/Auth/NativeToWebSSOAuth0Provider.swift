// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// Native to Web SSO implementation of `Auth0ProviderProtocol` using Auth0's SDK.
public struct NativeToWebSSOAuth0Provider: Auth0ProviderProtocol {

    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication(bundle: .ecosia),
                                                        storage: EcosiaKeychainStorage())
    
    typealias SessionToken = String
    
    enum NativeToWebSSOError: Error {
        case invalidResponse
        case missingRefreshToken(String)
        case missingConfiguration(String)
        case couldNotRetrieveToken
    }

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

extension NativeToWebSSOAuth0Provider {
    
    /// Requests the `session_token` with the `refresh_token`
    ///
    /// - Returns: A `session_token` as `SessionToken` as a `String` type
    /// - Throws: An error if the retrieval fails.
    public func getSessionToken() async throws -> String {
        
        let credentials = try await withCheckedThrowingContinuation { continuation in
            credentialsManager.credentials { result in
                switch result {
                case .success(let credentials):
                    continuation.resume(returning: credentials)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        guard let refreshToken = credentials.refreshToken else {
            throw NativeToWebSSOError.missingRefreshToken("Refresh token is missing. Please check your credentials.")
        }
        
        guard let values = configurationValues() else {
            throw NativeToWebSSOError.missingConfiguration("Missing Auth0.plist file")
        }
        
        let tokenExchanceUrl = URL(string: "https://\(values.domain)/oauth/token")!
        
        let jsonBody: [String: Any] = [
            "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
            "subject_token": refreshToken,
            "subject_token_type": "urn:ietf:params:oauth:token-type:refresh_token",
            "requested_token_type": "urn:auth0:params:oauth:token-type:session_token",
            "client_id": values.clientId
        ]
        
        var request = URLRequest(url: tokenExchanceUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody, options: [])
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NativeToWebSSOError.invalidResponse
        }
        
        if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let sessionToken = jsonResponse["access_token"] as? String {
            return sessionToken
        } else {
            throw NativeToWebSSOError.couldNotRetrieveToken
        }
    }
    
    func configurationValues(bundle: Bundle = .ecosia) -> (clientId: String, domain: String)? {
        guard let path = bundle.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path) as? [String: Any] else {
                print("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
                return nil
            }

        guard let clientId = values["ClientId"] as? String, let domain = values["Domain"] as? String else {
                print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
                print("File currently has the following entries: \(values)")
                return nil
            }
        return (clientId: clientId, domain: domain)
    }
}

extension NativeToWebSSOAuth0Provider {

    /// Helper function
    /// - Returns: An HTTPS `WebAuth`
    private func httpsWebAuth() -> WebAuth {
        Auth0
            .webAuth(bundle: .ecosia)
            .useHTTPS()
    }
}
