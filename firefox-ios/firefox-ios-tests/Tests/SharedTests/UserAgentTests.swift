// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Shared

final class UserAgentTests: XCTestCase {
    func testWaybackUserAgent_returnsExpectedUserAgent() {
        XCTAssertEqual(
            UserAgent.waybackUserAgent,
            "firefox-ios-neterr/\(AppInfo.appVersion) (+https://mzl.la/3RNfZFB)"
        )
    }

    // Ecosia: `configureEcosiaDesktopUserAgentDomains` mutates a process-wide singleton with no
    // getter to snapshot/restore the prior value, and XCTest doesn't guarantee test order, so any
    // test that calls it must reset it here to avoid leaking state into other tests in this target.
    override func tearDown() {
        UserAgent.configureEcosiaDesktopUserAgentDomains([])
        super.tearDown()
    }

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

    // Ecosia: Verify URLProvider-backed domains without a per-domain override receive
    // Ecosia's desktop UA. Uses a synthetic domain rather than ecosia.org/ecosia-staging.xyz,
    // since those are now also in `customDesktopUAForDomain` (see test below) and an
    // override always wins over this registration.
    func testGetUserAgentDesktop_withEcosiaDomains_returnEcosiaDesktopUserAgent() {
        let domains = ["some-other-ecosia-backed-domain.example"]
        UserAgent.configureEcosiaDesktopUserAgentDomains(domains)

        domains.forEach { domain in
            XCTAssertEqual(UserAgent.ecosiaDesktopUA, UserAgent.getUserAgent(domain: domain, platform: .Desktop))
        }
    }

    // Ecosia: Regression coverage for MOB-4879 — a WKWebView-hosted Cloudflare challenge on
    // ecosia.org loops forever on iPad. Root cause: `customUserAgent` overrides don't
    // propagate to fetch/XHR/Worker requests, only to document navigations, so branding the
    // desktop UA with "(Ecosia ios@...)" made the top-level document's UA diverge from the
    // UA used by the challenge's own worker requests, invalidating `cf_clearance`. ecosia.org
    // and ecosia-staging.xyz must resolve to the *plain*, unbranded desktop UA — identical to
    // what an unmodified request would use — so every request in the page converges on the
    // same string. Also guards against a future upstream merge reordering the two lookups
    // inside `getUserAgent(domain:platform:)` and silently reintroducing the branded UA here.
    func testGetUserAgentDesktop_withEcosiaOrgDomains_returnsPlainDesktopUserAgent() {
        let domains = ["ecosia.org", "ecosia-staging.xyz"]
        UserAgent.configureEcosiaDesktopUserAgentDomains(domains)

        domains.forEach { domain in
            let userAgent = UserAgent.getUserAgent(domain: domain, platform: .Desktop)
            XCTAssertEqual(userAgent, UserAgent.desktopUserAgent())
            XCTAssertNotEqual(userAgent, UserAgent.ecosiaDesktopUA)
            XCTAssertFalse(userAgent.contains(UserAgent.uaBitEcosia))
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

    func testIsGoogleDomain_withGoogleDomains_returnsTrue() {
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("google.com"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("www.google.com"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("mail.google.com"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("google.de"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("google.co.uk"))
        XCTAssertTrue(CustomUserAgentConstant.isGoogleDomain("https://www.google.com/search?q=firefox"))
    }

    func testIsGoogleDomain_withNonGoogleDomains_returnsFalse() {
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain("notgoogle.com"))
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain("google.example.com"))
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain("youtube.com"))
        XCTAssertFalse(CustomUserAgentConstant.isGoogleDomain(""))
    }

    func testGetUserAgentDesktop_withGoogleDomain_returnsGoogleDesktopUserAgent() {
        let ua = UserAgent.getUserAgent(domain: "www.google.com", platform: .Desktop)

        XCTAssertEqual(ua, CustomUserAgentConstant.googleDesktopUserAgent)
        XCTAssertTrue(ua.contains("FxiOS/"))
    }

    func testGetUserAgentDesktop_withGoogleCcTLD_returnsGoogleDesktopUserAgent() {
        let ua = UserAgent.getUserAgent(domain: "google.co.uk", platform: .Desktop)

        XCTAssertEqual(ua, CustomUserAgentConstant.googleDesktopUserAgent)
        XCTAssertTrue(ua.contains("FxiOS/"))
    }

    func testGetUserAgentMobile_withGoogleDomain_returnsDefaultMobileUserAgent() {
        let ua = UserAgent.getUserAgent(domain: "www.google.com", platform: .Mobile)

        XCTAssertEqual(ua, UserAgent.mobileUserAgent())
    }

    func testGetUserAgentDesktop_withNonGoogleDomain_doesNotContainFxiOS() {
        let ua = UserAgent.getUserAgent(domain: "example.com", platform: .Desktop)

        XCTAssertEqual(ua, UserAgent.desktopUserAgent())
        XCTAssertFalse(ua.contains("FxiOS/"))
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

    // Ecosia: Regression coverage — `ecosiaMobileUserAgent()` used to hardcode "CPU iPhone OS"
    // regardless of device, producing the impossible "(iPad; CPU iPhone OS ...)" combination no
    // real device sends (real iPad UAs use "CPU OS", with no "iPhone" token). Written as a
    // device-agnostic invariant so it holds whichever simulator/idiom CI runs it on.
    func testEcosiaMobileUserAgent_neverPairsIPadModelWithIPhoneOSToken() {
        let userAgent = UserAgentBuilder.ecosiaMobileUserAgent().userAgent()

        if userAgent.contains("iPad;") {
            XCTAssertFalse(userAgent.contains("CPU iPhone OS"))
            XCTAssertTrue(userAgent.contains("CPU OS "))
        } else {
            XCTAssertTrue(userAgent.contains("CPU iPhone OS"))
        }
    }
}
