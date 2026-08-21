// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

/// Builds `OpenSearchEngine`s for the providers offered while
/// `CustomSearchProviderFeatureFlag` is enabled, from the bundled `SearchProvider` catalog.
enum CuratedSearchEngines {

    static let ecosiaEngineID = SearchProvider.ecosia.rawValue

    static func engines(for providers: [SearchProvider]) -> [OpenSearchEngine] {
        providers.map(engine(for:))
    }

    static func ecosiaEngine() -> OpenSearchEngine {
        engine(for: .ecosia)
    }

    static func engine(forID engineID: String) -> OpenSearchEngine? {
        SearchProvider(rawValue: engineID).map(engine(for:))
    }

    static func engine(for provider: SearchProvider) -> OpenSearchEngine {
        OpenSearchEngine(
            engineID: provider.rawValue,
            shortName: provider.displayName,
            telemetrySuffix: nil,
            image: SearchProviderIcons.image(for: provider),
            searchTemplate: provider.searchTemplate,
            suggestTemplate: provider.suggestTemplate,
            trendingTemplate: nil,
            isCustomEngine: false
        )
    }
}
