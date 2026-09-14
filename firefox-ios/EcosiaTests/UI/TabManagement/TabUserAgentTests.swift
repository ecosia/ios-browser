// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
import WebKit
@testable import Client

@MainActor
final class TabUserAgentTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var windowUUID: WindowUUID!

    override func setUp() {
        super.setUp()
        // Ecosia: register the AppContainer services Tab needs. `createWebview` resolves
        // `ThemeManager` from `AppContainer`, which fatal-errors if nothing is registered.
        DependencyHelperMock().bootstrapDependencies()
        windowUUID = WindowUUID()
    }

    override func tearDown() {
        windowUUID = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // Ecosia: Regression coverage for MOB-4879. `customUserAgent` mutations on a WKWebView only
    // take effect starting the *next* navigation (a documented WKWebView caveat), so a freshly
    // created webview's very first load must have the correct UA set proactively, before
    // `webView.load` is ever called. Relying solely on `decidePolicyFor` to set it reactively
    // applies one navigation too late — the first request goes out with WebKit's own default UA
    // instead of ours, which is exactly what broke Cloudflare's `cf_clearance` UA-consistency
    // check on iPad. This test guards `Tab.restore()` continuing to set it eagerly, since an
    // upstream merge touching `Tab.swift` could easily drop this without causing a build failure.
    func testCreateWebviewSetsCustomUserAgentBeforeFirstLoad() {
        let url = URL(string: "https://example.com/")!
        let tab = Client.Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.url = url

        tab.createWebview(configuration: WKWebViewConfiguration())

        let expectedUA = UserAgent.getUserAgent(domain: url.baseDomain ?? "")
        XCTAssertEqual(tab.webView?.customUserAgent, expectedUA)
    }
}
