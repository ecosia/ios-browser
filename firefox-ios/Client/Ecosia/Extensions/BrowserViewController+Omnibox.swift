// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Ecosia
import WebKit

// MARK: NTPSearchBarDelegate
// Ecosia: Routes the embedded NTP omnibox into the existing browser navigation
// pipeline. Submission goes through the same URIFixup → load/search path as the
// standard toolbar; live keystrokes feed the shared suggestions overlay.
@MainActor
extension BrowserViewController: NTPSearchBarDelegate {
    func ntpSearchBarDidSubmit(_ searchTerm: String) {
        // Mark the session engaged before tearing down the suggestions so the
        // existing `searchViewControllerWillHide` → `recordURLBarSearchEngagementTelemetryEvent`
        // pipeline records the omnibox submit the same way the URL bar would.
        searchSessionState = .engaged
        hideOmniboxSuggestions()
        let chatFiles = ntpOmniboxAnchorView?.readyChatFiles() ?? []
        // Clear the omnibox so the user returns to a fresh pill next time the
        // homepage is shown — the submitted query lives on the SERP, not in
        // the input.
        if let bar = ntpOmniboxAnchorView {
            bar.text = ""
            omniboxAttachmentCoordinator.clearAttachments()
            _ = bar.resignFirstResponder()
        }

        if !chatFiles.isEmpty {
            guard let tab = tabManager.selectedTab else { return }
            let cookieStore = tab.webView?.configuration.websiteDataStore.httpCookieStore
            Task { @MainActor [weak self] in
                guard let self else { return }
                await CloudflareAccessCookieBootstrap.syncAuthorizationCookieToWebView(
                    cookieStore: cookieStore ?? WKWebsiteDataStore.default().httpCookieStore
                )
                submitOmniboxSearch(query: searchTerm, chatFiles: chatFiles, tab: tab)
                showEmbeddedWebview(for: tab)
            }
            return
        }

        submitOmniboxSearch(query: searchTerm, chatFiles: chatFiles)
        // Force the swap to the webview. Without URL bar overlay mode, the
        // standard `addressToolbar(_:didLeaveOverlayModeForReason:)` chain
        // — which is what normally calls `showEmbeddedWebview()` — never fires.
        showEmbeddedWebview()
    }

    /// Builds the navigation URL for an omnibox submission.
    /// Pasted URLs navigate directly only when there are no attachments.
    /// Queries with attachments always open AI chat with the uploaded `files` metadata.
    /// Otherwise the query goes through Ecosia search with `ar=1` so the backend can decide
    /// between AI search and the standard SERP.
    private func submitOmniboxSearch(query: String, chatFiles: [AIChatFileQuery] = [], tab: Tab? = nil) {
        guard let tab = tab ?? tabManager.selectedTab else { return }
        let destinationURL = OmniboxSubmitRouting.destinationURL(query: query, chatFiles: chatFiles)

        if !chatFiles.isEmpty {
            EcosiaLogger.network.info(
                "[Omnibox] Routing to AI chat (files=\(chatFiles.count), host=\(destinationURL.host ?? "unknown"))"
            )
        }

        finishEditingAndSubmit(destinationURL, visitType: .typed, forTab: tab)
    }

    func ntpSearchBarTextDidChange(_ searchTerm: String) {
        guard let anchor = ntpOmniboxAnchorView else { return }
        if anchor.hasAttachments {
            hideOmniboxSuggestions()
            return
        }
        if searchTerm.isEmpty {
            hideOmniboxSuggestions()
            return
        }
        showOmniboxSuggestions(searchTerm: searchTerm, anchorView: anchor)
    }

    func ntpSearchBarAttachmentsDidChange() {
        guard let anchor = ntpOmniboxAnchorView else { return }
        if anchor.hasAttachments {
            hideOmniboxSuggestions()
        } else if !anchor.text.isEmpty {
            let searchTerm = anchor.normalizedSearchQuery(for: anchor.text)
            showOmniboxSuggestions(searchTerm: searchTerm, anchorView: anchor)
        }
    }

