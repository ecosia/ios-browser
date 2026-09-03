// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import Ecosia
@testable import Client

@MainActor
final class SearchProviderEngineOrderingTests: XCTestCase {

    private var previousSelection = ""

    override func setUp() {
        super.setUp()
        previousSelection = User.shared.selectedSearchEngineID
    }

    override func tearDown() {
        User.shared.selectedSearchEngineID = previousSelection
        super.tearDown()
    }

    func testPromotesSelectedProviderToDefaultSlot() {
        User.shared.selectedSearchEngineID = "google"
        let engines = makeEngines("ecosia", "google", "duckduckgo")

        let result = SearchProviderEngineOrdering.promoteSelectedSearchProvider(in: engines)

        XCTAssertEqual(result.map(\.engineID), ["google", "ecosia", "duckduckgo"])
    }

    func testLeavesListUntouchedWhenSelectionIsAlreadyDefault() {
        User.shared.selectedSearchEngineID = "ecosia"
        let engines = makeEngines("ecosia", "google")

        let result = SearchProviderEngineOrdering.promoteSelectedSearchProvider(in: engines)

        XCTAssertEqual(result.map(\.engineID), ["ecosia", "google"])
    }

    /// A provider dropped from the remote allowlist must not leave whichever engine
    /// happens to be first as the default.
    func testFallsBackToEcosiaWhenSelectionIsNoLongerOffered() {
        User.shared.selectedSearchEngineID = "perplexity"
        let engines = makeEngines("google", "ecosia", "duckduckgo")

        let result = SearchProviderEngineOrdering.promoteSelectedSearchProvider(in: engines)

        XCTAssertEqual(result.first?.engineID, "ecosia")
    }

    func testHandlesEmptyList() {
        User.shared.selectedSearchEngineID = "google"

        XCTAssertTrue(SearchProviderEngineOrdering.promoteSelectedSearchProvider(in: []).isEmpty)
    }

    // MARK: - Helpers

    private func makeEngines(_ ids: String...) -> [OpenSearchEngine] {
        ids.map { id in
            OpenSearchEngine(
                engineID: id,
                shortName: id,
                telemetrySuffix: nil,
                image: UIImage(),
                searchTemplate: "https://example.com/search?q={searchTerms}",
                suggestTemplate: nil,
                isCustomEngine: false
            )
        }
    }
}
