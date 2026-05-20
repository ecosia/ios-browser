// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Shared
import Common

final class UserAgentTests: XCTestCase {
    // Ecosia: Verify the default mobile UA uses Ecosia's UA marker.
    func testDefaultMobileUserAgent_returnsEcosiaUserAgent() {
        let userAgent = UserAgent.mobileUserAgent()

        XCTAssertTrue(userAgent.contains(UserAgent.uaBitVersion))
        XCTAssertTrue(userAgent.contains(UserAgent.uaBitEcosia))
        XCTAssertFalse(userAgent.contains(UserAgent.uaBitFx))
    }

    // Ecosia: Verify client UA prefixes use Ecosia branding.
    func testClientUserAgents_useEcosiaPrefixes() {
        XCTAssertTrue(UserAgent.syncUserAgent.hasPrefix("Ecosia-iOS-Sync/"))
        XCTAssertTrue(UserAgent.tokenServerClientUserAgent.hasPrefix("Ecosia-iOS-Token/"))
        XCTAssertTrue(UserAgent.fxaUserAgent.hasPrefix("Ecosia-iOS-EcosiaA/"))
        XCTAssertTrue(UserAgent.defaultClientUserAgent.hasPrefix("Ecosia-iOS/"))
    }

    // Ecosia: Verify Ecosia domains receive Ecosia's desktop UA override.
    func testGetUserAgentDesktop_withEcosiaDomains_returnEcosiaDesktopUserAgent() {
        let domains = ["ecosia.org", "ecosia-staging.xyz"]
        UserAgent.configureEcosiaDesktopUserAgentDomains(domains)

        domains.forEach { domain in
            XCTAssertEqual(UserAgent.ecosiaDesktopUA, UserAgent.getUserAgent(domain: domain, platform: .Desktop))
        }
    }

    func testGetUserAgentDesktop_withListedDomain_returnProperUserAgent() {
        let domains = CustomUserAgentConstant.customDesktopUAForDomain
        domains.forEach { domain, agent in
            // Ecosia: Add not nil check for domain
            XCTAssertNotNil(domain)
            XCTAssertEqual(agent, UserAgent.getUserAgent(domain: domain, platform: .Desktop))
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
        /* Ecosia: Use default Firefox UA instead.
        XCTAssertEqual(UserAgentBuilder.defaultMobileUserAgent().userAgent(),
                       UserAgent.getUserAgent(domain: paypalDomain, platform: .Desktop))
         */
        XCTAssertEqual(UserAgentBuilder.defaultFirefoxMobileUserAgent().userAgent(),
                       UserAgent.getUserAgent(domain: paypalDomain, platform: .Desktop))
    }

    func testGetUserAgentMobile_withPaypalDomain_returnProperUserAgent() {
        let paypalDomain = "paypal.com"
        /* Ecosia: Use default Firefox UA instead.
        XCTAssertEqual(UserAgentBuilder.defaultMobileUserAgent().userAgent(),
                       UserAgent.getUserAgent(domain: paypalDomain, platform: .Mobile))
         */
        XCTAssertEqual(UserAgentBuilder.defaultFirefoxMobileUserAgent().userAgent(),
                       UserAgent.getUserAgent(domain: paypalDomain, platform: .Mobile))
    }
}
