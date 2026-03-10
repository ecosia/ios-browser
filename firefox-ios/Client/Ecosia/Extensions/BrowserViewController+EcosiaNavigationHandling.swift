// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Ecosia

// MARK: - Ecosia Web View Event Handling
extension BrowserViewController {

    /// Handles any Ecosia-specific tracking when a navigation action is allowed.
    /// - Parameters:
    ///   - url: The URL being navigated to
    ///   - navigationAction: The navigation action that triggered this check
    ///   - previousUrl: The previously loaded URL for comparison
    /// - Returns: The URL to set as the new previousUrl
    func ecosiaHandleNavigationAction(
        url: URL,
        navigationAction: WKNavigationAction,
        previousUrl: URL?
    ) -> URL {
        guard url.isEcosiaSearchVertical() else {
            return url
        }

        // Only process if not navigating back/forward and either URL changed or it's a reload
        let urlChanged = url != previousUrl
        let isReload = navigationAction.navigationType == .reload
        let isBackForward = navigationAction.navigationType == .backForward
        guard !isBackForward && (urlChanged || isReload) else {
            return url
        }

        Analytics.shared.inappSearch(url: url)

        return url
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
