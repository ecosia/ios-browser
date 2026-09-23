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
    // Tracked live via KVO (see init) instead of read from tab.webView?.url at close time -
    // tabManager.removeTab has usually already torn down the webview by the time handleTabClosed()
    // runs, so tab.webView?.url would read back nil there.
    private var lastKnownURL: URL?
    private var urlObservation: NSKeyValueObservation?
    private var loadingObservation: NSKeyValueObservation?
    private var isMonitoring = false
    private var pendingLandingClose: Task<Void, Never>?

    /// Grace period after loading stops, so a JS or form-post redirect can start the next load before we close.
    static let landingSettleDelay: TimeInterval = 0.5

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
        self.lastKnownURL = url

        EcosiaLogger.invisibleTabs.info("InvisibleTabSession created for: \(url)")

        // Ecosia: Attach as early as possible (not in startMonitoring) to avoid missing a fast
        // redirect chain that finishes before monitoring starts.
        urlObservation = tab.webView?.observe(\.url, options: [.new]) { [weak self] _, change in
            guard let newURL = change.newValue ?? nil else { return }
            Task { @MainActor in
                self?.lastKnownURL = newURL
            }
        }
        loadingObservation = tab.webView?.observe(\.isLoading, options: [.new]) { [weak self] _, change in
            let isLoading = change.newValue ?? false
            Task { @MainActor in
                self?.handleLoadingChanged(isLoading: isLoading)
            }
        }
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
            isMonitoring = true
            handleLoadingChanged(isLoading: tab.isLoading)
        }
    }

    private func handleLoadingChanged(isLoading: Bool) {
        pendingLandingClose?.cancel()
        pendingLandingClose = nil

        guard isMonitoring, !isCompleted, !isLoading,
              let currentURL = lastKnownURL,
              Self.hasLanded(on: currentURL, from: url, urlProvider: urlProvider) else { return }

        let tabUUID = tab.tabUUID
        pendingLandingClose = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Self.landingSettleDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            EcosiaLogger.invisibleTabs.info("Invisible tab landed on: \(currentURL.redactedForLogging)")
            InvisibleTabAutoCloseManager.shared.closeTrackedTab(tabUUID)
        }
    }

    /// Done once resting on a www page other than the start page; Auth0 hops happen on another host.
    /// Sign-in is excluded because it can hand off to Auth0 client-side, so a pause there isn't final.
    static func hasLanded(on currentURL: URL, from startURL: URL, urlProvider: URLProvider) -> Bool {
        guard currentURL.host == urlProvider.root.host else { return false }
        let path = currentURL.path.lowercased()
        return path != startURL.path.lowercased() && !path.hasPrefix(urlProvider.signInURL.path.lowercased())
    }

    private func handleTabClosed() {
        guard !isCompleted else { return }
        isCompleted = true

        cleanup()

        let success = isSessionTransferSuccessful()
        if !success {
            EcosiaLogger.auth.sentry("Session transfer landed on a failure path: \(lastKnownURL?.redactedForLogging ?? "nil")")
        }
        EcosiaLogger.invisibleTabs.info("Session completed for tab: \(tab.tabUUID), success: \(success)")
        // Ensure completion is called on main for strict concurrency (caller may update UI).
        let completionToCall = completion
        completion = nil
        if let completionToCall = completionToCall {
            Task { @MainActor in
                completionToCall(success)
            }
        }
    }

    /// Classifies the invisible tab's final URL as success or failure: landing on the accounts error page, or being redirected
    /// back to sign-in, means the transfer didn't actually authenticate the web session, even though the tab closed normally.
    private func isSessionTransferSuccessful() -> Bool {
        guard let finalURL = lastKnownURL, finalURL.isEcosia(urlProvider) else { return true }

        let path = finalURL.path.lowercased()
        let errorPaths = urlProvider.errorPaths.map { $0.lowercased() }
        let signInPath = urlProvider.signInURL.relativePath.lowercased()

        return !(errorPaths.contains(path) || path.hasPrefix(signInPath))
    }

    private var urlProvider: URLProvider {
        EcosiaEnvironment.current.urlProvider
    }

    private func cleanup() {
        pendingLandingClose?.cancel()
        pendingLandingClose = nil
        loadingObservation = nil
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

        // TabManager protocol has removeTab(_ tabUUID: TabUUID) with no completion
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

    /// Don't call cleanup() from deinit — cleanup() is main-actor/actor-isolated. Callers must ensure cleanup when session ends (e.g. handleTabClosed).
    deinit {
        EcosiaLogger.invisibleTabs.debug("InvisibleTabSession deallocated")
    }
}
