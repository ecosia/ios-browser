// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Shared
import Common

final class UserAgentTests: XCTestCase {
    func testGetUserAgentDesktop_withListedDomain_returnProperUserAgent() {
        let domains = CustomUserAgentConstant.customDesktopUAForDomain
        domains.forEach { domain, agent in
            // Ecosia: Add not nil check for domain
            XCTAssertNotNil(domain)
            XCTAssertEqual(agent, UserAgent.getUserAgent(domain: domain!, platform: .Desktop))
        }
    }

    func testGetUserAgentMobile_withListedDomain_returnProperUserAgent() {
        let domains = CustomUserAgentConstant.customMobileUAForDomain
        domains.forEach { domain, agent in
            XCTAssertEqual(agent, UserAgent.getUserAgent(domain: domain, platform: .Mobile))
        }
    }

    func testGetUserAgentDesktop_withPaypalDomain_returnMobileUserAgent() {
        let paypalDomain = "paypal.com"
        /* Ecosia: Use default Firefox UA instead
        XCTAssertEqual(UserAgent.mobileUserAgent(),
         */
        XCTAssertEqual(UserAgentBuilder.defaultFirefoxMobileUserAgent().userAgent(),
                       UserAgent.getUserAgent(domain: paypalDomain, platform: .Desktop))
    }

    func testGetUserAgentMobile_withPaypalDomain_returnProperUserAgent() {
        let paypalDomain = "paypal.com"
        /* Ecosia: Use default Firefox UA instead
        XCTAssertEqual(UserAgent.mobileUserAgent(),
         */
        XCTAssertEqual(UserAgentBuilder.defaultFirefoxMobileUserAgent().userAgent(),
                       UserAgent.getUserAgent(domain: paypalDomain, platform: .Mobile))
    }
}
