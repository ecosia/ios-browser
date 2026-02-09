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
        EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Setting up session cookies for tab: \(tab.tabUUID)")
        
        guard let sessionCookie = authService.getSessionTokenCookie() else {
            EcosiaLogger.invisibleTabs.notice("🔐 [INVISIBLE-TAB] No session cookie available for tab: \(tab.tabUUID)")
            return
        }

        Task { @MainActor in
            EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Injecting session cookie into webview")
            EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB]   - Cookie name: \(sessionCookie.name)")
            EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB]   - Cookie domain: \(sessionCookie.domain)")
            EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB]   - Cookie path: \(sessionCookie.path)")
            EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB]   - Cookie secure: \(sessionCookie.isSecure)")
            EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB]   - Cookie expires: \(sessionCookie.expiresDate?.description ?? "session")")
            
            #if DEBUG
            EcosiaLogger.invisibleTabs.debug("🔐 [INVISIBLE-TAB] [DEBUG-ONLY] Cookie value being injected: \(sessionCookie.value)")
            #endif
            
            tab.webView?.configuration.websiteDataStore.httpCookieStore.setCookie(sessionCookie)
            EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Session cookie set successfully for tab: \(self.tab.tabUUID)")
            
            #if DEBUG
            // Verify the cookie was actually set by reading it back
            let cookieStore = tab.webView?.configuration.websiteDataStore.httpCookieStore
            if let cookieStore = cookieStore {
                let allCookies = await cookieStore.allCookies()
                if let retrievedCookie = allCookies.first(where: { $0.name == sessionCookie.name }) {
                    EcosiaLogger.invisibleTabs.debug("🔐 [INVISIBLE-TAB] [DEBUG-ONLY] Cookie retrieved from webview: name=\(retrievedCookie.name), value=\(retrievedCookie.value)")
                } else {
                    EcosiaLogger.invisibleTabs.error("🔐 [INVISIBLE-TAB] [DEBUG-ONLY] Cookie not found in webview after setting!")
                }
            }
            #endif
        }
    }

    /// Starts monitoring for session completion (page load + auth)
    /// - Parameter completion: Called when session completes or times out
    func startMonitoring(_ completion: @escaping (Bool) -> Void) {
        self.completion = completion

        EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Starting session monitoring for tab: \(tab.tabUUID)")
        EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Target URL: \(url)")
        EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Timeout: \(timeout) seconds")
        
        setupTabAutoCloseManager()
    }

    // MARK: - Private Implementation

    private static func createInvisibleTab(url: URL, browserViewController: BrowserViewController) throws -> Tab {
        let profile = browserViewController.profile

        guard let tabManager = browserViewController.tabManager as? LegacyTabManager else {
            throw AuthError.authFlowConfigurationError("TabManager not available")
        }

        // Create invisible tab
        let newTab = Tab(profile: profile, isPrivate: false, windowUUID: tabManager.windowUUID)
        newTab.url = url
        newTab.isInvisible = true

        tabManager.configureTab(newTab,
                                request: URLRequest(url: url),
                                afterTab: nil,
                                flushToDisk: true,
                                zombie: false)

        // Mark as invisible in the manager
        InvisibleTabManager.shared.markTabAsInvisible(newTab)

        EcosiaLogger.invisibleTabs.info("Invisible tab created: \(newTab.tabUUID)")
        return newTab
    }

    private func setupTabAutoCloseManager() {
        // Ensure InvisibleTabAutoCloseManager has the TabManager reference
        if let tabManager = browserViewController?.tabManager {
            InvisibleTabAutoCloseManager.shared.setTabManager(tabManager)
        }

        Task { @MainActor in
            // Setup auto-close monitoring
            InvisibleTabAutoCloseManager.shared.setupAutoCloseForTab(
                self.tab,
                on: .EcosiaAuthStateChanged,
                timeout: self.timeout
            )

            // Register for tab close events
            register(self, forTabEvents: .didClose)
        }
    }

    private func handleTabClosed() {
        guard !isCompleted else { 
            EcosiaLogger.invisibleTabs.notice("🔐 [INVISIBLE-TAB] Tab already marked as completed: \(tab.tabUUID)")
            return 
        }
        isCompleted = true

        EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Tab closed successfully: \(tab.tabUUID)")
        EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Session transfer completed")
        
        cleanup()

        EcosiaLogger.invisibleTabs.info("🔐 [INVISIBLE-TAB] Calling completion handler with success")
        completion?(true)
    }

    private func cleanup() {
        // Cancel auto-close monitoring in InvisibleTabAutoCloseManager
        InvisibleTabAutoCloseManager.shared.cancelAutoCloseForTab(tab.tabUUID)
    }

    private func closeTab() {
        guard let browserViewController = browserViewController else {
            return
        }

        let tabManager = browserViewController.tabManager

        // Remove from invisible tracking
        InvisibleTabManager.shared.markTabAsVisible(tab)

        // Remove the tab
        tabManager.removeTab(tab) {
            EcosiaLogger.invisibleTabs.info("Tab closed: \(self.tab.tabUUID)")
        }
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

    deinit {
        cleanup()
        EcosiaLogger.invisibleTabs.debug("InvisibleTabSession deallocated")
    }
}
