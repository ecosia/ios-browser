// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class AuthSessionCookieHandler: BaseCookieHandler {

    init() {
        super.init(cookieName: Cookie.authSession.rawValue)
    }

    /// Removes any `EASC` cookie previously copied into `HTTPCookieStorage.shared`.
    ///
    /// `FileUploadAuthCookieSync.syncAuthSessionCookieToSharedStorage` copies `EASC` out of the
    /// WKWebView cookie jar so native `URLSession` calls can see it, but that copy lives independently
    /// of the WKWebView store and isn't cleared when the web session cookie is. Call this on logout so a
    /// stale session cookie for the previous user can't be attached to native requests made under a
    /// different, newly logged-in user.
    static func clearFromSharedStorage() {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        cookies
            .filter { $0.name == Cookie.authSession.rawValue }
            .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }
}
