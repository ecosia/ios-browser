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
}
