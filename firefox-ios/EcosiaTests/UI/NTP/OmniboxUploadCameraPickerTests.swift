// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import AVFoundation
import UniformTypeIdentifiers
@testable import Client

final class OmniboxUploadCameraPickerTests: XCTestCase {

    func testCameraAuthorizationRequiresAuthorizedStatus() {
        XCTAssertTrue(OmniboxUploadCameraAuthorization.isAccessGranted(for: .authorized))
        XCTAssertFalse(OmniboxUploadCameraAuthorization.isAccessGranted(for: .denied))
        XCTAssertFalse(OmniboxUploadCameraAuthorization.isAccessGranted(for: .restricted))
        XCTAssertFalse(OmniboxUploadCameraAuthorization.isAccessGranted(for: .notDetermined))
    }

    func testCameraPickerOnlyAllowsPhotoCapture() {
        XCTAssertEqual(OmniboxUploadCameraPickerUX.photoMediaTypes, [UTType.image.identifier])
        XCTAssertFalse(OmniboxUploadCameraPickerUX.photoMediaTypes.contains(UTType.movie.identifier))
    }
}
