// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Shared
import Ecosia

// MARK: HomepageViewControllerDelegate
@MainActor
extension BrowserViewController: HomepageViewControllerDelegate {
    func homeDidTapSearchButton(_ home: HomepageViewController) {
        // Ecosia: urlBar renamed to addressToolbarContainer; use enterOverlayMode to focus search
        addressToolbarContainer.enterOverlayMode(nil, pasted: false, search: true)
    }
}

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
    /// AI search backend. Mirrors `handleAISearchSelection` in
    /// `SearchViewController+Ecosia` but loads through the active tab since
    /// the omnibox keyboard-Done path doesn't go through the search delegate.
    private func submitOmniboxAIChat(query: String) {
        guard let tab = tabManager.selectedTab else { return }
        let url = Environment.current.urlProvider
            .aiSearch(origin: .omnibox)
            .appendingQueryItems([URLQueryItem(name: "q", value: query)])
        searchTelemetry.shouldSetUrlTypeSearch = true
        finishEditingAndSubmit(url, visitType: .typed, forTab: tab)
    }

    /// Builds the search URL for a `.search`-mode omnibox submission (direct
    /// typed submit or autocomplete row tap) and loads it. Pasted URLs
    /// navigate directly; everything else goes through the default search
    /// engine with an `ar=1` parameter appended so the backend can decide
    /// whether the query lands on AI search or the standard SERP.
    /// `.aiChat` mode is handled separately by `submitOmniboxAIChat`.
    private func submitOmniboxSearch(query: String) {
        guard let tab = tabManager.selectedTab else { return }

        if let url = URIFixup.getURL(query) {
            finishEditingAndSubmit(url, visitType: .typed, forTab: tab)
            return
        }

        guard let engine = searchEnginesManager.defaultEngine,
              let baseSearchURL = engine.searchURLForQuery(query) else {
            return
        }
        let searchURL = baseSearchURL.appendingQueryItems([URLQueryItem(name: "ar", value: "1")])
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
        // Mark the session abandoned synchronously so the deferred
        // `hideOmniboxSuggestions` below — which triggers
        // `searchViewControllerWillHide` — sees the right state and routes
        // to `recordURLBarSearchAbandonmentTelemetryEvent`. A submit that
        // races in before the deferred hide runs flips the state back to
        // `.engaged`, which is exactly what we want.
        if searchSessionState == .active {
            searchSessionState = .abandoned
        }
        // The bar resigns first responder for two distinct reasons: an explicit
        // user dismissal, or the tap-outside gesture firing on a tap that's
        // actually selecting a suggestion row. Tearing the suggestions overlay
        // down synchronously kills the second case — the table view's row
        // selection gesture fires *after* the parent tap recognizer's action,
        // so by the time `didSelectRowAt` runs, the search controller has
        // already been removed from the hierarchy. Defer to the next runloop
        // so any pending row tap completes first; an explicit submit/cancel
        // hides the overlay before the deferred call lands, making it a no-op.
        DispatchQueue.main.async { [weak self] in
            self?.hideOmniboxSuggestions()
        }
    }

    private var ntpOmniboxAnchorView: NTPSearchBarView? {
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

    private func attachOmniboxSuggestions(anchorView: UIView) {
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

        // Keep the omnibox — and the floating top-right close button — above
        // the suggestions overlay.
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
        // Drag-down on the suggestions list dismisses the keyboard interactively,
        // matching the homepage collection view's behavior.
        searchController.tableView.keyboardDismissMode = .interactive
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

    private static let omniboxFastTapName = "EcosiaOmniboxSuggestionFastTap"

    @objc private func handleOmniboxFastTap(_ gesture: UITapGestureRecognizer) {
        guard let tableView = gesture.view as? UITableView,
              let indexPath = tableView.indexPathForRow(at: gesture.location(in: tableView)),
              let searchController else { return }
        // Disable further interaction so the table's own delayed selection
        // gesture doesn't re-fire `didSelectRowAt` after we've handed off to
        // the submit pipeline. Re-enabled on the next omnibox attach.
        tableView.isUserInteractionEnabled = false
        searchController.tableView(tableView, didSelectRowAt: indexPath)
    }

    private static func nearestViewController(of view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}

// MARK: DefaultBrowserDelegate
@MainActor
extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowserViewController) {
        User.shared.markDefaultBrowserSearchPromoAsShown()
    }
}

// MARK: - Default browser promo after search threshold
extension BrowserViewController {

