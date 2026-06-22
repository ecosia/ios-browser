// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Photos
@testable import Client

final class OmniboxUploadPhotoPickerTests: XCTestCase {

    func testPhotoLibraryAccessAllowsAuthorizedAndLimited() {
        XCTAssertTrue(OmniboxUploadPhotoLibraryAuthorization.isAccessGranted(for: .authorized))
        XCTAssertTrue(OmniboxUploadPhotoLibraryAuthorization.isAccessGranted(for: .limited))
    }

    func testPhotoLibraryAccessRejectsDeniedAndRestricted() {
        XCTAssertFalse(OmniboxUploadPhotoLibraryAuthorization.isAccessGranted(for: .denied))
        XCTAssertFalse(OmniboxUploadPhotoLibraryAuthorization.isAccessGranted(for: .restricted))
    }

    func testPhotoPickerSelectionLimitIsFive() {
        XCTAssertEqual(OmniboxUploadPhotoPickerUX.maxSelectionCount, 5)
    }
}
