// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
class RouteTests: XCTestCase {
    func testSearchRouteWithUrl() {
        let subject = createSubject()
        let url = URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(
            route,
            .search(
                url: URL(string: "http://google.com?a=1&b=2&c=foo%20bar")!,
                isPrivate: false,
                options: [.focusLocationField]
            )
        )
    }

    func testSearchRouteWithEncodedUrl() {
        let subject = createSubject()

        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://open-url?url=http%3A%2F%2Fgoogle.com%3Fa%3D1%26b%3D2%26c%3Dfoo%2520bar")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: URL(string: "http://google.com?a=1&b=2&c=foo%20bar"), isPrivate: false))
    }

    func testSearchRouteWithPrivateFlag() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://open-url?private=true")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: nil, isPrivate: true))
    }

    func testPairingRouteFromSystemCameraDeepLink() {
        let subject = createSubject()
        let pairingURL = URL(
            string: "https://accounts.stage.mozaws.net/pair#channel_id=channel&channel_key=key&v=2"
        )!
        let url = wrappedDeepLink(for: pairingURL)

        let route = subject.makeRoute(url: url)

        guard case .fxaPairing(let routedURL) = route else {
            return XCTFail("The route should be an FxA pairing route")
        }
        XCTAssertEqual(routedURL, pairingURL)
    }

    func testPairingRouteFromSystemCameraUserActivity() {
        let subject = createSubject()
        let pairingURL = URL(
            string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2"
        )!
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = pairingURL

        let route = subject.makeRoute(userActivity: activity)

        guard case .fxaPairing(let routedURL) = route else {
            return XCTFail("The route should be an FxA pairing route")
        }
        XCTAssertEqual(routedURL, pairingURL)
    }

    func testPairingRouteFromDefaultBrowserURL() {
        let subject = createSubject()
        let pairingURL = URL(
            string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=2"
        )!

        guard case .fxaPairing(let routedURL) = subject.makeRoute(url: pairingURL) else {
            return XCTFail("The route should be an FxA pairing route")
        }
        XCTAssertEqual(routedURL, pairingURL)
    }

    func testInvalidPairingDeepLinkDoesNotOpenBrowserTab() {
        let subject = createSubject()
        let pairingURL = URL(string: "https://accounts.firefox.com/pair#v=2")!
        let url = wrappedDeepLink(for: pairingURL)

        XCTAssertNil(subject.makeRoute(url: url))
    }

    func testInvalidPairingUserActivityDoesNotOpenBrowserTab() {
        let subject = createSubject()
        let pairingURL = URL(string: "https://accounts.firefox.com/pair#v=2")!
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = pairingURL

        XCTAssertNil(subject.makeRoute(userActivity: activity))
    }

    func testNonV2PairingUserActivityOpensBrowserTab() {
        let subject = createSubject()
        let pairingURL = URL(
            string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key"
        )!
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = pairingURL

        guard case .search(let routedURL, _, _) = subject.makeRoute(userActivity: activity) else {
            return XCTFail("A non-v2 pairing URL should use the existing browser route")
        }
        XCTAssertEqual(routedURL, pairingURL)
    }

    func testNonV2DirectPairingURLOpensBrowserTab() {
        let subject = createSubject()
        let pairingURL = URL(
            string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=1"
        )!

        guard case .search(let routedURL, _, _) = subject.makeRoute(url: pairingURL) else {
            return XCTFail("A non-v2 pairing URL should use the existing browser route")
        }
        XCTAssertEqual(routedURL, pairingURL)
    }

    func testNonV2WrappedPairingDeepLinkOpensBrowserTab() {
        let subject = createSubject()
        let pairingURL = URL(
            string: "https://accounts.firefox.com/pair#channel_id=channel&channel_key=key&v=1"
        )!

        guard case .search(let routedURL, _, _) = subject.makeRoute(url: wrappedDeepLink(for: pairingURL)) else {
            return XCTFail("A non-v2 pairing URL should use the existing browser route")
        }
        XCTAssertEqual(routedURL, pairingURL)
    }

    func testSettingsRouteWithClearPrivateData() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/settings/clear-private-data")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .clearPrivateData))
    }

    func testSettingsRouteWithNewTab() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/settings/newTab")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .newTab))
    }

    func testSettingsRouteWithNewTabTrailingSlash() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/settings/newTab/")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .newTab))
    }

    func testSettingsRouteWithHomePage() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/settings/homePage")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .homePage))
    }

    func testSettingsRouteWithMailto() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/settings/mailto")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .mailto))
    }

    func testSettingsRouteWithSearch() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/settings/search")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .search))
    }

    func testSettingsRouteWithFxa() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/settings/fxa")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .settings(section: .fxa))
    }

    func testHomepanelRouteWithBookmarks() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/homepanel/bookmarks")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .bookmarks))
    }

    func testHomepanelRouteWithTopSites() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/homepanel/top-sites")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .topSites))
    }

    func testHomepanelRouteWithHistory() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/homepanel/history")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .history))
    }

    func testHomepanelRouteWithReadingList() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/homepanel/reading-list")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .homepanel(section: .readingList))
    }

    func testDefaultBrowserRouteWithTutorial() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/default-browser/tutorial")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .defaultBrowser(section: .tutorial))
    }

    func testDefaultBrowserRouteWithSystemSettings() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/default-browser/system-settings")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .defaultBrowser(section: .systemSettings))
    }

    func testInvalidRouteWithBadPath() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/homepanel/badbad")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testFxaSignInrouteBuilderRoute() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://fxa-signin?signin=coolcodes&user=foo&email=bar")!

        let route = subject.makeRoute(url: url)

        let expectedQuery = ["signin": "coolcodes", "user": "foo", "email": "bar"]
        XCTAssertEqual(route, .fxaSignIn(params: FxALaunchParams(entrypoint: .fxaDeepLinkNavigation,
                                                                 query: expectedQuery)))
    }

    func testInvalidScheme() {
        let subject = createSubject()
        let url = URL(string: "focus://deep-link?url=/settings/newTab")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWhenJSSchemeWithSearchThenDoesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=javascript://https://google.com%2Fsearch?q=foo")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testMakeRouteWhenJSSchemeWithAlertThenDoesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=javascript:alert(1)")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testMakeRouteWhenJSSchemeWithWindowCloseThenDoesntOpenRoute() {
        let subject = createSubject()
        let url = URL(string: "firefox://open-url?url=javascript:window.close();alert(1337)")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidDeepLink() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-links-are-fun?url=/settings/newTab/")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testWidgetMediumTopSitesOpenUrl() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-medium-topsites-open-url?url=https://google.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: false))
    }

    func testWidgetSmallQuicklinkOpenUrlWithPrivateFlag() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-small-quicklink-open-url?private=true&url=https://google.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(
            route,
            .search(url: URL(string: "https://google.com"), isPrivate: true, options: [.focusLocationField])
        )
    }

    func testWidgetMediumQuicklinkOpenUrlWithoutPrivateFlag() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-medium-quicklink-open-url?url=https://google.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(
            route,
            .search(url: URL(string: "https://google.com"), isPrivate: false, options: [.focusLocationField])
        )
    }

    func testWidgetSmallQuicklinkOpenCopied() {
        let subject = createSubject()
        UIPasteboard.general.string = "test search text"
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .searchQuery(query: "test search text", isPrivate: false))
    }

    func testWidgetSmallQuicklinkOpenCopiedWithUrl() {
        let subject = createSubject()
        UIPasteboard.general.url = URL(string: "https://google.com")
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-small-quicklink-open-copied")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: URL(string: "https://google.com"), isPrivate: false))
    }

    func testWidgetSmallQuicklinkClosePrivateTabs() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-small-quicklink-close-private-tabs")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .action(action: .closePrivateTabs))
    }

    func testWidgetMediumQuicklinkClosePrivateTabs() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-medium-quicklink-close-private-tabs")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .action(action: .closePrivateTabs))
    }

    func testUnsupportedScheme() {
        let subject = createSubject()
        let url = URL(string: "chrome://example.com")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidHost() {
        let subject = createSubject()
        let url = URL(string: "firefox://")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidDeepLinking() {
        let subject = createSubject()
        let url = URL(string: "firefox://deep-link?url=/invalid-path")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testInvalidWidgetTabUuid() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://widget-tabs-medium-open-url?uuid=invalid")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .search(url: nil, isPrivate: false))
    }

    func testInvalidFxaSignIn() {
        let subject = createSubject()
        let url = URL(string: "firefox://fxa-signin")!

        let route = subject.makeRoute(url: url)

        XCTAssertNil(route)
    }

    func testOpenText() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://open-text?text=google")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .searchQuery(query: "google", isPrivate: false))
    }

    // MARK: - AppAction

    func testAppAction_showIntroOnboarding() {
        let subject = createSubject()
        // Ecosia: Update url
        // let url = URL(string: "firefox://open-url?private=true")!
        let url = URL(string: "ecosia://deep-link?url=/action/show-intro-onboarding")!

        let route = subject.makeRoute(url: url)

        XCTAssertEqual(route, .action(action: .showIntroOnboarding))
    }

    // MARK: - Helper

    func createSubject() -> RouteBuilder {
        let subject = RouteBuilder()
        subject.configure(isPrivate: false, prefs: MockProfile().prefs)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func wrappedDeepLink(for url: URL) -> URL {
        var components = URLComponents(string: "firefox://open-url")!
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
        return components.url!
    }
}
