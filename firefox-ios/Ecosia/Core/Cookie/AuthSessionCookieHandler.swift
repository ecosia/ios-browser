// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

final class AuthSessionCookieHandler: BaseCookieHandler {

    init() {
        super.init(cookieName: Cookie.authSession.rawValue)
    }

    /// Mirrors `EASC` into `HTTPCookieStorage.shared` as soon as the WKWebView cookie store reports it,
    /// so native `URLSession` calls can see the web session without waiting for an explicit sync point
    override func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }

    /// Removes any `EASC` cookie previously copied into `HTTPCookieStorage.shared`.
    ///
    /// We copy `EASC` cookie out of the WKWebView cookie jar so native `URLSession` calls can see it, but that copy lives
    /// independently of the WKWebView store and isn't cleared when the web session cookie is.
    /// This is called on logout so a stale session cookie for the previous user can't be attached to
    /// native requests made under a different, newly logged-in user.
    static func clearFromSharedStorage() {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        cookies
            .filter { $0.name == Cookie.authSession.rawValue }
            .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }
}