    func ntpSearchBarNeedsSearchReset() {
        searchLoader?.query = ""
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

    func ntpSearchBarIsSuggestionsOverlayVisible() -> Bool {
        searchController?.parent is HomepageViewController
    }

    func ntpSearchBarNeedsSuggestionsLayoutUpdate() {
        updateOmniboxSuggestionsScrollInsets()
    }

    func ntpSearchBarDidTapUpload() {
        guard FileUploadFeatureFlag.isEnabled else { return }
        _ = ntpOmniboxAnchorView?.resignFirstResponder()
        let isLoggedIn = ecosiaAuth?.isLoggedIn == true
        let hasUploadScopes = EcosiaAuthenticationService.shared.hasConversationScopes
        if !isLoggedIn || !hasUploadScopes {
            if #available(iOS 16.0, *), !AccountsDisabled.isActive {
                presentOmniboxSignInSheetForUpload()
            } else {
                guard let auth = ecosiaAuth else { return }
                auth
                    .onAuthFlowCompleted { [weak self] success in
                        guard success else { return }
                        self?.presentOmniboxUploadDrawer()
                    }
                    .onError { _ in }
                    .login()
            }
            return
        }
        presentOmniboxUploadDrawer()
    }

    fileprivate func configureOmniboxUploadAuthCallbacks(
        auth: EcosiaAuth,
        sheetState: NTPOmniboxSheetState?
    ) -> EcosiaAuth {
        auth
            .onAuthFlowCompleted { [weak sheetState] success in
                sheetState?.handleAuthenticationCompleted(success: success)
            }
            .onError { [weak sheetState] _ in
                sheetState?.handleAuthenticationCompleted(success: false)
            }
    }

    fileprivate func presentOmniboxSignInSheetForUpload() {
        guard let homepage = contentContainer.contentController as? HomepageViewController,
              let sheetState = homepage.ecosiaAdapter?.omniboxSheetState else { return }

        homepage.presentOmniboxUploadSheetIfNeeded()
        sheetState.presentSignInSheetForUpload(
            onSignIn: { [weak self, weak sheetState] in
                guard let self, let auth = self.ecosiaAuth else { return }
                self.configureOmniboxUploadAuthCallbacks(auth: auth, sheetState: sheetState).login()
            },
            onSignUp: { [weak self, weak sheetState] in
                guard let self, let auth = self.ecosiaAuth else { return }
                self.configureOmniboxUploadAuthCallbacks(auth: auth, sheetState: sheetState).signUp()
            },
            onUploadDrawerRequested: { [weak self] in
                self?.presentOmniboxUploadDrawer()
            }
        )
    }

    fileprivate var ntpOmniboxAnchorView: NTPSearchBarView? {
        let bar = (contentContainer.contentController as? HomepageViewController)?.ntpSearchBar
        bar?.onRemoveAttachment = { [weak self] id in
            self?.omniboxAttachmentCoordinator.removeAttachment(id: id)
        }
        return bar
    }

