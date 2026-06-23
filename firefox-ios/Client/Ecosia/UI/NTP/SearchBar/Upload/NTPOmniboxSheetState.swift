// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import Ecosia

@MainActor
final class NTPOmniboxSheetState: ObservableObject {
    @Published var showUploadDrawer = false

    private var onUploadOptionSelected: ((OmniboxUploadOption) -> Void)?
    private var pendingUploadOption: OmniboxUploadOption?

    func presentUploadDrawer(onSelect: @escaping (OmniboxUploadOption) -> Void) {
        pendingUploadOption = nil
        onUploadOptionSelected = onSelect
        showUploadDrawer = true
    }

    func handleUploadOptionSelected(_ option: OmniboxUploadOption) {
        pendingUploadOption = option
        showUploadDrawer = false
    }

    func handleUploadDrawerDismissed() {
        guard let option = pendingUploadOption else {
            onUploadOptionSelected = nil
            return
        }
        pendingUploadOption = nil
        let callback = onUploadOptionSelected
        onUploadOptionSelected = nil
        callback?(option)
    }
}
