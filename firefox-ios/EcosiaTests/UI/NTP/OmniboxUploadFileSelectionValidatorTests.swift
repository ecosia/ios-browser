// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class OmniboxUploadFileSelectionValidatorTests: XCTestCase {

    func testBlocksAppAndExeFiles() {
        XCTAssertFalse(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/app.app")))
        XCTAssertFalse(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/installer.exe")))
    }

    func testAllowsSupportedFormats() {
        XCTAssertTrue(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/report.pdf")))
        XCTAssertTrue(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/notes.txt")))
        XCTAssertTrue(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/letter.doc")))
        XCTAssertTrue(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/photo.jpg")))
        XCTAssertTrue(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/photo.jpeg")))
        XCTAssertTrue(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/photo.png")))
    }

    func testLimitsSelectionToFiveFiles() {
        let urls = (1...7).map { URL(fileURLWithPath: "/tmp/file\($0).pdf") }
        XCTAssertEqual(OmniboxUploadFileSelectionValidator.allowedURLs(from: urls).count, 5)
    }

    func testRejectsUnsupportedFormats() {
        XCTAssertFalse(OmniboxUploadFileSelectionValidator.isAllowed(URL(fileURLWithPath: "/tmp/archive.zip")))
    }
}