    /// Pure eligibility check, isolated from UIKit for unit-testing.
    static func isEligibleForEcosiaDefaultBrowserSearchPromo(
        searchCount: Int,
        isDefaultBrowser: Bool,
        promoAlreadyShown: Bool
    ) -> Bool {
        guard !isDefaultBrowser else { return false }
        guard searchCount > DefaultBrowserViewController.minSearchCountToTrigger else { return false }
        guard !promoAlreadyShown else { return false }
        return true
    }

    /// Presents the default-browser promo once the search-count threshold is crossed.
    /// Safe to call repeatedly — the User flag prevents double-presentation.
    func ecosiaMaybePresentDefaultBrowserPromoForSearchThreshold() {
        guard #available(iOS 14, *) else { return }

        guard Self.isEligibleForEcosiaDefaultBrowserSearchPromo(
            searchCount: User.shared.searchCount,
            isDefaultBrowser: DefaultBrowserUtility().isDefaultBrowser,
            promoAlreadyShown: User.shared.defaultBrowserSearchPromoShown
        ) else { return }

        guard presentedViewController == nil else { return }
        guard viewIfLoaded?.window != nil else { return }

        let controller = DefaultBrowserViewController(windowUUID: windowUUID, delegate: self)
        present(controller, animated: true, completion: nil)
    }
}

// MARK: WhatsNewViewDelegate
@MainActor
extension BrowserViewController: WhatsNewViewDelegate {
    func whatsNewViewDidShow(_ viewController: WhatsNewViewController) {
        // Ecosia: whatsNewDataProvider removed in Firefox refactor; use WhatsNewLocalDataProvider to mark as seen
        WhatsNewLocalDataProvider().markPreviousVersionsAsSeen()
    }
}

// MARK: PageActionsShortcutsDelegate
@MainActor
extension BrowserViewController: PageActionsShortcutsDelegate {
    func pageOptionsOpenHome() {
        // Ecosia: tabToolbarDidPressHome/toolbar removed; focus search (home equivalent)
        addressToolbarContainer.enterOverlayMode(nil, pasted: false, search: true)
        dismiss(animated: true)
        Analytics.shared.menuClick(.home)
    }

    func pageOptionsNewTab() {
        openBlankNewTab(focusLocationField: false)
        dismiss(animated: true)
        Analytics.shared.menuClick(.newTab)
    }

    func pageOptionsSettings() {
        // Ecosia: homePanelDidRequestToOpenSettings removed; use navigationHandler.show(settings:)
        navigationHandler?.show(settings: .general)
        dismiss(animated: true)
        Analytics.shared.menuClick(.settings)
    }

    func pageOptionsShare() {
        dismiss(animated: true) {
            // Ecosia: menuHelper not in scope; use navigationHandler to show share sheet if needed
            self.navigationHandler?.showMainMenu()
        }
    }
}

// MARK: URL Bar
@MainActor
extension BrowserViewController {

    func updateURLBarFollowingPrivateModeUI() {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        addressToolbarContainer.applyUIMode(isPrivate: isPrivate, theme: themeManager.getCurrentTheme(for: windowUUID))
    }
}

// MARK: Present intro
@MainActor
extension BrowserViewController {

    func presentIntroViewController(_ alwaysShow: Bool = false) {
        if showLoadingScreen(for: .shared) {
            presentLoadingScreen()
        } else if User.shared.firstTime {
            handleFirstTimeUserActions()
        }
    }

    private func presentLoadingScreen() {
        guard let referrals = referrals else { return }
        present(LoadingScreen(profile: profile, referrals: referrals, windowUUID: windowUUID, referralCode: User.shared.referrals.pendingClaim), animated: true)
    }

    private func handleFirstTimeUserActions() {
        User.shared.firstTime = false
        User.shared.migrated = true
        User.shared.hideBookmarksImportExportTooltip()
    }

    private func showLoadingScreen(for user: User) -> Bool {
        user.referrals.pendingClaim != nil
    }
}

// MARK: Claim Referral
@MainActor
extension BrowserViewController {

    func openBlankNewTabAndClaimReferral(code: String) {
        User.shared.referrals.pendingClaim = code

        // on first start, browser is not in view hierarchy yet
        guard !User.shared.firstTime else { return }
        navigationHandler?.popToBVC()
        openURLInNewTab(nil, isPrivate: false)
        // Intro logic will trigger claiming referral
        presentIntroViewController()
    }
}

