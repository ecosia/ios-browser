// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import Ecosia
@testable import Client

@MainActor
final class SearchProviderEngineOrderingTests: XCTestCase {

    func testInsertingEcosiaPrependsWhenMissing() throws {
        guard CustomSearchProviderFeatureFlag.isEnabled else {
            throw XCTSkip("Custom search provider flag is disabled in this test run")
        }
        let engines = [makeEngine(id: "google"), makeEngine(id: "bing")]
        let result = SearchProviderEngineOrdering.insertingEcosiaIfNeeded(into: engines)

        XCTAssertEqual(result.first?.engineID, SearchProviderSelection.ecosiaEngineID)
        XCTAssertEqual(result.map(\.engineID), ["ecosia", "google", "bing"])
    }

    func testInsertingEcosiaIsNoOpWhenPresent() throws {
        guard CustomSearchProviderFeatureFlag.isEnabled else {
            throw XCTSkip("Custom search provider flag is disabled in this test run")
        }
        let engines = [makeEngine(id: "ecosia"), makeEngine(id: "google")]
        let result = SearchProviderEngineOrdering.insertingEcosiaIfNeeded(into: engines)
        XCTAssertEqual(result.map(\.engineID), ["ecosia", "google"])
    }

    func testPromoteSelectedSearchProviderMovesEngineToFront() throws {
        guard CustomSearchProviderFeatureFlag.isEnabled else {
            throw XCTSkip("Custom search provider flag is disabled in this test run")
        }
        let previousID = User.shared.selectedSearchEngineID
        defer { User.shared.selectedSearchEngineID = previousID }
        let engines = [makeEngine(id: "ecosia"), makeEngine(id: "google"), makeEngine(id: "bing")]
        User.shared.selectedSearchEngineID = "google"

        let result = SearchProviderEngineOrdering.promoteSelectedSearchProvider(in: engines)
        XCTAssertEqual(result.first?.engineID, "google")
    }

    func testApplyPersistedOrderingRespectsSavedIdentifiers() {
        let engines = [
            makeEngine(id: "ecosia"),
            makeEngine(id: "google"),
            makeEngine(id: "perplexity")
        ]
        let prefs = SearchEnginePrefs(
            engineIdentifiers: ["perplexity", "google", "ecosia"],
            disabledEngines: nil,
            version: .v2
        )

        let result = SearchProviderEngineOrdering.applyPersistedOrdering(from: prefs, to: engines)
        XCTAssertEqual(result.map(\.engineID), ["perplexity", "google", "ecosia"])
    }

    // MARK: - Helpers

    private func makeEngine(id: String) -> OpenSearchEngine {
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
