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

    func testErrorPageClosesTabEvenWhenItIsTheStartPage() async throws {
        let errorURL = sessionURLProvider.root.appendingPathComponent("accounts/error")
        let tab = try await startSession(url: errorURL)

        TabEvent.post(.didChangeURL(errorURL), for: tab)

        try await waitUntil { !self.tabManager.tabs.contains(tab) }
    }

    func testLandedPageInOtherTabDoesNotCloseSessionTab() async throws {
        let tab = try await startSession()
        let otherTab = Client.Tab(profile: MockProfile(), windowUUID: tabManager.windowUUID)

        TabEvent.post(.didChangeURL(landedURL), for: otherTab)

        try await waitPastSettleDelay()
        XCTAssertTrue(tabManager.tabs.contains(tab), "Another tab's page should not close the session's tab")
    }

    // MARK: - Transfer Outcome

    func testTransferEndingOnAuth0IsFailure() async throws {
        let auth0SignUpURL = URL(string: "https://\(sessionURLProvider.auth0Domain)/u/signup?state=abc")!

        let success = try await outcomeOfSession(endingOn: auth0SignUpURL)

        XCTAssertFalse(success)
    }

    func testTransferEndingOnErrorPageIsFailure() async throws {
        let errorURL = sessionURLProvider.root.appendingPathComponent("accounts/error")

        let success = try await outcomeOfSession(endingOn: errorURL)

        XCTAssertFalse(success)
    }

    func testTransferEndingOnSignInIsFailure() async throws {
        let success = try await outcomeOfSession(endingOn: sessionURLProvider.signInURL)

        XCTAssertFalse(success)
    }

    func testTransferEndingOnOtherWebPageIsSuccess() async throws {
        let success = try await outcomeOfSession(endingOn: landedURL)

        XCTAssertTrue(success)
    }

    func testTransferEndingOnNonEcosiaPageIsSuccess() async throws {
        let success = try await outcomeOfSession(endingOn: URL(string: "https://example.com/")!)

        XCTAssertTrue(success)
    }

    // MARK: - Helpers

    /// The session classifies URLs with the current environment's provider, so its events must use the same one
    private var sessionURLProvider: URLProvider { EcosiaEnvironment.current.urlProvider }
    private var landedURL: URL { sessionURLProvider.root }
    private var auth0URL: URL { URL(string: "https://\(sessionURLProvider.auth0Domain)/authorize")! }

    /// Starts a session and returns its tab once monitoring is set up
    private func startSession(url: URL? = nil,
                              completion: @escaping (Bool) -> Void = { _ in }) async throws -> Client.Tab {
        let session = try InvisibleTabSession(url: url ?? sessionURLProvider.signUpURL,
                                              browserViewController: browserViewController,
                                              timeout: 10.0,
                                              landingSettleDelay: settleDelay)
        sessions.append(session)
        session.startMonitoring(completion)
        let tab = try XCTUnwrap(tabManager.tabs.last)
        try await waitUntil { InvisibleTabAutoCloseManager.shared.trackedTabUUIDs.contains(tab.tabUUID) }
        return tab
    }

    /// Tests have no web view to report navigations, so the start URL stays the session's final URL
    private func outcomeOfSession(endingOn finalURL: URL) async throws -> Bool {
        var outcome: Bool?
        let tab = try await startSession(url: finalURL) { outcome = $0 }

        TabEvent.post(.didClose, for: tab)

        try await waitUntil { outcome != nil }
        return try XCTUnwrap(outcome)
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
}
// swiftlint:enable implicitly_unwrapped_optional
