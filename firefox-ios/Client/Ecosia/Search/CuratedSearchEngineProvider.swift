// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Shared
import UIKit

/// Search engine provider used when `CustomSearchProviderFeatureFlag` is enabled.
///
/// Returns a curated list of engines (Ecosia, Google, Bing, DuckDuckGo). Ecosia is the
/// default on first launch; the user's persisted ordering determines the active default afterward.
final class CuratedSearchEngineProvider: SearchEngineProvider, Sendable {

    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v2

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        let availableEngines = CuratedSearchEngines.allEngines()
        let finalPrefs = prefsMigrator.migratePrefsIfNeeded(engineOrderingPrefs,
                                                            to: preferencesVersion,
                                                            availableEngines: availableEngines)
        let orderedEngines = applyOrdering(from: finalPrefs, availableEngines: availableEngines)

        ensureMainThread {
            SearchProviderSelection.syncSelectedEngineID(orderedEngines.first?.engineID)
            completion(finalPrefs, orderedEngines)
        }
    }

    // MARK: - Private

    private func applyOrdering(from prefs: SearchEnginePrefs,
                               availableEngines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        guard let orderedIDs = prefs.engineIdentifiers, !orderedIDs.isEmpty else {
            return orderEngines(availableEngines, preferredIDs: CuratedSearchEngines.defaultOrder)
        }

        var ordered: [OpenSearchEngine] = []
        var remaining = availableEngines

        for engineID in orderedIDs where CuratedSearchEngines.defaultOrder.contains(engineID) {
            guard let index = remaining.firstIndex(where: { $0.engineID == engineID }) else { continue }
            ordered.append(remaining.remove(at: index))
        }

        if ordered.isEmpty {
            return orderEngines(availableEngines, preferredIDs: CuratedSearchEngines.defaultOrder)
        }

        // Append any curated engines missing from persisted prefs (e.g. after an app upgrade).
        let missing = CuratedSearchEngines.defaultOrder.compactMap { id in
            remaining.first { $0.engineID == id }
        }
        return promoteSelectedSearchProvider(in: ordered + missing)
    }

    private func promoteSelectedSearchProvider(in engines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return engines }

        let selectedID = User.shared.selectedSearchEngineID
        guard let selectedIndex = engines.firstIndex(where: { $0.engineID == selectedID }),
              selectedIndex != 0 else { return engines }

        var reordered = engines
        let selectedEngine = reordered.remove(at: selectedIndex)
        reordered.insert(selectedEngine, at: 0)
        return reordered
    }

    private func orderEngines(_ engines: [OpenSearchEngine],
                              preferredIDs: [String]) -> [OpenSearchEngine] {
        let ordered = preferredIDs.compactMap { id in engines.first { $0.engineID == id } }
        return promoteSelectedSearchProvider(in: ordered)
    }
}
