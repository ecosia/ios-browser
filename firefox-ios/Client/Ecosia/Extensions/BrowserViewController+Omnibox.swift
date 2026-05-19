// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Ecosia

// MARK: NTPSearchBarDelegate
// Ecosia: Routes the embedded NTP omnibox into the existing browser navigation
// pipeline. Submission goes through the same URIFixup → load/search path as the
// standard toolbar; live keystrokes feed the shared suggestions overlay.
@MainActor
extension BrowserViewController: NTPSearchBarDelegate {
    func ntpSearchBarDidSubmit(_ searchTerm: String, mode: NTPSearchBarSubmitMode) {
        // Mark the session engaged before tearing down the suggestions so the
        // existing `searchViewControllerWillHide` → `recordURLBarSearchEngagementTelemetryEvent`
        // pipeline records the omnibox submit the same way the URL bar would.
        searchSessionState = .engaged
        hideOmniboxSuggestions()
        // Clear the omnibox so the user returns to a fresh pill next time the
        // homepage is shown — the submitted query lives on the SERP, not in
        // the input.
        if let bar = ntpOmniboxAnchorView {
            bar.text = ""
            _ = bar.resignFirstResponder()
        }
        switch mode {
        case .search:
            submitOmniboxSearch(query: searchTerm)
        case .aiChat:
            submitOmniboxAIChat(query: searchTerm)
        }
        // Force the swap to the webview. Without URL bar overlay mode, the
        // standard `addressToolbar(_:didLeaveOverlayModeForReason:)` chain
        // — which is what normally calls `showEmbeddedWebview()` — never fires.
        showEmbeddedWebview()
    }

    /// Routes a long-prompt submit (above the omnibox AI threshold) into the
    /// AI search backend. Mirrors `handleAIChatSelection` in
    /// `SearchViewController+Ecosia` but loads through the active tab since
    /// the omnibox keyboard-Done path doesn't go through the search delegate.
    private func submitOmniboxAIChat(query: String) {
        guard let tab = tabManager.selectedTab else { return }
        let url = Environment.current.urlProvider.aiChat(origin: .omnibox, query: query)
        searchTelemetry.shouldSetUrlTypeSearch = true
        finishEditingAndSubmit(url, visitType: .typed, forTab: tab)
    }

    /// Builds the search URL for a `.search`-mode omnibox submission (direct
    /// typed submit or autocomplete row tap) and loads it. Pasted URLs
    /// navigate directly; everything else goes through Ecosia's `urlProvider`
    /// via `URL.ecosiaSearchWithQuery` with `autoRedirect: true`, which
    /// appends the `ar=1` parameter so the backend can decide whether the
    /// query lands on AI search or the standard SERP.
    /// `.aiChat` mode is handled separately by `submitOmniboxAIChat`.
    private func submitOmniboxSearch(query: String) {
        guard let tab = tabManager.selectedTab else { return }

        if let url = URIFixup.getURL(query) {
            finishEditingAndSubmit(url, visitType: .typed, forTab: tab)
            return
        }

        let searchURL = URL.ecosiaSearchWithQuery(query, autoRedirect: true)
        finishEditingAndSubmit(searchURL, visitType: .typed, forTab: tab)
    }

    func ntpSearchBarTextDidChange(_ searchTerm: String) {
        guard let anchor = ntpOmniboxAnchorView else { return }
        if searchTerm.isEmpty {
            hideOmniboxSuggestions()
            return
        }
        if anchor.isMultiline {
            // Past two lines the suggestions rows aren't useful anymore, but
            // we keep the overlay attached so its colored background stays
            // visible behind the pill (only the table content is hidden).
            ensureOmniboxSuggestionsAttached(anchorView: anchor)
            searchController?.tableView.isHidden = true
            return
        }
        searchController?.tableView.isHidden = false
        showOmniboxSuggestions(searchTerm: searchTerm, anchorView: anchor)
    }

    /// Attaches the suggestions overlay (creating the search controller if
    /// needed) without populating its query — used for the multi-line state
    /// where we want the background visible but no rows.
    private func ensureOmniboxSuggestionsAttached(anchorView: UIView & Autocompletable) {
        createSearchControllerIfNeeded()
        guard let searchController else { return }
        searchLoader?.autocompleteView = anchorView
        if searchController.parent == nil {
            attachOmniboxSuggestions(anchorView: anchorView)
        }
    }

    func ntpSearchBarDidBeginEditing() {
        // Mark the session active the moment the omnibox gains focus so an
        // abandoned focus (no text entered) is recorded the same way the URL
        // bar tracks it via `addressToolbarDidBeginEditing`. The state is
        // otherwise only set lazily inside `createSearchControllerIfNeeded`,
        // which runs on first keystroke and would miss focus-only sessions.
        searchSessionState = .active
    }

    func ntpSearchBarDidCancel() {
        // Mark the session abandoned synchronously so the eventual overlay
        // teardown — which triggers `searchViewControllerWillHide` — sees
        // the right state and routes to
        // `recordURLBarSearchAbandonmentTelemetryEvent`. A submit that races
        // in flips the state back to `.engaged`, which is exactly what we
        // want. Note: this callback intentionally does NOT hide the overlay
        // any more. A keyboard drag-dismiss resigns the textView too, and
        // tearing the suggestions down there would kill the whole point of
        // letting the user swipe the keyboard away to read the full list.
        // The explicit dismiss paths (`ntpSearchBarRequestsOverlayDismiss`,
        // submit, suggestion-row selection, text-cleared) handle teardown.
        if searchSessionState == .active {
            searchSessionState = .abandoned
        }
    }

