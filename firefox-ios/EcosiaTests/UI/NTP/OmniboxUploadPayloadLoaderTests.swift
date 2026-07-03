// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

@MainActor
final class OmniboxUploadPayloadLoaderTests: XCTestCase {

    func testRejectsOversizedPayload() {
        let oversized = Data(repeating: 0, count: OmniboxUploadPayloadLoader.maxFileSizeBytes + 1)
        XCTAssertThrowsError(try OmniboxUploadPayloadLoader.validateSize(oversized)) { error in
            XCTAssertEqual(error as? OmniboxUploadPayloadError, .fileTooLarge)
        }
    }

    func testNormalizedJPEGFileNameReplacesExtension() {
        XCTAssertEqual(
            OmniboxUploadPayloadLoader.normalizedJPEGFileName(from: "IMG_0001.HEIC"),
            "IMG_0001.jpg"
        )
        XCTAssertEqual(
            OmniboxUploadPayloadLoader.normalizedJPEGFileName(from: "camera-photo.heic", fallback: "photo.jpg"),
            "camera-photo.jpg"
        )
    }

    func testNormalizedJPEGFileNameUsesFallbackForEmptyStem() {
        XCTAssertEqual(
            OmniboxUploadPayloadLoader.normalizedJPEGFileName(from: ".heic", fallback: "photo.jpg"),
            "photo.jpg"
        )
    }
}
