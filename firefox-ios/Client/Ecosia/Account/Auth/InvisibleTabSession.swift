// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Ecosia
import Common

/// Encapsulates an invisible tab session with its monitoring and cleanup
/// Single responsibility: manage one invisible tab through its complete lifecycle
final class InvisibleTabSession: TabEventHandler {

    // MARK: - Properties

    private let tab: Tab
    private let startURL: URL
    private let timeout: TimeInterval
    private let landingSettleDelay: TimeInterval
    private weak var browserViewController: BrowserViewController?

    // State
    private var isCompleted = false
    private var completion: ((Bool) -> Void)?
    // Tracked live via KVO (see init) instead of read from tab.webView?.url at close time -
    // tabManager.removeTab has usually already torn down the webview by the time handleTabClosed()
    // runs, so tab.webView?.url would read back nil there.
    private var lastKnownURL: URL?
    private var urlObservation: NSKeyValueObservation?
    private var pendingLandingClose: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates an invisible tab session
    /// - Parameters:
    ///   - url: URL to load in the tab
    ///   - browserViewController: Browser view controller for tab operations
    ///   - timeout: Fallback timeout for completion
    ///   - landingSettleDelay: Grace period after a page finishes, so a JS or form-post redirect
    ///     can start the next load before we close
    init(url: URL,
         browserViewController: BrowserViewController,
         timeout: TimeInterval = 10.0,
         landingSettleDelay: TimeInterval = 0.5) throws {
        self.startURL = url
        self.browserViewController = browserViewController
        self.timeout = timeout
        self.landingSettleDelay = landingSettleDelay

        // Create the tab immediately
        self.tab = try Self.createInvisibleTab(url: url, browserViewController: browserViewController)
        self.lastKnownURL = url

        EcosiaLogger.invisibleTabs.info("InvisibleTabSession created for: \(url)")

        // Ecosia: Attach as early as possible (not in startMonitoring) to avoid missing a fast
        // redirect chain that finishes before monitoring starts.
        urlObservation = tab.webView?.observe(\.url, options: [.initial, .new]) { [weak self] _, change in
            guard let newURL = change.newValue ?? nil else { return }
            Task { @MainActor in
                self?.lastKnownURL = newURL
            }
        }
    }

    // MARK: - Session Management

    /// Installs the SSO session cookie into the shared non-private cookie store.
    ///
    /// Must finish before the session's tab exists: creating the tab starts the transfer load
    /// immediately, and a load that beats the cookie authenticates nothing and lands back on sign-in.
    @MainActor
    static func installSessionCookie(from authService: Ecosia.EcosiaAuthenticationService) async {
        guard let sessionCookie = authService.getSessionTokenCookie() else {
            EcosiaLogger.cookies.notice("No session cookie available for tab")
            return
        }

        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().httpCookieStore.setCookie(sessionCookie) {
                continuation.resume()
            }
        }
        EcosiaLogger.cookies.info("Session cookie installed for session transfer")
    }

    /// Starts monitoring for session completion (page load + auth)
    /// - Parameter completion: Called when session completes or times out
    func startMonitoring(_ completion: @escaping (Bool) -> Void) {
        self.completion = completion

        setupTabAutoCloseManager()

        EcosiaLogger.invisibleTabs.info("Starting session monitoring: \(tab.tabUUID)")
    }

    // MARK: - Private Implementation

    /// Marks the tab invisible before adding it: adding inserts the tab and notifies tab manager delegates,
    /// and the iPad top tabs insert whatever `didAddTab` hands them, so marking afterwards flashes the
    /// auth tab in the tab strip.
    private static func createInvisibleTab(url: URL, browserViewController: BrowserViewController) throws -> Tab {
        let tabManager = browserViewController.tabManager

        let newTab = Tab(profile: browserViewController.profile, isPrivate: false, windowUUID: tabManager.windowUUID)
        newTab.isInvisible = true
        tabManager.addTab(newTab, request: URLRequest(url: url))

        EcosiaLogger.invisibleTabs.info("Invisible tab created: \(newTab.tabUUID)")
        return newTab
    }

    private func setupTabAutoCloseManager() {
        guard let tabManager = browserViewController?.tabManager else { return }
        let tabUUID = tab.tabUUID
        let timeout = timeout

        Task { @MainActor in
            InvisibleTabAutoCloseManager.shared.setupAutoCloseForTab(
                tabUUID: tabUUID,
                in: tabManager,
                on: .EcosiaAuthStateChanged,
                timeout: timeout
            )
            // One call for both events: a second register call on the same object drops the first one's observers
            register(self, forTabEvents: .didClose, .didChangeURL)
            if !tab.isLoading, let lastKnownURL {
                scheduleCloseIfLanded(on: lastKnownURL)
            }
        }
    }

    private func scheduleCloseIfLanded(on pageURL: URL) {
        // A newer page supersedes any close still waiting on an earlier one
        pendingLandingClose?.cancel()
        pendingLandingClose = nil

        // The tab has already closed, by this or the fallback timeout
        guard !isCompleted else { return }

        // Auth0 hops happen on login.<domain>, not the web host
        guard pageURL.host == urlProvider.root.host else { return }

        // An error page ends the flow, even when the session started on it
        let isErrorPage = pageURL.isEcosiaErrorPage(urlProvider)
        // The start page is still handing off to Auth0
        let hasLeftStartPage = pageURL.path.lowercased() != startURL.path.lowercased()
        // Sign-in can still hand off to Auth0 client-side
        let isSignIn = EcosiaURLInterceptor(urlProvider: urlProvider).interceptedType(for: pageURL) == .signIn
        guard isErrorPage || (hasLeftStartPage && !isSignIn) else { return }

        let tabUUID = tab.tabUUID
        let landingSettleDelay = landingSettleDelay
        pendingLandingClose = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(landingSettleDelay * 1_000_000_000))
            // Loading again means a redirect started after this page finished
            guard let self, !Task.isCancelled, !self.tab.isLoading else { return }
            EcosiaLogger.invisibleTabs.info("Invisible tab landed on: \(pageURL.redactedForLogging)")
            InvisibleTabAutoCloseManager.shared.closeTrackedTab(tabUUID)
        }
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
        let signInPath = urlProvider.signInURL.relativePath.lowercased()

        return !(finalURL.isEcosiaErrorPage(urlProvider) || path.hasPrefix(signInPath))
    }

    private var urlProvider: URLProvider {
        EcosiaEnvironment.current.urlProvider
    }

    private func cleanup() {
        pendingLandingClose?.cancel()
        pendingLandingClose = nil
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

    /// Posted when a page finishes loading, and on title or same-origin URL changes
    func tab(_ tab: Tab, didChangeURL url: URL) {
        guard tab.tabUUID == self.tab.tabUUID else { return }
        scheduleCloseIfLanded(on: url)
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
