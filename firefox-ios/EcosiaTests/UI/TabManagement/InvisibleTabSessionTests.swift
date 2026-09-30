// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Ecosia
import Common
@testable import Client
// swiftlint:disable implicitly_unwrapped_optional

@MainActor
final class InvisibleTabSessionTests: XCTestCase {

    private let urlProvider: URLProvider = .production
    private let settleDelay: TimeInterval = 0.05
    private var tabManager: TabAutoCloseTestMockTabManager!
    private var browserViewController: BrowserViewController!
    private var sessions: [InvisibleTabSession] = []

    override func setUp() {
        super.setUp()
        InvisibleTabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()
        tabManager = TabAutoCloseTestMockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)
        browserViewController = BrowserViewController(profile: MockProfile(), tabManager: tabManager)
    }

    override func tearDown() {
        sessions = []
        InvisibleTabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()
        browserViewController = nil
        tabManager = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - Delayed Close

    func testLandedPageClosesTabAfterSettleDelay() async throws {
        let tab = try await startSession()

        TabEvent.post(.didChangeURL(landedURL), for: tab)

        XCTAssertTrue(tabManager.tabs.contains(tab), "Tab should stay open during the settle delay")
        try await waitUntil { !self.tabManager.tabs.contains(tab) }
    }

    func testNewerPageWithinSettleDelayCancelsClose() async throws {
        let tab = try await startSession()

        TabEvent.post(.didChangeURL(landedURL), for: tab)
        TabEvent.post(.didChangeURL(auth0URL), for: tab)

        try await waitPastSettleDelay()
        XCTAssertTrue(tabManager.tabs.contains(tab), "A redirect within the settle delay should keep the tab open")
    }

    func testClosesOnFinalPageAfterRedirect() async throws {
        let tab = try await startSession()

        TabEvent.post(.didChangeURL(auth0URL), for: tab)
        try await waitPastSettleDelay()
        XCTAssertTrue(tabManager.tabs.contains(tab))

        TabEvent.post(.didChangeURL(landedURL), for: tab)
        try await waitUntil { !self.tabManager.tabs.contains(tab) }
    }

    func testPagesThatHaveNotLandedNeverCloseTab() async throws {
        let tab = try await startSession()

        TabEvent.post(.didChangeURL(auth0URL), for: tab)
        TabEvent.post(.didChangeURL(sessionURLProvider.signUpURL), for: tab)
        TabEvent.post(.didChangeURL(sessionURLProvider.signInURL), for: tab)

        try await waitPastSettleDelay()
        XCTAssertTrue(tabManager.tabs.contains(tab), "Only a landed page should close the tab")
    }

    func testLandedPageInOtherTabDoesNotCloseSessionTab() async throws {
        let tab = try await startSession()
        let otherTab = Client.Tab(profile: MockProfile(), windowUUID: tabManager.windowUUID)

        TabEvent.post(.didChangeURL(landedURL), for: otherTab)

        try await waitPastSettleDelay()
        XCTAssertTrue(tabManager.tabs.contains(tab), "Another tab's page should not close the session's tab")
    }

    // MARK: - Landed Pages

    func testHasLandedOnWwwPageOtherThanStart() {
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/", from: urlProvider.signUpURL))
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/accounts/profile", from: urlProvider.logoutURL))
    }

    func testHasLandedOnErrorPage() {
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/accounts/error", from: urlProvider.signUpURL))
    }

    func testHasLandedOnErrorPageThatIsAlsoTheStartPage() {
        let errorURL = URL(string: "https://www.ecosia.org/accounts/error")!
        XCTAssertTrue(InvisibleTabSession.hasLanded(on: errorURL, from: errorURL, urlProvider: urlProvider))
    }

    func testHasNotLandedOnSignIn() {
        XCTAssertFalse(hasLanded(on: "https://www.ecosia.org/accounts/sign-in", from: urlProvider.signUpURL))
        XCTAssertFalse(hasLanded(on: "https://www.ecosia.org/accounts/sign-in?returnTo=x", from: urlProvider.logoutURL))
    }

    func testHasNotLandedOnStartPage() {
        XCTAssertFalse(hasLanded(on: urlProvider.signUpURL.absoluteString, from: urlProvider.signUpURL))
        XCTAssertFalse(hasLanded(on: "https://www.ecosia.org/accounts/sign-out?x=1", from: urlProvider.logoutURL))
    }

    func testHasNotLandedOnAuth0Host() {
        XCTAssertFalse(hasLanded(on: "https://login.ecosia.org/authorize", from: urlProvider.signUpURL))
        XCTAssertFalse(hasLanded(on: "https://login.ecosia.org/v2/logout", from: urlProvider.logoutURL))
    }

    func testHasNotLandedOnOtherHost() {
        XCTAssertFalse(hasLanded(on: "https://example.com/", from: urlProvider.signUpURL))
    }

    // MARK: - Helpers

    /// The session classifies URLs with the current environment's provider, so its events must use the same one
    private var sessionURLProvider: URLProvider { EcosiaEnvironment.current.urlProvider }
    private var landedURL: URL { sessionURLProvider.root }
    private var auth0URL: URL { URL(string: "https://\(sessionURLProvider.auth0Domain)/authorize")! }

    /// Starts a session on the sign-up URL and returns its tab once monitoring is set up
    private func startSession() async throws -> Client.Tab {
        let session = try InvisibleTabSession(url: sessionURLProvider.signUpURL,
                                              browserViewController: browserViewController,
                                              timeout: 10.0,
                                              landingSettleDelay: settleDelay)
        sessions.append(session)
        session.startMonitoring { _ in }
        let tab = try XCTUnwrap(tabManager.tabs.last)
        try await waitUntil { InvisibleTabAutoCloseManager.shared.trackedTabUUIDs.contains(tab.tabUUID) }
        return tab
    }

    private func waitPastSettleDelay() async throws {
        try await Task.sleep(nanoseconds: UInt64(settleDelay * 4 * 1_000_000_000))
    }

    private func waitUntil(timeout: TimeInterval = 1.0, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Condition not met within \(timeout)s")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func hasLanded(on urlString: String, from startURL: URL) -> Bool {
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid URL: \(urlString)")
            return false
        }
        return InvisibleTabSession.hasLanded(on: url, from: startURL, urlProvider: urlProvider)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
