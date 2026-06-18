// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum OmniboxUploadOption: CaseIterable {
    case photos
    case camera
    case files
}

/// Placeholder model for selected upload items. Upload handling is wired in a follow-up.
struct OmniboxUploadItem: Equatable {
    enum Source {
        case photos
        case camera
        case files
    }

    let source: Source
    let fileName: String
    let contentTypeIdentifier: String?
}

@MainActor
protocol OmniboxUploadDrawerDelegate: AnyObject {
    func omniboxUploadDrawer(_ drawer: OmniboxUploadDrawerViewController,
                             didSelect option: OmniboxUploadOption,
                             sourceView: UIView)
    func omniboxUploadDrawerDidDismiss(_ drawer: OmniboxUploadDrawerViewController)
}

@MainActor
protocol OmniboxUploadPickerDelegate: AnyObject {
    func omniboxUploadDidSelect(items: [OmniboxUploadItem])
}
