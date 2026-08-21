// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import Ecosia
@testable import Client

@MainActor
final class CuratedSearchEngineProviderTests: XCTestCase {

    private var previousSelection = ""

    override func setUp() {
        super.setUp()
        previousSelection = User.shared.selectedSearchEngineID
    }

    override func tearDown() {
        User.shared.selectedSearchEngineID = previousSelection
        super.tearDown()
    }

    // MARK: - Allowlist

    func testOffersEveryProviderInTheConfig() {
        User.shared.selectedSearchEngineID = "ecosia"

        let engines = orderedEngines(for: .default)

        XCTAssertEqual(engines.map(\.engineID),
                       ["ecosia", "google", "duckduckgo", "chatgpt", "perplexity"])
    }

    func testRestrictsListToTheConfiguredProviders() {
        User.shared.selectedSearchEngineID = "ecosia"
        let config = SearchRouterConfig(aiMode: .full, providers: [.ecosia, .duckduckgo])

        XCTAssertEqual(orderedEngines(for: config).map(\.engineID), ["ecosia", "duckduckgo"])
    }

    func testRouterDisabledConfigOffersEcosiaOnly() {
        User.shared.selectedSearchEngineID = "ecosia"

        XCTAssertEqual(orderedEngines(for: .routerDisabled).map(\.engineID), ["ecosia"])
    }

    /// Remote Settings has no entry for these, so they can only come from the catalog.
    func testIncludesProvidersRemoteSettingsDoesNotVend() {
        User.shared.selectedSearchEngineID = "ecosia"
        let config = SearchRouterConfig(aiMode: .full, providers: [.ecosia, .chatgpt, .perplexity])

        let ids = orderedEngines(for: config).map(\.engineID)
        XCTAssertTrue(ids.contains("chatgpt"))
        XCTAssertTrue(ids.contains("perplexity"))
    }

    func testBingIsNotOffered() {
        User.shared.selectedSearchEngineID = "ecosia"

        XCTAssertFalse(orderedEngines(for: .default).contains { $0.engineID == "bing" })
    }

    // MARK: - Default engine

    func testSelectedProviderBecomesDefaultEngine() {
        User.shared.selectedSearchEngineID = "duckduckgo"

        XCTAssertEqual(orderedEngines(for: .default).first?.engineID, "duckduckgo")
    }

    func testSelectionDroppedFromTheAllowlistFallsBackToEcosia() {
        User.shared.selectedSearchEngineID = "perplexity"
        let config = SearchRouterConfig(aiMode: .full, providers: [.ecosia, .google])

        let engines = orderedEngines(for: config)

        XCTAssertEqual(engines.first?.engineID, "ecosia")
        XCTAssertEqual(User.shared.selectedSearchEngineID, "ecosia")
    }

    // MARK: - Engine construction

    /// Asserted on the template rather than on `searchURLForQuery`, which additionally
    /// depends on the feature flag being on at runtime.
    func testEnginesAreBuiltFromTheCatalogTemplates() {
        User.shared.selectedSearchEngineID = "ecosia"
        let engines = orderedEngines(for: .default)

        for provider in SearchProvider.allCases {
            let engine = engines.first { $0.engineID == provider.rawValue }
            XCTAssertEqual(engine?.searchTemplate, provider.searchTemplate)
        }
    }

    /// `suggestTemplate` is private on `OpenSearchEngine`, so the wiring is checked
    /// through the URL it produces.
    func testOnlySearchProvidersOfferSuggestions() {
        User.shared.selectedSearchEngineID = "ecosia"
        let engines = orderedEngines(for: .default)

        XCTAssertEqual(engines.first { $0.engineID == "ecosia" }?.suggestURLForQuery("trees")?.host,
                       "ac.ecosia.org")
        XCTAssertEqual(engines.first { $0.engineID == "duckduckgo" }?.suggestURLForQuery("trees")?.host,
                       "duckduckgo.com")
        XCTAssertNil(engines.first { $0.engineID == "chatgpt" }?.suggestURLForQuery("trees"))
        XCTAssertNil(engines.first { $0.engineID == "perplexity" }?.suggestURLForQuery("trees"))
    }

    func testEnginesCarryBrandNames() {
        User.shared.selectedSearchEngineID = "ecosia"
        let engines = orderedEngines(for: .default)

        XCTAssertEqual(engines.first { $0.engineID == "duckduckgo" }?.shortName, "DuckDuckGo")
        XCTAssertEqual(engines.first { $0.engineID == "chatgpt" }?.shortName, "ChatGPT")
    }

    /// The picker offers a fixed list, so persisted custom engines are not surfaced.
    func testCustomEnginesAreNotOffered() {
        User.shared.selectedSearchEngineID = "ecosia"
        let custom = OpenSearchEngine(
            engineID: "custom-a",
            shortName: "Custom A",
            telemetrySuffix: nil,
            image: UIImage(),
            searchTemplate: "https://example.com/search?q={searchTerms}",
            suggestTemplate: nil,
            isCustomEngine: true
        )

        let engines = orderedEngines(for: .default, customEngines: [custom])

        XCTAssertFalse(engines.contains { $0.engineID == "custom-a" })
    }

    // MARK: - Helpers

    private func orderedEngines(for config: SearchRouterConfig,
                                customEngines: [OpenSearchEngine] = []) -> [OpenSearchEngine] {
        let provider = CuratedSearchEngineProvider(configProvider: { config })
        let expectation = expectation(description: "getOrderedEngines completes")
        var result: [OpenSearchEngine] = []

        provider.getOrderedEngines(
            customEngines: customEngines,
            engineOrderingPrefs: SearchEnginePrefs(engineIdentifiers: nil, disabledEngines: nil, version: .v2),
            prefsMigrator: DefaultSearchEnginePrefsMigrator()
        ) { _, engines in
            result = engines
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        return result
    }
}
