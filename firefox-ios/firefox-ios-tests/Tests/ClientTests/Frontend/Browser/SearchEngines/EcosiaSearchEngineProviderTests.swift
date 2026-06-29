// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

/// Guards the Ecosia-only search engine setup against regressions, including a Firefox upgrade
/// merge accidentally restoring the upstream `ASSearchEngineProvider` (which caused MOB-4673 /
/// MOB-4579: Google/Firefox shown as default for non-German, non-EU-region users).
// @MainActor so the @MainActor `SearchEngineCompletion` closure and the assertions share an
// isolation domain (avoids Swift 6 "Sending 'result' risks causing data races").
@MainActor
final class EcosiaSearchEngineProviderTests: XCTestCase {

    /// The production factory must use our custom provider, not the upstream Remote Settings one.
    /// If a future upgrade flips this back to `ASSearchEngineProvider()`, this fails immediately.
    func testFactoryUsesEcosiaProvider() {
        XCTAssertTrue(
            SearchEngineProviderFactory.defaultSearchEngineProvider is EcosiaSearchEngineProvider,
            "The default search engine provider must be EcosiaSearchEngineProvider so Ecosia stays "
            + "the default on every locale/region. Did a Firefox upgrade restore ASSearchEngineProvider()?"
        )
    }

    /// Ecosia must be the default (index 0) regardless of any persisted engine ordering or custom
    /// engines — this is the behavioural guarantee the bug fix relies on.
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
    /// third party — otherwise typed queries would leak to another provider's suggest API.
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
