// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class OmniboxUploadPayloadLoaderTests: XCTestCase {

    func testValidateFileSizeRejectsOversizedFileBeforeReading() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("oversized.txt")
        let oversized = Data(count: OmniboxUploadPayloadLoader.maxFileSizeBytes + 1)
        try oversized.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(try OmniboxUploadPayloadLoader.validateFileSize(at: url)) { error in
            XCTAssertEqual(error as? OmniboxUploadPayloadError, .fileTooLarge)
        }
    }

    func testLoadFileReadsSmallFile() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("small.txt")
        try Data("hello".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let payload = try await OmniboxUploadPayloadLoader.loadFile(from: url)
        XCTAssertEqual(payload.fileName, "small.txt")
        XCTAssertEqual(payload.data, Data("hello".utf8))
    }
}
