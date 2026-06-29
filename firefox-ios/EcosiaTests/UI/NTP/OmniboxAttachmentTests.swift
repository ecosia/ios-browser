// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class OmniboxAttachmentTests: XCTestCase {

    func testReadyAttachmentExposesFileId() {
        let attachment = OmniboxAttachment(
            fileName: "notes.pdf",
            layout: .file,
            state: .ready(byteCount: 1024, fileId: "file-123", mimeType: "application/pdf")
        )

        XCTAssertEqual(attachment.fileId, "file-123")
        XCTAssertTrue(attachment.isReady)
        XCTAssertFalse(attachment.isLoading)
        XCTAssertEqual(
            attachment.chatFileQuery,
            AIChatFileQuery(
                fileId: "file-123",
                filename: "notes.pdf",
                mimeType: "application/pdf",
                sizeBytes: 1024
            )
        )
    }

    func testChatFileQueryAddsExtensionWhenPhotoNameOmitsIt() {
        let attachment = OmniboxAttachment(
            fileName: "IMG_0111",
            layout: .image,
            state: .ready(byteCount: 5212725, fileId: "file-123", mimeType: "image/jpeg")
        )

        XCTAssertEqual(attachment.chatFileQuery?.filename, "IMG_0111.jpg")
    }

    func testLoadingAttachmentHasNoFileId() {
        let attachment = OmniboxAttachment(
            fileName: "photo.jpg",
            layout: .image,
            state: .loading
        )

        XCTAssertNil(attachment.fileId)
        XCTAssertTrue(attachment.isLoading)
        XCTAssertFalse(attachment.isReady)
    }
}
