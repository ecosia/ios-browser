// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

/// Builds Ecosia search URLs for the NTP omnibox.
///
/// Autorouting (`ar=1`) is the default so the backend can send the query to AI
/// search. When AI-free searching is active, autorouting is disabled and the
/// URL is a plain `/search?q=…`.
enum SearchProviderRouting {

    static func omniboxSearchURL(forQuery query: String) -> URL {
        URL.ecosiaSearchWithQuery(query, autoRedirect: !AIFreeSearchingSelection.isActive)
    }
}
