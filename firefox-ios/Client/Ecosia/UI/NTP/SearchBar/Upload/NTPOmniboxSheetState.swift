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

    private var onUploadOptionSelected: ((OmniboxUploadOption) -> Void)?
    private var onChatModeSelectionChanged: ((OmniboxChatMode?) -> Void)?
    /// An upload selection is delivered only after the sheet finishes dismissing
    /// so the picker it presents doesn't fight the dismissal. Chat-mode changes
    /// don't present anything, so they apply immediately (see below).
    private var pendingUploadOption: OmniboxUploadOption?

    func presentUploadDrawer(onSelectUpload: @escaping (OmniboxUploadOption) -> Void,
                             onChatModeSelectionChanged: @escaping (OmniboxChatMode?) -> Void) {
        pendingUploadOption = nil
        onUploadOptionSelected = onSelectUpload
        self.onChatModeSelectionChanged = onChatModeSelectionChanged
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
        selectedChatMode = mode
        onChatModeSelectionChanged?(selectedChatMode)
        showUploadDrawer = false
    }

    func handleUploadDrawerDismissed() {
        let option = pendingUploadOption
        let uploadCallback = onUploadOptionSelected
        pendingUploadOption = nil
        onUploadOptionSelected = nil
        onChatModeSelectionChanged = nil

        if let option {
            uploadCallback?(option)
        }
    }
}
