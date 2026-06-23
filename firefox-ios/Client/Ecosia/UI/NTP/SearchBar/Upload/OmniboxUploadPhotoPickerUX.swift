// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Photos

enum OmniboxUploadPhotoPickerUX {
    static let maxSelectionCount = 5
}

enum OmniboxUploadPhotoLibraryAuthorization {
    static func isAccessGranted(for status: PHAuthorizationStatus) -> Bool {
        status == .authorized || status == .limited
    }
}
