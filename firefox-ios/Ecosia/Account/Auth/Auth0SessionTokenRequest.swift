// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Struct for encoding the JSON request body
struct TokenRequest: Codable {
    let grantType: String
    let subjectToken: String
    let subjectTokenType: String
    let requestedTokenType: String
    let clientId: String
}

/// Struct for decoding the JSON response
struct TokenResponse: Codable {
    let accessToken: String
}

struct Auth0SessionTokenRequest: BaseRequest {

    private var domain: String

    let method: HTTPMethod = .post

    var baseURL: URL { URL(string: "https://\(domain)")! }

    var path: String { "/oauth/token" }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?

    init(domain: String, refreshToken: String, clientId: String) {
        let tokenRequest = TokenRequest(
            grantType: "urn:ietf:params:oauth:grant-type:token-exchange",
            subjectToken: refreshToken,
            subjectTokenType: "urn:ietf:params:oauth:token-type:refresh_token",
            requestedTokenType: "urn:auth0:params:oauth:token-type:session_token",
            clientId: clientId
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.body = try? encoder.encode(tokenRequest)
        self.domain = domain
    }
}
