// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Ecosia

struct PendingInappSearch {
    let url: URL
    /// Cleared once a response proves a document was really loaded rather than served from cache.
    var awaitingNavigationResponse = true
    /// Set when didCommit suppressed the event, so a late response can be reported as out of order.
    var suppressedAtCommit = false
}

// MARK: - Ecosia Web View Event Handling
extension BrowserViewController {

    /// Single entry point for all Ecosia-specific processing in `decidePolicyFor`.
    /// Runs vertical preservation, URL ecosification, and navigation tracking in order.
    /// Returns `true` when a replacement navigation was started — caller is responsible for
    /// calling `decisionHandler(.cancel)` and returning.
    func ecosiaDecidePolicyForNavigation(
        url: URL,
        webView: WKWebView,
        tab: Tab,
        navigationAction: WKNavigationAction
    ) -> Bool {
        guard navigationAction.targetFrame?.isMainFrame == true else { return false }
        if ecosiaApplyVerticalPreservingSearchNavigationIfNeeded(
            navigationURL: url,
            currentPageURL: webView.url ?? tab.url,
            navigationType: navigationAction.navigationType,
            tab: tab
        ) {
            return true
        }
        if ecosiaEcosifyNavigationIfNeeded(url: url, tab: tab) {
            return true
        }
        ecosiaHandleNavigationAction(url: url)
        return false
    }

    /// Handles any Ecosia-specific tracking when a navigation action is allowed.
    /// Stores a pending search to be tracked at didCommit.
    private func ecosiaHandleNavigationAction(url: URL) {
        // Clear any stale pending tracking from a previous navigation
        pendingInappSearch = nil

        guard url.isEcosiaSearchVertical() else { return }

        pendingInappSearch = PendingInappSearch(url: url)
    }

    /// Only a real document load produces a response, and only here is the status visible.
    /// A cache restore reuses the document, so web's Vue never re-mounts and sends nothing either.
    func ecosiaHandleNavigationResponse(response: URLResponse, isForMainFrame: Bool) {
        guard isForMainFrame,
              let url = response.url,
              let pending = pendingInappSearch,
              url == pending.url
        else { return }

        // The event is already gone, so all we can do is flag that the ordering assumption broke.
        if pending.suppressedAtCommit {
            EcosiaLogger.search.sentry(
                "Navigation response arrived after didCommit for \(url.redactedForLogging); in-app search event was dropped"
            )
            pendingInappSearch = nil
            return
        }

        // An error page commits without rendering the SERP, so web's Vue never mounts.
        if let statusCode = (response as? HTTPURLResponse)?.statusCode,
           !(200..<400).contains(statusCode) {
            pendingInappSearch = nil
            return
        }

        pendingInappSearch?.awaitingNavigationResponse = false
    }

    /// Fires the in-app search event when the web content starts to be received (didCommit).
    /// This matches the timing of Vue's mounted event on web (DOM ready, before full page load).
    /// - Parameters:
    ///   - url: The URL that just committed
    ///   - isPrivate: Whether the tab is in private browsing mode
    func ecosiaHandleDidCommit(url: URL, isPrivate: Bool) {
        guard let pending = pendingInappSearch, url == pending.url else { return }
        guard !pending.awaitingNavigationResponse else {
            // Kept rather than cleared so a late response is still recognisable as out of order.
            pendingInappSearch?.suppressedAtCommit = true
            return
        }
        pendingInappSearch = nil
        Analytics.shared.inappSearch(url: url, isPrivate: isPrivate)
    }

    /// Rewrites in-page SERP navigations that target the default text vertical (`/search`) so they
    /// stay on the user's active vertical (e.g. Images). Returns `nil` when navigation should proceed unchanged.
    private func ecosiaSearchURLPreservingVertical(
        navigationURL: URL,
        currentPageURL: URL?,
        navigationType: WKNavigationType
    ) -> URL? {
        guard let rewritten = navigationURL.ecosiaSearchURLPreservingVertical(from: currentPageURL) else {
            return nil
        }
        // Same-query link to `/search` is a vertical-tab switch (e.g. Web from Images), not a new search.
        if navigationType == .linkActivated,
           let currentPageURL,
           let currentQuery = currentPageURL.getEcosiaSearchQuery(),
           let newQuery = navigationURL.getEcosiaSearchQuery(),
           currentQuery == newQuery {
            return nil
        }
        return rewritten
    }

    /// Returns `true` when navigation was rewritten to preserve the active SERP vertical.
    @discardableResult
    private func ecosiaApplyVerticalPreservingSearchNavigationIfNeeded(
        navigationURL: URL,
        currentPageURL: URL?,
        navigationType: WKNavigationType,
        tab: Tab
    ) -> Bool {
        guard let rewritten = ecosiaSearchURLPreservingVertical(
            navigationURL: navigationURL,
            currentPageURL: currentPageURL,
            navigationType: navigationType
        ) else {
            return false
        }
        tab.loadRequest(URLRequest(url: rewritten))
        return true
    }

    /// Ecosifies the navigation URL if it carries an absent or outdated Snowplow user id, reloading via
    /// `tab.loadRequest()` so `ecosiaUpdatedRequest` runs. Returns `true` when a replacement was started.
    private func ecosiaEcosifyNavigationIfNeeded(url: URL, tab: Tab) -> Bool {
        let ecosified = url.ecosified(isIncognitoEnabled: tab.isPrivate)
        guard ecosified != url else { return false }
        tab.loadRequest(URLRequest(url: ecosified))
        return true
    }
}
