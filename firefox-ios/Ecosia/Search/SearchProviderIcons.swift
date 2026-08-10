// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Bundled search provider icons from `SearchProviders.xcassets` in the Ecosia framework.
public enum SearchProviderIcons {

    public static func image(for engineID: String) -> UIImage {
        guard let image = UIImage.ecosia(named: assetName(for: engineID)) else {
            fatalError("Missing required bundled asset '\(assetName(for: engineID))' for search engine icon")
        }
        return image
    }

    private static func assetName(for engineID: String) -> String {
        "search-provider-\(engineID)"
    }
}
