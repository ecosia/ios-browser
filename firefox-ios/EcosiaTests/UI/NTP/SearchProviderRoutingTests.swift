// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

final class SearchProviderRoutingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        User.shared.aiFreeSearching = nil
        Unleash.clearInstanceModel()
    }

    override func tearDown() {
        super.tearDown()
        User.shared.aiFreeSearching = nil
        Unleash.clearInstanceModel()
        try? FileManager.default.removeItem(at: FileManager.user)
    }

    func testOmniboxSearchURLIncludesAutoroutingWhenAIFreeIsOff() throws {
        let url = SearchProviderRouting.omniboxSearchURL(forQuery: "trees")
        let items = queryItems(from: url)

        XCTAssertEqual(items["q"], "trees")
        XCTAssertEqual(items["ar"], "1")
    }

    func testOmniboxSearchURLOmitsAutoroutingWhenAIFreeIsOn() throws {
        enableAIFreeSearching()

        let url = SearchProviderRouting.omniboxSearchURL(forQuery: "trees")
        let items = queryItems(from: url)

        XCTAssertEqual(items["q"], "trees")
        XCTAssertNil(items["ar"])
        XCTAssertTrue(url.path.hasSuffix("/search"))
    }

    func testOmniboxSearchURLKeepsAutoroutingWhenFlagOffEvenIfToggleOn() throws {
        User.shared.aiFreeSearching = true

        let url = SearchProviderRouting.omniboxSearchURL(forQuery: "trees")
        XCTAssertEqual(queryItems(from: url)["ar"], "1")
    }

    private func enableAIFreeSearching() {
        let toggle = Unleash.Toggle(
            name: Unleash.Toggle.Name.aiFreeSearching.rawValue,
            enabled: true,
            variant: Unleash.Variant(name: "", enabled: false, payload: nil)
        )
        Unleash.model = Unleash.Model(toggles: Set([toggle]))
        AIFreeSearchingSelection.setEnabled(true)
    }

    private func queryItems(from url: URL) -> [String: String?] {
        Dictionary(
            uniqueKeysWithValues: (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
                .map { ($0.name, $0.value) }
        )
    }
}
