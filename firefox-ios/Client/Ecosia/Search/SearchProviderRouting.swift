// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation
import Shared

/// Routes omnibox and URL-bar search queries to the selected provider when the feature flag is on.
enum SearchProviderRouting {

    static func searchURL(forQuery query: String,
                          engine: OpenSearchEngine,
                          preservingVerticalFrom sourceURL: URL? = nil) -> URL? {
        if SearchProviderSelection.isEcosiaEngineID(engine.engineID) || !CustomSearchProviderFeatureFlag.isEnabled {
            if let sourceURL {
                return URL.ecosiaSearchWithQuery(query, preservingVerticalFrom: sourceURL)
            }
            return URL.ecosiaSearchWithQuery(
                query,
                autoRedirect: !AIFreeSearchingSelection.isActive
            )
        }
        return engine.searchURLForQuery(query)
    }

    static func omniboxSearchURL(forQuery query: String,
                                 engine: OpenSearchEngine? = nil,
                                 engineID: String = User.shared.selectedSearchEngineID) -> URL {
        if CustomSearchProviderFeatureFlag.isEnabled,
           !SearchProviderSelection.isEcosiaEngineID(engineID),
           let engine,
           let url = engine.searchURLForQuery(query) {
            return url
        }
        return URL.ecosiaSearchWithQuery(query, autoRedirect: !AIFreeSearchingSelection.isActive)
    }
}