// MARK: Ecosia URL Detection and Handling
@MainActor
extension BrowserViewController {
    /// Detects Ecosia-specific URLs (auth, profile, etc.) and triggers native flows.
    /// - Returns: `true` if the URL was handled and navigation should be cancelled, `false` otherwise
    func detectAndHandleEcosiaURL(_ url: URL, for tab: Tab) -> Bool {
        guard !tab.isInvisible else { return false }

        let interceptor = EcosiaURLInterceptor()
        let interceptedType = interceptor.interceptedType(for: url)

        switch interceptedType {
        case .signUp, .signIn:
            return handleSignInAndSignUpDetection(url, tab: tab)
        case .signOut:
            return handleSignOutDetection(url)
        case .profile:
            return handleProfilePageDetection(url)
        case .none:
            return false
        }
    }

    private func handleSignInAndSignUpDetection(_ url: URL, tab: Tab) -> Bool {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for authentication detection")
            return false
        }

        if !ecosiaAuth.isLoggedIn {
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-up URL detected in navigation: \(url)")
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native authentication flow")

            ecosiaAuth
                .onNativeAuthCompleted {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native authentication completed from navigation detection")
                }
                .onAuthFlowCompleted { [weak self] success in
                    if success {
                        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete authentication flow successful from navigation")
                        // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
                        Task { @MainActor in
                            self?.tabManager.selectedTab?.reload()
                            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after successful sign-in")
                        }
                    } else {
                        EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Authentication flow completed with issues from navigation")
                    }
                }
                .onError { error in
                    EcosiaLogger.auth.error("🔐 [WEB-AUTH] Authentication failed from navigation: \(error)")
                }
                .login()
        } else {
            EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Inconsistent state detected: web thinks user is logged out but native doesn't")
            EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Failing entire process to avoid user getting locked")

            ecosiaAuth
                .onAuthFlowCompleted { _ in
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Logout completed to resolve inconsistency")
                    ecosiaAuth
                        .onAuthFlowCompleted { [weak self] success in
                            if success {
                                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Re-authentication successful after resolving inconsistency")
                                // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
                                Task { @MainActor in
                                    self?.tabManager.selectedTab?.reload()
                                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after inconsistency resolution")
                                }
                            } else {
                                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Re-authentication failed after resolving inconsistency")
                            }
                        }
                        .onError { error in
                            EcosiaLogger.auth.error("🔐 [WEB-AUTH] Re-authentication error after resolving inconsistency: \(error)")
                        }
                        .login()
                }
                .onError { error in
                    EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed while resolving inconsistency: \(error)")
                }
                .logout()
        }

        return true
    }

    private func handleSignOutDetection(_ url: URL) -> Bool {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for sign-out detection")
            return false
        }

        // Always perform logout on web-triggered sign-out to clear inconsistent state
        if !ecosiaAuth.isLoggedIn {
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] User already logged out, but we perform logout anyways to clear inconsistent state for: \(url) as if it's triggered, it means the User sees the page and clicks logout. It may happen sometimes. Noticed especially on iPad.")
        }

        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-out URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native logout flow")

        ecosiaAuth
            .onNativeAuthCompleted {
                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native logout completed from navigation detection")
            }
            .onAuthFlowCompleted { [weak self] success in
                if success {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete logout flow successful from navigation")
                    // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
                    Task { @MainActor in
                        self?.tabManager.selectedTab?.reload()
                        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after successful sign-out")
                    }
                } else {
                    EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Logout flow completed with issues from navigation")
                }
            }
            .onError { error in
                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed from navigation: \(error)")
            }
            .logout()

        return true
    }

    private func handleProfilePageDetection(_ url: URL) -> Bool {
        EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Profile URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Opening native profile modal")
        // Ecosia: Task { @MainActor in } instead of DispatchQueue.main.async for strict concurrency
        Task { @MainActor in
            self.presentProfileModal()
        }
        return true
    }
}

// MARK: Profile Modal Presentation
@MainActor
extension BrowserViewController {
    /// Presents the profile page as a modal, similar to EcosiaAccountImpactView
    func presentProfileModal() {
        guard #available(iOS 16.0, *) else {
            EcosiaLogger.auth.notice("Profile modal requires iOS 16.0+")
            return
        }

        let profileView = EcosiaWebViewModal(
            url: Environment.current.urlProvider.profileURL,
            windowUUID: windowUUID,
            userAgent: UserAgentBuilder.defaultMobileUserAgent().userAgent(),
            onLoadComplete: {
                Analytics.shared.accountProfileViewed()
            },
            onDismiss: {
                Analytics.shared.accountProfileDismissed()
            }
        )

        let hostingController = UIHostingController(rootView: profileView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [UISheetPresentationController.Detent.large()]
            sheet.prefersGrabberVisible = true
        }

        present(hostingController, animated: true) {
            EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Profile modal presented successfully")
        }
    }
}