    fileprivate var omniboxAttachmentCoordinator: OmniboxAttachmentUploadCoordinator {
        if let coordinator = objc_getAssociatedObject(self, &OmniboxUploadAssociatedKeys.attachmentCoordinator)
            as? OmniboxAttachmentUploadCoordinator {
            coordinator.searchBar = ntpOmniboxAnchorView
            return coordinator
        }
        let coordinator = OmniboxAttachmentUploadCoordinator()
        coordinator.delegate = self
        coordinator.searchBar = ntpOmniboxAnchorView
        objc_setAssociatedObject(self,
                                 &OmniboxUploadAssociatedKeys.attachmentCoordinator,
                                 coordinator,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return coordinator
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
        updateOmniboxSuggestionsScrollInsets()
    }

    /// Tears down the suggestions overlay when the omnibox loses content/focus
    /// and routes autocomplete back to the standard URL bar.
    func hideOmniboxSuggestions() {
        searchLoader?.autocompleteView = addressToolbarContainer
        if let searchController {
            // Restore the modal accessibility scope set in attachOmniboxSuggestions.
            searchController.view.superview?.accessibilityViewIsModal = false
            UIAccessibility.post(notification: .screenChanged, argument: nil)
            searchController.additionalSafeAreaInsets = .zero
            let tableView = searchController.tableView
            tableView.contentInset = .zero
            tableView.verticalScrollIndicatorInsets = .zero
            tableView.contentInsetAdjustmentBehavior = .automatic
            tableView.isUserInteractionEnabled = true
            tableView.keyboardDismissMode = .none
            removeOmniboxFastTap(from: tableView)
        }
        guard searchController?.parent != nil else { return }
        hideSearchController()
    }

    fileprivate static let omniboxSuggestionsClearance: CGFloat = .ecosia.space._1s

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
        // omnibox pill. The scrim sits above the suggestions so the bottom
        // of the list fades into the pill, but below the pill itself so the
        // pill stays fully opaque.
        if let homepage = hostVC as? HomepageViewController,
           let backdrop = homepage.ntpSearchBarBackdrop {
            host.bringSubviewToFront(backdrop)
        }
        host.bringSubviewToFront(anchorView)

        searchController.didMove(toParent: hostVC)
        updateOmniboxSuggestionsScrollInsets()
        // Scope VoiceOver to the omnibox host so background NTP content is unreachable,
        // without hiding contentContainer (which would also hide the suggestions inside it).
        // Restored in hideOmniboxSuggestions.
        host.accessibilityViewIsModal = true
        UIAccessibility.post(notification: .screenChanged, argument: searchController.tableView)

        // Re-enable interaction in case the previous attach left the table
        // disabled by the fast-tap path below.
        searchController.tableView.isUserInteractionEnabled = true
        searchController.tableView.contentInsetAdjustmentBehavior = .never
        // Any drag on the suggestions list dismisses the keyboard so the user
        // can scan the full list. Resigning the textView's first responder
        // from this path fires `ntpSearchBarDidCancel`, which intentionally
        // no longer tears down the overlay — so the suggestions stay visible.
        searchController.tableView.keyboardDismissMode = .onDrag
        installOmniboxFastTap(on: searchController.tableView)
    }

    /// The suggestions overlay is full-bleed behind the floating omnibox. Inset
    /// the table's safe area so the last rows can scroll clear of the pill as
    /// the keyboard and multi-line growth move it.
    fileprivate func updateOmniboxSuggestionsScrollInsets() {
        guard let searchController,
              searchController.parent is HomepageViewController,
              let homepage = contentContainer.contentController as? HomepageViewController,
              let omnibox = homepage.ntpSearchBar else { return }

        homepage.view.layoutIfNeeded()

        // Only the bottom needs insetting — the last rows must scroll clear of the floating
        // omnibox pill. The top stays at zero so the table fills the overlay from the top.
        let omniboxFrame = searchController.view.convert(omnibox.bounds, from: omnibox)
        let bottomInset = max(
            0,
            searchController.view.bounds.height - omniboxFrame.minY + Self.omniboxSuggestionsClearance
        )

        searchController.additionalSafeAreaInsets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: bottomInset,
            right: 0
        )

        // Mirror on the table too — it is edge-pinned, not safe-area-pinned.
        let tableView = searchController.tableView
        var contentInset = tableView.contentInset
        contentInset.top = 0
        contentInset.bottom = bottomInset
        tableView.contentInset = contentInset
        tableView.verticalScrollIndicatorInsets.top = 0
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
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

