// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class UnleashCookieHandler: BaseCookieHandler {

    init() {
        super.init(cookieName: Cookie.unleash.rawValue)
    }

    override func getCookieValue() -> String? {
        // TODO: Ensure Unleash has been loaded when getting id
        return Unleash.model.id.uuidString.lowercased()
    }

    override func extractValue(_ value: String) {
        // No need to extract since we override the value
        // TODO: Do we need to force override again here if changed? Or is the one on `LegacyTabManager.makeWebViewConfig` enough?
    }
}
