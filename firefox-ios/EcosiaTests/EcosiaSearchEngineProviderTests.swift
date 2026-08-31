// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
@testable import Client

// Guards the Ecosia-only search engine setup against regressions, in particular a Firefox upgrade
// merge accidentally restoring the upstream `ASSearchEngineProvider`, which would let Google become
// the default search engine for non-German, non-EU-region users.
//
// @MainActor so the @MainActor `SearchEngineCompletion` closure and the assertions share an
// isolation domain (avoids Swift 6 "Sending 'result' risks causing data races").
@MainActor
final class EcosiaSearchEngineProviderTests: XCTestCase {

    private var previousUnleashModel = Unleash.Model()

    override func setUp() {
        super.setUp()
        previousUnleashModel = Unleash.model
    }

    override func tearDown() {
        Unleash.model = previousUnleashModel
        SearchRouterConfiguration.invalidateCache()
        super.tearDown()
    }

    /// The flag is process-global, so each case sets it rather than reading whatever another
    /// suite left behind. Skipping on ambient state would make this coverage depend on run order.
    func testFactoryUsesEcosiaProviderWhenFeatureDisabled() {
        setCustomSearchProvider(enabled: false)

        XCTAssertTrue(
            SearchEngineProviderFactory.defaultSearchEngineProvider is EcosiaSearchEngineProvider,
            "The default search engine provider must be EcosiaSearchEngineProvider so Ecosia stays "
            + "the default on every locale/region. Did a Firefox upgrade restore ASSearchEngineProvider()?"
        )
    }

    func testFactoryUsesCuratedProviderWhenFeatureEnabled() {
        setCustomSearchProvider(enabled: true)

        XCTAssertTrue(
            SearchEngineProviderFactory.defaultSearchEngineProvider is CuratedSearchEngineProvider,
            "When the custom search provider flag is enabled, CuratedSearchEngineProvider must be used."
        )
    }

    /// Ecosia must be the default (index 0) regardless of any persisted engine ordering or custom
    /// engines. This is the behavioural guarantee the bug fix relies on.
    func testEcosiaIsAlwaysDefaultEngine() {
        let provider = EcosiaSearchEngineProvider()
        let customEngines = [makeEngine(id: "custom-a"), makeEngine(id: "custom-b")]
        // Prefs that would otherwise put a non-Ecosia engine first.
        let prefs = SearchEnginePrefs(
            engineIdentifiers: ["custom-a", "custom-b"],
            disabledEngines: nil,
            version: .v2
        )

        let expectation = expectation(description: "getOrderedEngines completes")
        var result: [OpenSearchEngine] = []
        provider.getOrderedEngines(
            customEngines: customEngines,
            engineOrderingPrefs: prefs,
            prefsMigrator: DefaultSearchEnginePrefsMigrator()
        ) { _, engines in
            result = engines
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(result.first?.engineID, "ecosia", "Ecosia must be the default engine at index 0")
        XCTAssertEqual(result.first?.shortName, "Ecosia")
        // Custom engines are preserved after Ecosia.
        XCTAssertEqual(result.map { $0.engineID }, ["ecosia", "custom-a", "custom-b"])
    }

    /// The Ecosia engine's suggest template must point at Ecosia's autocomplete endpoint, not a
    /// third party, otherwise typed queries would leak to another provider's suggest API.
    func testEcosiaEngineSuggestsFromEcosia() {
        let provider = EcosiaSearchEngineProvider()

        let expectation = expectation(description: "getOrderedEngines completes")
        var ecosia: OpenSearchEngine?
        provider.getOrderedEngines(
            customEngines: [],
            engineOrderingPrefs: SearchEnginePrefs(engineIdentifiers: nil, disabledEngines: nil, version: .v2),
            prefsMigrator: DefaultSearchEnginePrefsMigrator()
        ) { _, engines in
            ecosia = engines.first
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        let suggestURL = ecosia?.suggestURLForQuery("trees")
        XCTAssertEqual(suggestURL?.host, "ac.ecosia.org")
    }

    // MARK: - Helpers

    private func setCustomSearchProvider(enabled: Bool) {
        var model = Unleash.Model()
        model.toggles.insert(
            Unleash.Toggle(name: Unleash.Toggle.Name.customSearchProvider.rawValue,
                           enabled: enabled,
                           variant: .init(name: "config", enabled: true, payload: nil))
        )
        Unleash.model = model
        SearchRouterConfiguration.invalidateCache()
    }

    private func makeEngine(id: String) -> OpenSearchEngine {
        OpenSearchEngine(
            engineID: id,
            shortName: id,
            telemetrySuffix: nil,
            image: UIImage(),
            searchTemplate: "https://example.com/search?q={searchTerms}",
            suggestTemplate: nil,
            isCustomEngine: true
        )
    }
}
