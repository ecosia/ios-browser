// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

final class OmniboxSubmitRoutingTests: XCTestCase {

    func testRoutesPastedURLWhenNoAttachments() {
        let url = OmniboxSubmitRouting.destinationURL(
            query: "https://example.com/path",
            chatFiles: []
        )

        XCTAssertEqual(url.absoluteString, "https://example.com/path")
    }

    func testRoutesToAIChatWhenAttachmentsPresent() throws {
        let files = [
            AIChatFileQuery(
                fileId: "file-1",
                filename: "doc.pdf",
                mimeType: "application/pdf",
                sizeBytes: 1024
            )
        ]
        let url = OmniboxSubmitRouting.destinationURL(query: "summarize this", chatFiles: files)
        let items = Dictionary(
            uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
                .map { ($0.name, $0.value) }
        )

        XCTAssertEqual(items["q"], "summarize this")
        XCTAssertNotNil(items["files"])
    }

    func testRoutesToEcosiaSearchForPlainQueryWithoutAttachments() throws {
        let url = OmniboxSubmitRouting.destinationURL(query: "trees", chatFiles: [])
        let items = Dictionary(
            uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
                .map { ($0.name, $0.value) }
        )

        XCTAssertEqual(items["q"], "trees")
        XCTAssertEqual(items["ar"], "1")
    }
}
