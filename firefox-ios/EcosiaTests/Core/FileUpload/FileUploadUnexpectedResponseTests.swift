// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class FileUploadUnexpectedResponseTests: XCTestCase {

    func testUnexpectedResponse_capturesStatusRayIDAndBody() throws {
        let unexpectedResponse = FileUploadService.UnexpectedResponse(
            step: .refresh,
            data: Data(#"{"message":"Forbidden"}"#.utf8),
            response: try makeResponse(statusCode: 403, headers: ["cf-ray": "a44466c57d1e1a62-HAM"])
        )

        XCTAssertEqual(unexpectedResponse.step, .refresh)
        XCTAssertEqual(unexpectedResponse.statusCode, 403)
        XCTAssertEqual(unexpectedResponse.rayID, "a44466c57d1e1a62-HAM")
        XCTAssertNil(unexpectedResponse.cloudflareMitigation)
        XCTAssertEqual(unexpectedResponse.body, #"{"message":"Forbidden"}"#)
    }

    func testChallengeHeader_isCaptured() throws {
        let unexpectedResponse = FileUploadService.UnexpectedResponse(
            step: .presign,
            data: Data("<html>Confirm you're not a robot</html>".utf8),
            response: try makeResponse(statusCode: 403, headers: ["cf-mitigated": "challenge"])
        )

        XCTAssertEqual(unexpectedResponse.cloudflareMitigation, "challenge")
    }

    func testLongBody_isTruncated() throws {
        let unexpectedResponse = FileUploadService.UnexpectedResponse(
            step: .put,
            data: Data(String(repeating: "x", count: 1_000).utf8),
            response: try makeResponse(statusCode: 500)
        )

        XCTAssertEqual(unexpectedResponse.body?.count, 200)
    }

    func testMissingResponse_reportsUnknownStatus() {
        let unexpectedResponse = FileUploadService.UnexpectedResponse(step: .put, data: Data(), response: nil)

        XCTAssertEqual(unexpectedResponse.statusCode, -1)
        XCTAssertNil(unexpectedResponse.rayID)
        XCTAssertNil(unexpectedResponse.cloudflareMitigation)
        XCTAssertNil(unexpectedResponse.body)
    }

    func testUnexpectedResponseError_describesTheResponse() throws {
        let unexpectedResponse = FileUploadService.UnexpectedResponse(
            step: .presign,
            data: Data("Forbidden".utf8),
            response: try makeResponse(statusCode: 403, headers: ["cf-ray": "a45b07659cec62ca-HAM"])
        )

        XCTAssertEqual(
            FileUploadService.Error.unexpectedResponse(unexpectedResponse).localizedDescription,
            "presign unexpected response status=403 cf-ray=a45b07659cec62ca-HAM cf-mitigated=none body=Forbidden"
        )
    }

    private func makeResponse(statusCode: Int, headers: [String: String] = [:]) throws -> HTTPURLResponse {
        let url = try XCTUnwrap(URL(string: "https://api.ecosia.org/v2/conversations/files/upload"))
        return try XCTUnwrap(HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers))
    }
}
