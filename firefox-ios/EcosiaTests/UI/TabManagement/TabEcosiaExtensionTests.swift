// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import WebKit
@testable import Client
@testable import Ecosia

@MainActor
final class TabEcosiaExtensionTests: XCTestCase {

    // Ecosia: implicitly-unwrapped so tearDown can set it to nil; setUp assigns a fresh WindowUUID(). (MOB-4384)
    private var windowUUID: WindowUUID!
    private var savedAnalyticsId = UUID()
    private var savedSendAnonymousUsageData = true
    private var savedCookieConsentValue: String?

    override func setUp() {
        super.setUp()
        windowUUID = WindowUUID()
        savedAnalyticsId = User.shared.analyticsId
        savedSendAnonymousUsageData = User.shared.sendAnonymousUsageData
        savedCookieConsentValue = User.shared.cookieConsentValue
        User.shared.sendAnonymousUsageData = true
        User.shared.cookieConsentValue = "a"
    }

    override func tearDown() {
        User.shared.analyticsId = savedAnalyticsId
        User.shared.sendAnonymousUsageData = savedSendAnonymousUsageData
        User.shared.cookieConsentValue = savedCookieConsentValue
        windowUUID = nil
        super.tearDown()
    }

    // MARK: - _sp injection

    func testSpAddedToEcosiaURL() {
        let tab = makeTab(isPrivate: false)
        let url = URL(string: "https://www.ecosia.org/search?q=cats&tt=iosapp")!
        let result = tab.ecosiaUpdatedRequest(URLRequest(url: url))

        XCTAssertTrue(result.url?.hasEcosiaUserId == true)
        XCTAssertEqual(
            result.url?.queryItem(named: "_sp"),
            User.shared.analyticsId.uuidString
        )
    }

    func testSpNotAddedToNonEcosiaURL() {
        let tab = makeTab(isPrivate: false)
        let url = URL(string: "https://example.com/search?q=cats")!
        let result = tab.ecosiaUpdatedRequest(URLRequest(url: url))

        XCTAssertFalse(result.url?.hasEcosiaUserId == true)
    }

    func testSpNotDuplicatedWhenAlreadyPresent() {
        let tab = makeTab(isPrivate: false)
        let existingSP = "existing-sp-value"
        let url = URL(string: "https://www.ecosia.org/search?q=cats&_sp=\(existingSP)")!
        let result = tab.ecosiaUpdatedRequest(URLRequest(url: url))

        // guard !url.hasEcosiaUserId means the existing value is preserved unchanged
        XCTAssertEqual(result.url?.queryItem(named: "_sp"), existingSP)
    }

    func testSpIsNullUUIDForPrivateTab() {
        let tab = makeTab(isPrivate: true)
        let url = URL(string: "https://www.ecosia.org/search?q=cats&tt=iosapp")!
        let result = tab.ecosiaUpdatedRequest(URLRequest(url: url))

        XCTAssertEqual(
            result.url?.queryItem(named: "_sp"),
            UUID(uuid: UUID_NULL).uuidString
        )
    }

    func testSpIsNullUUIDWhenAnalyticsOptedOut() {
        User.shared.sendAnonymousUsageData = false
        let tab = makeTab(isPrivate: false)
        let url = URL(string: "https://www.ecosia.org/search?q=cats&tt=iosapp")!
        let result = tab.ecosiaUpdatedRequest(URLRequest(url: url))

        XCTAssertEqual(
            result.url?.queryItem(named: "_sp"),
            UUID(uuid: UUID_NULL).uuidString
        )
    }

    // MARK: - Language-region header

    func testLanguageRegionHeaderAddedForSERPURL() {
        let tab = makeTab(isPrivate: false)
        let url = URL(string: "https://www.ecosia.org/search?q=cats")!
        let result = tab.ecosiaUpdatedRequest(URLRequest(url: url))

        let expected = Locale.current.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        XCTAssertEqual(result.value(forHTTPHeaderField: "x-ecosia-app-language-region"), expected)
    }

    func testLanguageRegionHeaderNotAddedForNonSERPURL() {
        let tab = makeTab(isPrivate: false)
        let url = URL(string: "https://www.ecosia.org/")!
        let result = tab.ecosiaUpdatedRequest(URLRequest(url: url))

        XCTAssertNil(result.value(forHTTPHeaderField: "x-ecosia-app-language-region"))
    }

    // MARK: - loadRequest integration

    func testLoadRequestPassesEcosifiedURLToWebView() {
        let tab = makeTab(isPrivate: false)
        tab.createWebview(configuration: WKWebViewConfiguration())

        let expect = expectation(description: "decidePolicyFor called")
        let spy = NavigationSpy(expectation: expect)
        tab.navigationDelegate = spy

        let url = URL(string: "https://www.ecosia.org/search?q=cats&tt=iosapp")!
        tab.loadRequest(URLRequest(url: url))

        waitForExpectations(timeout: 2)
        XCTAssertTrue(spy.capturedURL?.hasEcosiaUserId == true,
                      "loadRequest must pass the ecosified URL (with _sp) to WKWebView")
    }

    func testLoadRequestPassesNullUUIDForPrivateTab() {
        let tab = makeTab(isPrivate: true)
        tab.createWebview(configuration: WKWebViewConfiguration())

        let expect = expectation(description: "decidePolicyFor called")
        let spy = NavigationSpy(expectation: expect)
        tab.navigationDelegate = spy

        let url = URL(string: "https://www.ecosia.org/search?q=cats&tt=iosapp")!
        tab.loadRequest(URLRequest(url: url))

        waitForExpectations(timeout: 2)
        XCTAssertEqual(spy.capturedURL?.queryItem(named: "_sp"),
                       UUID(uuid: UUID_NULL).uuidString)
    }

    // MARK: - Helpers

    private func makeTab(isPrivate: Bool) -> Client.Tab {
        Client.Tab(profile: MockProfile(), isPrivate: isPrivate, windowUUID: windowUUID)
    }
}

// MARK: - Navigation spy

private final class NavigationSpy: NSObject, WKNavigationDelegate {
    private(set) var capturedURL: URL?
    private let expectation: XCTestExpectation

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        capturedURL = navigationAction.request.url
        expectation.fulfill()
        return .cancel
    }
}

private extension URL {
    func queryItem(named name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
