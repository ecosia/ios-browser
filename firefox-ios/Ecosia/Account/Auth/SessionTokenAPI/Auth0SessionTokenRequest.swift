// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct Auth0SessionTokenRequest: BaseRequest {
    
    /// Struct for encoding the JSON request body
    struct TokenRequest: Codable {
        let grantType: String
        let subjectToken: String
        let subjectTokenType: String
        let requestedTokenType: String
        let clientId: String
    }

    private var domain: String
    
    private var refreshToken: String
    private var clientId: String

    let method: HTTPMethod = .post

    var baseURL: URL { URL(string: "https://\(domain)")! }

    var path: String { "/oauth/token" }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let request = TokenRequest(
            grantType: "urn:ietf:params:oauth:grant-type:token-exchange",
            subjectToken: refreshToken,
            subjectTokenType: "urn:ietf:params:oauth:token-type:refresh_token",
            requestedTokenType: "urn:auth0:params:oauth:token-type:session_token",
            clientId: clientId
        )
        return try? encoder.encode(request)
    }

    init(domain: String, refreshToken: String, clientId: String) {
        self.refreshToken = refreshToken
        self.clientId = clientId
        self.domain = domain
    }
}
