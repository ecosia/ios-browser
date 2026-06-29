// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Shared
import UIKit

/// Ecosia: Search engine provider that always returns Ecosia as the single default engine.
///
/// Ecosia is an Ecosia-only product: the actual search is hardcoded to Ecosia
/// (`OpenSearchEngine.searchURLForQuery` / `URL.ecosiaSearchWithQuery`) regardless of the selected
/// engine, and autocomplete uses Ecosia's suggest endpoint. We therefore build the Ecosia engine
/// locally instead of fetching engines from Mozilla's Remote Settings.
final class EcosiaSearchEngineProvider: SearchEngineProvider, Sendable {

    // MARK: - SearchEngineProvider

    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v2

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        // Ecosia is always the default at position 0. Any user-added custom engines follow it.
        let engines = [makeEcosiaEngine()] + customEngines
        ensureMainThread {
            completion(engineOrderingPrefs, engines)
        }
    }

    // MARK: - Private

    /// Builds the Ecosia `OpenSearchEngine` from the current environment's `URLProvider`.
    ///
    /// `OpenSearchEngine` already routes searches through `URL.ecosiaSearchWithQuery(_:)`, so the
    /// search template is only used to recognise Ecosia result URLs and extract the typed query for
    /// the address bar (`queryForSearchURL`). The suggest template drives autocomplete. Both are
    /// derived from `URLProvider` so they follow the active environment (production/staging).
    private func makeEcosiaEngine() -> OpenSearchEngine {
        let urlProvider = EcosiaEnvironment.current.urlProvider
        return OpenSearchEngine(
            engineID: Engine.engineID,
            shortName: Engine.shortName,
            telemetrySuffix: nil,
            image: ecosiaEngineImage(),
            searchTemplate: "\(urlProvider.root.absoluteString)/search?q={searchTerms}",
            suggestTemplate: "\(urlProvider.searchAutocomplete.absoluteString)?q={searchTerms}&type=list",
            trendingTemplate: nil,
            isCustomEngine: false
        )
    }

    private func ecosiaEngineImage() -> UIImage {
        // Brand mark shown next to the engine in Search settings. OpenSearchEngine asserts on an
        // empty image, so this asset must exist in the bundle.
        return UIImage(named: "ecosiaHomeHeaderLogoBall") ?? UIImage()
    }

    private enum Engine {
        static let engineID = "ecosia"
        static let shortName = "Ecosia"
    }
}
