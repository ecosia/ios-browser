// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// Native to Web SSO implementation of `Auth0ProviderProtocol` using Auth0's SDK and performing Native to Web SSO via REST API to perform the session token exchange.
public struct NativeToWebSSOAuth0Provider: Auth0ProviderProtocol {

    public let credentialsManager: CredentialsManagerProtocol
    private var client: HTTPClient
    public typealias SessionToken = String

    enum NativeToWebSSOError: Error, Equatable {
        case invalidResponse
        case missingRefreshToken(String)
        case missingConfiguration(String)
    }

    public init(client: HTTPClient = URLSessionHTTPClient(),
                credentialsManager: CredentialsManagerProtocol = Auth.defaultCredentialsManager) {
        self.client = client
        self.credentialsManager = credentialsManager
    }

    public var webAuth: WebAuth {
        makeHttpsWebAuth()
            .scope("openid profile email offline_access")
    }

    /// The `startAuth` method configured to explicity request the `offline_access` scope in order to obtain a `refresh_token`.
    public func startAuth() async throws -> Credentials {
        return try await webAuth.start()
    }
}

extension NativeToWebSSOAuth0Provider {

    /// Requests the `session_token` with the `refresh_token`.
    ///
    /// - Returns: A `session_token` as `SessionToken` (a `String` type).
    /// - Throws: An error if the retrieval fails.
    public func getSSOCredentials() async throws -> SSOCredentials {
        let credentials = try await retrieveCredentials()
        guard let refreshToken = credentials.refreshToken else {
            throw NativeToWebSSOError.missingRefreshToken("Refresh token is missing. Please check your credentials.")
        }
//
//        let request = Auth0SessionTokenRequest(domain: credentialsManager.auth0SettingsProvider.domain,
//                                               refreshToken: refreshToken,
//                                               clientId: credentialsManager.auth0SettingsProvider.id)
//        let (data, response) = try await client.perform(request)
//
//        guard let httpResponse = response, httpResponse.statusCode == 200 else {
//            throw NativeToWebSSOError.invalidResponse
//        }
//
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        let tokenResponse = try decoder.decode(Auth0SessionTokenResponse.self, from: data)
//        return tokenResponse.accessToken
        let configuration: URLSessionConfiguration = .default
        let ecosiaAuth0Session = URLSession(configuration: configuration.withCloudFlareAuthParameters())
        return try await Auth0
            .authentication(clientId: credentialsManager.auth0SettingsProvider.id,
                            domain: credentialsManager.auth0SettingsProvider.domain,
                            session: ecosiaAuth0Session)
            .ssoExchange(withRefreshToken: refreshToken)
            .start()
    }

    /// Retrieves configuration values from the Auth0.plist file.
    ///
    /// - Parameter bundle: The bundle containing the Auth0.plist file. Defaults to `.ecosia`.
    /// - Returns: A tuple containing the `clientId` and `domain` if available, otherwise `nil`.
    func configurationValues(bundle: Bundle = .ecosia) -> (clientId: String, domain: String)? {
        guard let path = bundle.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
        }

        guard let clientId = values["ClientId"] as? String, let domain = values["Domain"] as? String else {
            print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            return nil
        }
        return (clientId: clientId, domain: domain)
    }
}
