// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import Ecosia

@MainActor
final class NTPOmniboxSheetState: ObservableObject {
    @Published var showUploadDrawer = false

    /// The currently active chat mode, or `nil` when none is selected. Drives
    /// both the checkmark in the drawer and the mode chip on the omnibox, and
    /// is read by the submit path to route messages to the matching AI Chat
    /// URL. Owned here so the drawer, the chip, and routing share one source
    /// of truth.
    @Published var selectedChatMode: OmniboxChatMode?

    /// Whether the current user is signed in. Drives the drawer's signed-out
    /// state (only Standard AI Chat selectable, others disabled, sign-in CTA).
    @Published var isAuthenticated = false

    private var onUploadOptionSelected: ((OmniboxUploadOption) -> Void)?
    private var onChatModeSelectionChanged: ((OmniboxChatMode?) -> Void)?
    private var onLoginRequested: (() -> Void)?
    /// An upload selection (or a sign-in tap) is delivered only after the sheet
    /// finishes dismissing so the picker / auth flow it presents doesn't fight
    /// the dismissal. Chat-mode changes don't present anything, so they apply
    /// immediately (see below).
    private var pendingUploadOption: OmniboxUploadOption?
    private var pendingLogin = false

    func presentUploadDrawer(isAuthenticated: Bool,
                             onSelectUpload: @escaping (OmniboxUploadOption) -> Void,
                             onChatModeSelectionChanged: @escaping (OmniboxChatMode?) -> Void,
                             onLogin: @escaping () -> Void) {
        pendingUploadOption = nil
        pendingLogin = false
        self.isAuthenticated = isAuthenticated
        onUploadOptionSelected = onSelectUpload
        self.onChatModeSelectionChanged = onChatModeSelectionChanged
        onLoginRequested = onLogin
        showUploadDrawer = true
    }

    func handleUploadOptionSelected(_ option: OmniboxUploadOption) {
        pendingUploadOption = option
        showUploadDrawer = false
    }

    func handleChatModeSelected(_ mode: OmniboxChatMode) {
        // Only one mode can be active; picking a mode makes it the active one.
        // Re-picking the already-active mode is a no-op (it just closes the
        // drawer) — deselection happens by tapping the omnibox chip, not here.
        // Applied immediately (rather than on dismiss) so the drawer checkmark
        // and the omnibox chip update the instant the user taps.
        Analytics.shared.aiToolsMenuChatModeSelection(mode: mode,
                                                      action: .select,
                                                      isLoggedIn: isAuthenticated)
        selectedChatMode = mode
        onChatModeSelectionChanged?(selectedChatMode)
        showUploadDrawer = false
    }

    /// Requests the sign-in flow from the drawer's CTA. Deferred until the sheet
    /// dismisses so the auth UI doesn't fight the dismissal.
    func handleLoginRequested() {
        Analytics.shared.aiToolsMenuSignInClicked()
        pendingLogin = true
        showUploadDrawer = false
    }

    func handleUploadDrawerDismissed() {
        let option = pendingUploadOption
        let uploadCallback = onUploadOptionSelected
        let login = pendingLogin
        let loginCallback = onLoginRequested
        pendingUploadOption = nil
        pendingLogin = false
        onUploadOptionSelected = nil
        onChatModeSelectionChanged = nil
        onLoginRequested = nil

        if let option {
            uploadCallback?(option)
        } else if login {
            loginCallback?()
        }
    }
}
