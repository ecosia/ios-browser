// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

final class OmniboxUploadValidationErrorTests: XCTestCase {

    func testSingleErrorMessage() {
        XCTAssertEqual(
            OmniboxUploadValidationError.orderedMessages(for: [.fileTooLarge]),
            [String.localized(.uploadErrorFileTooLarge)]
        )
    }

    func testMultipleErrorMessagesPreserveOrder() {
        XCTAssertEqual(
            OmniboxUploadValidationError.orderedMessages(for: [.tooManyFiles, .unsupportedFileType]),
            [
                String.localized(.uploadErrorTooManyFiles),
                String.localized(.uploadErrorUnsupportedFileType)
            ]
        )
    }

    func testOrderedMessagesIsEmptyForNoErrors() {
        XCTAssertTrue(OmniboxUploadValidationError.orderedMessages(for: []).isEmpty)
    }
}
