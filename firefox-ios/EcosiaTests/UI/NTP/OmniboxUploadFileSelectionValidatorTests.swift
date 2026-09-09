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

    func testValidateReportsTooManyFilesWhenChatIsFull() {
        let urls = [URL(fileURLWithPath: "/tmp/report.pdf")]
        let result = OmniboxUploadFileSelectionValidator.validate(urls: urls, existingAttachmentCount: 5)

        XCTAssertTrue(result.acceptedURLs.isEmpty)
        XCTAssertEqual(result.validationErrors, [.tooManyFiles])
    }

    func testValidateReportsUnsupportedFileType() {
        let urls = [
            URL(fileURLWithPath: "/tmp/report.pdf"),
            URL(fileURLWithPath: "/tmp/archive.zip")
        ]
        let result = OmniboxUploadFileSelectionValidator.validate(urls: urls, existingAttachmentCount: 0)

        XCTAssertEqual(result.acceptedURLs.count, 1)
        XCTAssertEqual(result.validationErrors, [.unsupportedFileType])
    }

    func testValidateReportsTooManyFilesWhenSelectionExceedsRemainingSlots() {
        let urls = (1...7).map { URL(fileURLWithPath: "/tmp/file\($0).pdf") }
        let result = OmniboxUploadFileSelectionValidator.validate(urls: urls, existingAttachmentCount: 0)

        XCTAssertEqual(result.acceptedURLs.count, 5)
        XCTAssertEqual(result.validationErrors, [.tooManyFiles])
    }

    func testValidateReportsOversizedFile() throws {
        let directory = FileManager.default.temporaryDirectory
        let fileURL = directory.appendingPathComponent("oversized.pdf")
        let oversizedData = Data(repeating: 0, count: OmniboxUploadPayloadLoader.maxFileSizeBytes + 1)
        try oversizedData.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let result = OmniboxUploadFileSelectionValidator.validate(urls: [fileURL], existingAttachmentCount: 0)

        XCTAssertTrue(result.acceptedURLs.isEmpty)
        XCTAssertEqual(result.validationErrors, [.fileTooLarge])
    }
}
