// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// POST to the AI Worker to obtain a presigned upload URL and `file_id`.
///
/// The route is protected by `setAuthNoOptOut` + `requireScopes(['write:conversations'])`.
/// The current middleware only reads the EASC session cookie; it does not support Bearer tokens.
///
/// **Required backend change before this can work on mobile:**
/// `setAuthNoOptOut` in `ai-search-worker` needs to fall back to calling
/// `AUTH_WORKER.verifyAccessToken(token, scopes)` when an `Authorization: Bearer` header is
/// present instead of a cookie. The RPC method already exists — only the middleware needs updating.
struct FilePresignRequest: BaseRequest {

    var method: HTTPMethod { .post }

    // AI Worker lives under /v2/conversations on api.{domain}.
    // Web: `${aiWorkerApiUrl}/files/upload` where aiWorkerApiUrl = `${PROD_API}/v2/conversations`
    var path: String { "/v2/conversations/files/upload" }

    var queryParameters: [String: String]?

    // No body — the server generates the presigned URL server-side.
    var body: Data?

    var additionalHeaders: [String: String]?

    init(accessToken: String) {
        additionalHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "X-API-Version": "v1",
        ]
    }
}
