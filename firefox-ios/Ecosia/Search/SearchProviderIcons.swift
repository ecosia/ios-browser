// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Bundled search provider icons from `SearchProviders.xcassets` in the Ecosia framework.
public enum SearchProviderIcons {

    public static func image(for provider: SearchProvider) -> UIImage {
        image(for: provider.rawValue)
    }

    /// Engine identifiers can come from Remote Settings or from the Unleash payload, so
    /// an unrecognised one is expected rather than exceptional: fall back to a generic
    /// mark instead of failing.
    public static func image(for engineID: String) -> UIImage {
        guard let image = UIImage.ecosia(named: assetName(for: engineID)) else {
            EcosiaLogger.search.notice("Missing search provider icon for '\(engineID)', using fallback")
            return fallbackImage
        }
        return image
    }

    private static func assetName(for engineID: String) -> String {
        "search-provider-\(engineID)"
    }

    /// Drawn into a bitmap because `OpenSearchEngine` archiving requires `pngData()`,
    /// which a plain symbol image does not reliably provide.
    private static var fallbackImage: UIImage {
        let size = CGSize(width: 32, height: 32)
        let configuration = UIImage.SymbolConfiguration(pointSize: 24)
        let symbol = UIImage(systemName: "globe", withConfiguration: configuration)
        return UIGraphicsImageRenderer(size: size).image { _ in
            symbol?.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
