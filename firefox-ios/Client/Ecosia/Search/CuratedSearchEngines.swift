// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

/// Curated third-party search engines available when `CustomSearchProviderFeatureFlag` is enabled.
/// Templates follow Mozilla's consolidated search configuration for iOS.
enum CuratedSearchEngines {

    static let ecosiaEngineID = "ecosia"

    static let defaultOrder: [String] = [
        ecosiaEngineID,
        "google",
        "bing",
        "duckduckgo"
    ]

    /// Preferred default ordering when Remote Settings is unavailable.
    static let fallbackDefaultOrder = defaultOrder

    /// Builds the bundled fallback engine list used when Remote Settings is unavailable.
    static func allEngines() -> [OpenSearchEngine] {
        [
            ecosiaEngine(),
            makeGoogleEngine(),
            makeBingEngine(),
            makeDuckDuckGoEngine()
        ]
    }

    static func ecosiaEngine() -> OpenSearchEngine {
        makeEcosiaEngine()
    }

    static func engine(forID engineID: String) -> OpenSearchEngine? {
        allEngines().first { $0.engineID == engineID }
    }

    // MARK: - Private

    private static func makeEcosiaEngine() -> OpenSearchEngine {
        let urlProvider = EcosiaEnvironment.current.urlProvider
        return OpenSearchEngine(
            engineID: ecosiaEngineID,
            shortName: "Ecosia",
            telemetrySuffix: nil,
            image: SearchProviderIcons.image(for: ecosiaEngineID),
            searchTemplate: "\(urlProvider.root.absoluteString)/search?q={searchTerms}",
            suggestTemplate: "\(urlProvider.searchAutocomplete.absoluteString)?q={searchTerms}&type=list",
            trendingTemplate: nil,
            isCustomEngine: false
        )
    }

    private static func makeGoogleEngine() -> OpenSearchEngine {
        OpenSearchEngine(
            engineID: "google",
            shortName: "Google",
            telemetrySuffix: "b-1-d",
            image: SearchProviderIcons.image(for: "google"),
            searchTemplate: "https://www.google.com/search?client=firefox-b-1-d&channel=ts&q={searchTerms}",
            suggestTemplate: "https://suggestqueries.google.com/complete/search?client=firefox&channel=tr&q={searchTerms}",
            trendingTemplate: nil,
            isCustomEngine: false
        )
    }

    private static func makeBingEngine() -> OpenSearchEngine {
        OpenSearchEngine(
            engineID: "bing",
            shortName: "Bing",
            telemetrySuffix: nil,
            image: SearchProviderIcons.image(for: "bing"),
            searchTemplate: "https://www.bing.com/search?q={searchTerms}",
            suggestTemplate: "https://www.bing.com/osjson.aspx?query={searchTerms}",
            trendingTemplate: nil,
            isCustomEngine: false
        )
    }

    private static func makeDuckDuckGoEngine() -> OpenSearchEngine {
        OpenSearchEngine(
            engineID: "duckduckgo",
            shortName: "DuckDuckGo",
            telemetrySuffix: nil,
            image: SearchProviderIcons.image(for: "duckduckgo"),
            searchTemplate: "https://duckduckgo.com/?q={searchTerms}&t=fpas",
            suggestTemplate: "https://duckduckgo.com/ac/?q={searchTerms}&type=list",
            trendingTemplate: nil,
            isCustomEngine: false
        )
    }

}
