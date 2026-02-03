// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia
import Common

/// Encapsulates an invisible tab session with its monitoring and cleanup
/// Single responsibility: manage one invisible tab through its complete lifecycle
final class InvisibleTabSession: TabEventHandler {

    // MARK: - Properties

    private let tab: Tab
    private let url: URL
    private let timeout: TimeInterval
    private weak var browserViewController: BrowserViewController?
    private let authService: Ecosia.EcosiaAuthenticationService

    // State
    private var isCompleted = false
    private var completion: ((Bool) -> Void)?

    // MARK: - Initialization

    /// Creates an invisible tab session
    /// - Parameters:
    ///   - url: URL to load in the tab
    ///   - browserViewController: Browser view controller for tab operations
    ///   - authService: Authentication service for session operations
    ///   - timeout: Fallback timeout for completion
    init(url: URL,
         browserViewController: BrowserViewController,
         authService: Ecosia.EcosiaAuthenticationService,
         timeout: TimeInterval = 10.0) throws {
        self.url = url
        self.browserViewController = browserViewController
        self.authService = authService
        self.timeout = timeout

        // Create the tab immediately
        self.tab = try Self.createInvisibleTab(url: url, browserViewController: browserViewController)

        EcosiaLogger.invisibleTabs.info("InvisibleTabSession created for: \(url)")
    }

    // MARK: - Session Management

    /// Sets up session cookies for the tab
    func setupSessionCookies() {
        guard let sessionCookie = authService.getSessionTokenCookie() else {
            EcosiaLogger.cookies.notice("No session cookie available for tab")
            return
        }

        Task { @MainActor in
            tab.webView?.configuration.websiteDataStore.httpCookieStore.setCookie(sessionCookie)
            EcosiaLogger.cookies.info("Session cookie set for tab: \(self.tab.tabUUID)")
        }
    }

    /// Starts monitoring for session completion (page load + auth)
    /// - Parameter completion: Called when session completes or times out
    func startMonitoring(_ completion: @escaping (Bool) -> Void) {
        self.completion = completion

        setupTabAutoCloseManager()

        EcosiaLogger.invisibleTabs.info("Starting session monitoring: \(tab.tabUUID)")
    }

    // MARK: - Private Implementation

    /// Ecosia: Use TabManager.addTab (LegacyTabManager/configureTab removed in Firefox upgrade)
    private static func createInvisibleTab(url: URL, browserViewController: BrowserViewController) throws -> Tab {
        let profile = browserViewController.profile
        let tabManager = browserViewController.tabManager

        let newTab = tabManager.addTab(
            URLRequest(url: url),
            afterTab: nil,
            zombie: false,
            isPrivate: false
        )
        newTab.url = url
        newTab.isInvisible = true

        InvisibleTabManager.shared.markTabAsInvisible(newTab)

        EcosiaLogger.invisibleTabs.info("Invisible tab created: \(newTab.tabUUID)")
        return newTab
    }

    private func setupTabAutoCloseManager() {
        guard let tabManager = browserViewController?.tabManager else { return }
        let tabUUID = tab.tabUUID
        let timeout = timeout

        Task { @MainActor in
            InvisibleTabAutoCloseManager.shared.setTabManager(tabManager)
            InvisibleTabAutoCloseManager.shared.setupAutoCloseForTab(
                tabUUID: tabUUID,
                on: .EcosiaAuthStateChanged,
                timeout: timeout
            )
            register(self, forTabEvents: .didClose)
        }
    }

    private func handleTabClosed() {
        guard !isCompleted else { return }
        isCompleted = true

        cleanup()

        EcosiaLogger.invisibleTabs.info("Session completed for tab: \(tab.tabUUID), success: true")
        // Ecosia: Ensure completion is called on main for strict concurrency (caller may update UI).
        let completionToCall = completion
        completion = nil
        if let completionToCall = completionToCall {
            Task { @MainActor in
                completionToCall(true)
            }
        }
    }

    private func cleanup() {
        Task { @MainActor in
            InvisibleTabAutoCloseManager.shared.cancelAutoCloseForTab(tab.tabUUID)
        }
    }

    private func closeTab() {
        guard let browserViewController = browserViewController else {
            return
        }

        let tabManager = browserViewController.tabManager

        // Remove from invisible tracking
        InvisibleTabManager.shared.markTabAsVisible(tab)

        // Ecosia: TabManager protocol has removeTab(_ tabUUID: TabUUID) with no completion
        tabManager.removeTab(tab.tabUUID)
        tabManager.cleanupInvisibleTabTracking()
        EcosiaLogger.invisibleTabs.info("Tab closed: \(tab.tabUUID)")
    }

    // MARK: - TabEventHandler

    var tabEventWindowResponseType: TabEventHandlerWindowResponseType {
        // Only respond to events for the specific window this session belongs to
        return .singleWindow(browserViewController?.tabManager.windowUUID ?? WindowUUID.unavailable)
    }

    func tabDidClose(_ tab: Tab) {
        // Only handle close events for our specific tab
        guard tab.tabUUID == self.tab.tabUUID else { return }
        handleTabClosed()
    }

    // MARK: - Cleanup

    /// Ecosia: Don't call cleanup() from deinit — cleanup() is main-actor/actor-isolated. Callers must ensure cleanup when session ends (e.g. handleTabClosed).
    deinit {
        EcosiaLogger.invisibleTabs.debug("InvisibleTabSession deallocated")
    }
}
