// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class GeminiSearchRoutingTests: XCTestCase {

    func testAIModeSearchURLIncludesQueryAndUDM() throws {
        let url = GeminiSearchRouting.aiModeSearchURL(query: "trees")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

        XCTAssertEqual(components.host, "www.google.com")
        XCTAssertEqual(components.path, "/search")
        XCTAssertEqual(items["q"], "trees")
        XCTAssertEqual(items["udm"], "50")
    }

    func testGeminiAppURLUsesGeminiHost() {
        XCTAssertEqual(GeminiSearchRouting.geminiAppURL.host, "gemini.google.com")
    }
}
