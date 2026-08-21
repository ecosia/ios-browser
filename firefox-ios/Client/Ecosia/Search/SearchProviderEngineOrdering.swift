// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

/// Ordering helpers for the curated search provider list.
enum SearchProviderEngineOrdering {

    /// Moves the user's selected provider into the default slot. When that provider is no
    /// longer offered, for example after it is dropped from the remote allowlist, Ecosia
    /// takes the slot instead.
    static func promoteSelectedSearchProvider(in engines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        let selectedID = User.shared.selectedSearchEngineID
        let isSelectionOffered = engines.contains { $0.engineID == selectedID }
        let targetID = isSelectionOffered ? selectedID : CuratedSearchEngines.ecosiaEngineID

        guard let index = engines.firstIndex(where: { $0.engineID == targetID }), index != 0 else {
            return engines
        }

        var reordered = engines
        reordered.insert(reordered.remove(at: index), at: 0)
        return reordered
    }
}
