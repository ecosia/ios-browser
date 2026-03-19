// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Ecosia

// MARK: - Ecosia Web View Event Handling
extension BrowserViewController {

    /// Handles any Ecosia-specific tracking when a navigation action is allowed.
    /// Stores a pending URL to be tracked at didCommit.
    /// - Parameters:
    ///   - url: The URL being navigated to
    ///   - navigationAction: The navigation action that triggered this check
    func ecosiaHandleNavigationAction(url: URL, navigationAction: WKNavigationAction) {
        // Clear any stale pending tracking from a previous navigation
        pendingInappSearchUrl = nil

        guard url.isEcosiaSearchVertical() else { return }

        // Back/forward navigations are suppressed: on web, bfcache keeps the page mounted so
        // Vue never refires. Tab switching doesn't reach this delegate at all, so any other
        // navigation type arriving here is a genuine user action and should always track.
        guard navigationAction.navigationType != .backForward else { return }

        // Store the URL; the event fires in ecosiaHandleDidCommit when content starts rendering
        pendingInappSearchUrl = url
    }

    /// Fires the in-app search event when the web content starts to be received (didCommit).
    /// This matches the timing of Vue's mounted event on web (DOM ready, before full page load).
    /// - Parameter url: The URL that just committed
    func ecosiaHandleDidCommit(url: URL) {
        guard url == pendingInappSearchUrl else { return }
        pendingInappSearchUrl = nil
        Analytics.shared.inappSearch(url: url)
    }

    /// Handles any tasks that should run after a page finishes loading.
    /// - Parameter url: The URL that finished loading
    func ecosiaHandlePageLoadCompletion(url: URL) {
        if ProductTourManager.shared.isInProductTour {
            if url.isEcosiaSearchVertical() {
                ProductTourManager.shared.completeFirstSearchIfNeeded()
            } else if url.isBrowser() && !url.isEcosia() {
                ProductTourManager.shared.completeExternalWebsiteVisitIfNeeded()
            }
        }
    }
}
