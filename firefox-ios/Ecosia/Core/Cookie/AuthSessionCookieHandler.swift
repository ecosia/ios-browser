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

    /// Drops the mirrored copy too, since native requests (e.g. file uploads) fall back to it when the web view has none
    override func removed(in cookieStore: CookieStoreProtocol) {
        Self.clearFromSharedStorage()
        NotificationCenter.default.post(name: .EcosiaAuthSessionCookieRemoved, object: nil)
    }

    /// Removes any `EASC` cookie previously copied into `HTTPCookieStorage.shared`.
    ///
    /// We copy `EASC` cookie out of the WKWebView cookie jar so native `URLSession` calls can see it, but that copy lives
    /// independently of the WKWebView store. This is called on logout, so a stale session cookie for the previous user
    /// can't be attached to native requests made under a different, newly logged-in user, and when the web view's cookie
    /// is removed, so native requests don't keep sending a dead session.
    static func clearFromSharedStorage() {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        cookies
            .filter { $0.name == Cookie.authSession.rawValue }
            .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }
}
