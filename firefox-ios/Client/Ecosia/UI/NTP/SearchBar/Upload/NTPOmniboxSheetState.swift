// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import Ecosia

@MainActor
final class NTPOmniboxSheetState: ObservableObject {
    /// A selection made in the "AI tools" drawer, delivered after the sheet
    /// finishes dismissing so navigation/pickers don't fight the dismissal.
    private enum PendingSelection {
        case upload(OmniboxUploadOption)
        case chatMode(OmniboxChatMode)
    }

    @Published var showUploadDrawer = false

    private var onUploadOptionSelected: ((OmniboxUploadOption) -> Void)?
    private var onChatModeSelected: ((OmniboxChatMode) -> Void)?
    private var pendingSelection: PendingSelection?

    func presentUploadDrawer(onSelectUpload: @escaping (OmniboxUploadOption) -> Void,
                             onSelectChatMode: @escaping (OmniboxChatMode) -> Void) {
        pendingSelection = nil
        onUploadOptionSelected = onSelectUpload
        onChatModeSelected = onSelectChatMode
        showUploadDrawer = true
    }

    func handleUploadOptionSelected(_ option: OmniboxUploadOption) {
        pendingSelection = .upload(option)
        showUploadDrawer = false
    }

    func handleChatModeSelected(_ mode: OmniboxChatMode) {
        pendingSelection = .chatMode(mode)
        showUploadDrawer = false
    }

    func handleUploadDrawerDismissed() {
        defer {
            pendingSelection = nil
            onUploadOptionSelected = nil
            onChatModeSelected = nil
        }

        switch pendingSelection {
        case .upload(let option):
            onUploadOptionSelected?(option)
        case .chatMode(let mode):
            onChatModeSelected?(mode)
        case nil:
            break
        }
    }
}