    private func removeOmniboxFastTap(from tableView: UITableView) {
        tableView.gestureRecognizers?
            .filter { $0.name == Self.omniboxFastTapName }
            .forEach { tableView.removeGestureRecognizer($0) }
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

// MARK: - Omnibox upload drawer & pickers

private struct OmniboxUploadAssociatedKeys {
    /// Used only as opaque key for objc_getAssociatedObject; no shared mutable state.
    nonisolated(unsafe) static var pickerCoordinator: UInt8 = 0
    nonisolated(unsafe) static var attachmentCoordinator: UInt8 = 0
    nonisolated(unsafe) static var uploadErrorBatch: UInt8 = 0
}

@MainActor
private final class OmniboxUploadErrorBatch {
    var errors = Set<OmniboxUploadValidationError>()
    var presentationTask: Task<Void, Never>?
}

@MainActor
extension BrowserViewController {
    fileprivate var omniboxUploadPickerCoordinator: OmniboxUploadPickerCoordinator {
        if let coordinator = objc_getAssociatedObject(self, &OmniboxUploadAssociatedKeys.pickerCoordinator)
            as? OmniboxUploadPickerCoordinator {
            return coordinator
        }
        let coordinator = OmniboxUploadPickerCoordinator()
        coordinator.delegate = self
        objc_setAssociatedObject(self,
                                 &OmniboxUploadAssociatedKeys.pickerCoordinator,
                                 coordinator,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return coordinator
    }

    fileprivate func presentOmniboxUploadDrawer() {
        guard #available(iOS 16.0, *) else { return }
        guard let homepage = contentContainer.contentController as? HomepageViewController,
              let sheetState = homepage.ecosiaAdapter?.omniboxSheetState else { return }

        let sourceView = ntpOmniboxAnchorView ?? view
        homepage.presentOmniboxUploadSheetIfNeeded()
        sheetState.presentUploadDrawer { [weak self] option in
            guard let self else { return }
            self.omniboxUploadPickerCoordinator.presentPicker(for: option,
                                                              from: self,
                                                              sourceView: sourceView)
        }
    }
}

@MainActor
extension BrowserViewController: OmniboxUploadPickerDelegate, OmniboxAttachmentUploadDelegate {
    var omniboxUploadRemainingAttachmentSlots: Int {
        let currentCount = ntpOmniboxAnchorView?.attachments.count ?? 0
        return max(0, OmniboxUploadFileSelectionValidator.maxFileCount - currentCount)
    }

    func omniboxUploadDidFinishPicking(
        items: [OmniboxUploadPendingItem],
        validationErrors: Set<OmniboxUploadValidationError>
    ) {
        handleUploadSelection(items: items, validationErrors: validationErrors)
    }

    func omniboxAttachmentsDidChange() {
        ntpOmniboxAnchorView?.refreshSubmitButtonState()
        ntpSearchBarAttachmentsDidChange()
    }

    func omniboxUploadDidEncounterValidationErrors(_ errors: Set<OmniboxUploadValidationError>) {
        handleUploadSelection(items: [], validationErrors: errors)
    }

    fileprivate func handleUploadSelection(
        items: [OmniboxUploadPendingItem],
        validationErrors: Set<OmniboxUploadValidationError>
    ) {
        let simulatedErrors = OmniboxUploadDebugSimulation.simulatedValidationErrors()
        let allErrors = validationErrors.union(simulatedErrors)

        if !allErrors.isEmpty {
            enqueueOmniboxUploadValidationErrors(allErrors)
        }

        guard simulatedErrors.isEmpty else { return }
        guard !items.isEmpty else { return }

        _ = ntpOmniboxAnchorView?.becomeFirstResponder()
        omniboxAttachmentCoordinator.processPendingItems(items)
    }

    fileprivate var omniboxUploadErrorBatch: OmniboxUploadErrorBatch {
        if let batch = objc_getAssociatedObject(self, &OmniboxUploadAssociatedKeys.uploadErrorBatch)
            as? OmniboxUploadErrorBatch {
            return batch
        }
        let batch = OmniboxUploadErrorBatch()
        objc_setAssociatedObject(self,
                                 &OmniboxUploadAssociatedKeys.uploadErrorBatch,
                                 batch,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return batch
    }

    fileprivate func enqueueOmniboxUploadValidationErrors(_ errors: Set<OmniboxUploadValidationError>) {
        let batch = omniboxUploadErrorBatch
        batch.errors.formUnion(errors)
        batch.presentationTask?.cancel()
        batch.presentationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }

            let accumulated = batch.errors
            batch.errors.removeAll()
            batch.presentationTask = nil
            guard let self, !accumulated.isEmpty else { return }

            self.presentOmniboxUploadValidationErrors(accumulated)
        }
    }

    fileprivate func presentOmniboxUploadValidationErrors(_ errors: Set<OmniboxUploadValidationError>) {
        guard #available(iOS 16.0, *) else { return }
        let messages = OmniboxUploadValidationError.orderedMessages(for: errors)
        showEcosiaErrorToasts(messages: messages)
    }
}
