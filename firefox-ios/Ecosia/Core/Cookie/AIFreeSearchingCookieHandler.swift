// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class AIFreeSearchingCookieHandler: BaseCookieHandler {

    init() {
        super.init(cookieName: Cookie.aiFreeSearching.rawValue)
    }

    /// Three-state cookie: omit when unset (`nil`), `"true"` / `"false"` when the
    /// user has an explicit preference. Returns `nil` when the feature flag is
    /// off so no `ECNOAI` cookie is written.
    override func getCookieValue() -> String? {
        guard AIFreeSearchingFeatureFlag.isEnabled else { return nil }
        return User.shared.aiFreeSearching.map(\.description)
    }

    override func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol) {
        guard AIFreeSearchingFeatureFlag.isEnabled else { return }
        AIFreeSearchingSelection.setEnabled(Bool(cookie.value))
    }
}
