// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

final class AuthSessionCookieHandler: BaseCookieHandler {

    init() {
        super.init(cookieName: Cookie.authSession.rawValue)
    }
    
    // Ecosia: Override to log when auth session cookie is received from web
    override func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol) {
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE] Auth session cookie received from web")
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE]   - Cookie name: \(cookie.name)")
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE]   - Cookie domain: \(cookie.domain)")
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE]   - Cookie path: \(cookie.path)")
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE]   - Cookie secure: \(cookie.isSecure)")
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE]   - Cookie httpOnly: \(cookie.isHTTPOnly)")
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE]   - Cookie expires: \(cookie.expiresDate?.description ?? "session")")
        
        #if DEBUG
        EcosiaLogger.auth.debug("🔐 [WEB-TO-NATIVE] [DEBUG-ONLY] Cookie value received from web: \(cookie.value)")
        #endif
        
        // Call super to allow any base processing if needed
        super.received(cookie, in: cookieStore)
        
        EcosiaLogger.auth.info("🔐 [WEB-TO-NATIVE] Auth session cookie processed successfully")
    }
}
