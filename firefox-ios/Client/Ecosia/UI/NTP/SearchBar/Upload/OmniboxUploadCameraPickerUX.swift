// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import UniformTypeIdentifiers

enum OmniboxUploadCameraPickerUX {
    static let photoMediaTypes = [UTType.image.identifier]
}

enum OmniboxUploadCameraAuthorization {
    static func isAccessGranted(for status: AVAuthorizationStatus) -> Bool {
        status == .authorized
    }
}
