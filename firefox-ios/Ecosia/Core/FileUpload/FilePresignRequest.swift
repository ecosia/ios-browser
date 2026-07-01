// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// POST to the AI Worker to obtain a presigned upload URL and `file_id`.
///
/// The route is protected by `setAuthNoOptOut` + `requireScopes(['write:conversations'])`.
/// Today the middleware reads the `EASC` web session cookie; Bearer token support for
/// native Auth0 clients is a pending backend change (see spike branch notes).
struct FilePresignRequest: BaseRequest {

    var method: HTTPMethod { .post }

    var path: String { "/v2/conversations/files/upload" }

    var queryParameters: [String: String]?

    var body: Data?

    var additionalHeaders: [String: String]?

    init(accessToken: String, authSessionCookie: HTTPCookie? = nil) {
        var headers = [
            "Authorization": "Bearer \(accessToken)",
            "X-API-Version": "v1",
        ]
        if let authSessionCookie {
            headers["Cookie"] = "\(authSessionCookie.name)=\(authSessionCookie.value)"
        }
        additionalHeaders = headers
    }
}