    func ntpSearchBarRequestsOverlayDismiss() {
        // Defer to the next runloop so a tap-outside that's actually a
        // suggestion-row tap can complete its `didSelectRowAt` before the
        // table is removed from the hierarchy — an explicit submit/select
        // hides the overlay before the deferred call lands, making it a
        // no-op.
        DispatchQueue.main.async { [weak self] in
            self?.hideOmniboxSuggestions()
        }
    }

    fileprivate var ntpOmniboxAnchorView: NTPSearchBarView? {
        (contentContainer.contentController as? HomepageViewController)?.ntpSearchBar
    }
}

// MARK: - Omnibox suggestions overlay
// Ecosia: Bridges the NTP-embedded omnibox to the existing search suggestions
// stack. Reuses `SearchViewController` and `SearchLoader` rather than duplicating
// them, but anchors the overlay above the omnibox instead of the hidden URL bar.
@MainActor
extension BrowserViewController {

    /// Shows (or refreshes) the suggestions overlay for the supplied query.
    /// Empty query hides the overlay. While the omnibox drives suggestions,
    /// autocomplete is routed into the omnibox itself instead of the URL bar.
    func showOmniboxSuggestions(searchTerm: String, anchorView: UIView & Autocompletable) {
        guard !searchTerm.isEmpty else {
            hideOmniboxSuggestions()
            return
        }

        createSearchControllerIfNeeded()
        guard let searchController else { return }

        searchLoader?.autocompleteView = anchorView

        if searchController.parent == nil {
            attachOmniboxSuggestions(anchorView: anchorView)
        }

        searchController.viewModel.searchQuery = searchTerm
        searchController.searchTelemetry?.searchQuery = searchTerm
        searchController.searchTelemetry?.clearVisibleResults()
        searchController.searchTelemetry?.determineInteractionType()
        searchLoader?.query = searchTerm
    }

    /// Tears down the suggestions overlay when the omnibox loses content/focus
    /// and routes autocomplete back to the standard URL bar.
    func hideOmniboxSuggestions() {
        searchLoader?.autocompleteView = addressToolbarContainer
        guard searchController?.parent != nil else { return }
        hideSearchController()
    }

    fileprivate func attachOmniboxSuggestions(anchorView: UIView) {
        guard let searchController else { return }
        // The overlay must live inside the homepage view's hierarchy so the
        // omnibox (a sibling there) can sit on top of it in z-order. UIKit
        // requires the parent VC to match the view tree, so parent the search
        // controller to the homepage VC — not BVC — to avoid
        // UIViewControllerHierarchyInconsistency.
        guard let host = anchorView.superview,
              let hostVC = Self.nearestViewController(of: host) else { return }

        hostVC.addChild(searchController)
        host.addSubview(searchController.view)
        searchController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchController.view.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor),
            searchController.view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            searchController.view.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])

        // z-order back→front: suggestions overlay, focused-state scrim,
        // omnibox pill, floating close button. The scrim sits above the
        // suggestions so the bottom of the list fades into the pill, but
        // below the pill itself so the pill stays fully opaque.
        if let homepage = hostVC as? HomepageViewController,
           let backdrop = homepage.ntpSearchBarBackdrop {
            host.bringSubviewToFront(backdrop)
        }
        host.bringSubviewToFront(anchorView)
        if let homepage = hostVC as? HomepageViewController,
           let closeButton = homepage.ntpOmniboxCloseButton {
            host.bringSubviewToFront(closeButton)
            // Push the table content down below the close button so the first
            // suggestion isn't drawn underneath it. The view itself still
            // spans the safe area, so the keyboard-tracking footer stays put.
            host.layoutIfNeeded()
            let topInset = closeButton.frame.maxY - host.safeAreaInsets.top
            searchController.additionalSafeAreaInsets.top = max(0, topInset)
        }

        searchController.didMove(toParent: hostVC)
        contentContainer.accessibilityElementsHidden = true

        // Re-enable interaction in case the previous attach left the table
        // disabled by the fast-tap path below.
        searchController.tableView.isUserInteractionEnabled = true
        // Any drag on the suggestions list dismisses the keyboard so the user
        // can scan the full list. Resigning the textView's first responder
        // from this path fires `ntpSearchBarDidCancel`, which intentionally
        // no longer tears down the overlay — so the suggestions stay visible.
        searchController.tableView.keyboardDismissMode = .onDrag
        installOmniboxFastTap(on: searchController.tableView)
    }

    /// Adds a tap gesture on the suggestions table that fires `didSelectRowAt`
    /// the instant a touch ends, instead of waiting for `UIScrollView`'s
    /// ~150ms `delaysContentTouches` gate. Without this, suggestion taps lag
    /// noticeably behind the keyboard-return submit path (which doesn't go
    /// through the scroll view at all).
    private func installOmniboxFastTap(on tableView: UITableView) {
        if tableView.gestureRecognizers?.contains(where: { $0.name == Self.omniboxFastTapName }) == true {
            return
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleOmniboxFastTap(_:)))
        tap.name = Self.omniboxFastTapName
        // Let the touch flow through to the table so cell highlight/scroll
        // gestures still see it; we disable user interaction below to stop
        // the table's own delayed selection from firing a second time.
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }

    fileprivate static let omniboxFastTapName = "EcosiaOmniboxSuggestionFastTap"

    @objc fileprivate func handleOmniboxFastTap(_ gesture: UITapGestureRecognizer) {
        guard let tableView = gesture.view as? UITableView,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)),
              let searchController else { return }
        // Disable further interaction so the table's own delayed selection
        // gesture doesn't re-fire `didSelectRowAt` after we've handed off to
        // the submit pipeline. Re-enabled on the next omnibox attach.
        tableView.isUserInteractionEnabled = false
        searchController.tableView(tableView, didSelectRowAt: indexPath)
    }

    fileprivate static func nearestViewController(of view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}
