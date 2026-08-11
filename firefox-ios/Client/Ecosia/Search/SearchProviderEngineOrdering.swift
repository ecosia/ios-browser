// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

/// Shared ordering helpers for custom search provider engine lists.
enum SearchProviderEngineOrdering {

    /// Ensures the Ecosia engine is present when the custom provider feature is enabled.
    static func insertingEcosiaIfNeeded(into engines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return engines }
        guard !engines.contains(where: { SearchProviderSelection.isEcosiaEngineID($0.engineID) }) else {
            return engines
        }
        return [CuratedSearchEngines.ecosiaEngine()] + engines
    }

    /// Applies persisted engine ordering, optionally restricting to a known ID set.
    static func applyPersistedOrdering(from prefs: SearchEnginePrefs,
                                     to availableEngines: [OpenSearchEngine],
                                     restrictingTo allowedIDs: Set<String>? = nil) -> [OpenSearchEngine] {
        guard let orderedIDs = prefs.engineIdentifiers, !orderedIDs.isEmpty else {
            return availableEngines
        }

        var ordered: [OpenSearchEngine] = []
        var remaining = availableEngines

        for engineID in orderedIDs {
            guard allowedIDs == nil || allowedIDs?.contains(engineID) == true else { continue }
            guard let index = remaining.firstIndex(where: { $0.engineID == engineID }) else { continue }
            ordered.append(remaining.remove(at: index))
        }

        if ordered.isEmpty {
            return availableEngines
        }

        let trailing = remaining.filter { engine in
            allowedIDs == nil || allowedIDs?.contains(engine.engineID) == true
        }
        return ordered + trailing
    }

    /// Moves the user's selected engine to the default (index 0) slot when possible.
    static func promoteSelectedSearchProvider(in engines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return engines }

        let selectedID = User.shared.selectedSearchEngineID
        guard let selectedIndex = engines.firstIndex(where: { $0.engineID == selectedID }),
              selectedIndex != 0 else { return engines }

        var reordered = engines
        let selectedEngine = reordered.remove(at: selectedIndex)
        reordered.insert(selectedEngine, at: 0)
        return reordered
    }

    /// Orders engines by a preferred ID list (used for offline fallbacks).
    static func orderByPreferredIDs(_ preferredIDs: [String],
                                    in engines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        let ordered = preferredIDs.compactMap { id in engines.first { $0.engineID == id } }
        let orderedIDs = Set(ordered.map(\.engineID))
        let trailing = engines.filter { !orderedIDs.contains($0.engineID) }
        return ordered + trailing
    }
}
