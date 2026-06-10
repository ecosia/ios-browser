// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

extension Tab {

    /// Applies all Ecosia-specific mutations to a `URLRequest` before it is handed
    /// to WKWebView. Called from `Tab.loadRequest` as a single choke-point so every
    /// navigation — URL bar, Omnibox, tab restoration, vertical-preserving rewrites —
    /// picks up the changes without extra navigation cycles.
    ///
    /// Mutations applied, in order:
    /// 1. **Cloudflare auth headers** – required for non-production environments.
    /// 2. **Language-region header** – enriches SERP requests for market selection.
    /// 3. **Snowplow user id parameter** – appended to Ecosia URLs so the web SERP can
    ///    propagate it through its navigation links and link web Snowplow events back
    ///    to the native analytics identity. `ecosified()` sends the null UUID for
    ///    private tabs or when the user has opted out of analytics.
    func ecosiaUpdatedRequest(_ request: URLRequest) -> URLRequest {
        var updated = request
        updated = updated.withCloudFlareAuthParameters()
        if updated.url?.isEcosiaSearchQuery() == true {
            updated.addLanguageRegionHeader()
        }
        updated.url = updated.url.map { $0.ecosified(isIncognitoEnabled: isPrivate) }
        return updated
    }
}
