// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Shared

/// Search engine provider used when `CustomSearchProviderFeatureFlag` is enabled.
///
/// Fetches Mozilla's locale-specific engine list via Application Services, injects
/// Ecosia when missing, and falls back to the bundled curated list when Remote
/// Settings is unavailable.
final class HybridSearchEngineProvider: SearchEngineProvider, Sendable {

    private let remoteProvider: ASSearchEngineProvider
    private let fallbackEngines: [OpenSearchEngine]

    init(remoteProvider: ASSearchEngineProvider = ASSearchEngineProvider(),
         fallbackEngines: [OpenSearchEngine] = CuratedSearchEngines.allEngines()) {
        self.remoteProvider = remoteProvider
        self.fallbackEngines = fallbackEngines
    }

    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v2

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        let fallback = fallbackEngines
        remoteProvider.getOrderedEngines(customEngines: customEngines,
                                         engineOrderingPrefs: engineOrderingPrefs,
                                         prefsMigrator: prefsMigrator) { prefs, remoteEngines in
            let baseEngines = remoteEngines.isEmpty ? fallback : remoteEngines
            let withEcosia = SearchProviderEngineOrdering.insertingEcosiaIfNeeded(into: baseEngines)
            let migratedPrefs = prefsMigrator.migratePrefsIfNeeded(engineOrderingPrefs,
                                                                   to: self.preferencesVersion,
                                                                   availableEngines: withEcosia)
            var orderedEngines = SearchProviderEngineOrdering.applyPersistedOrdering(from: migratedPrefs,
                                                                                     to: withEcosia)

            if orderedEngines.isEmpty {
                orderedEngines = SearchProviderEngineOrdering.orderByPreferredIDs(
                    CuratedSearchEngines.fallbackDefaultOrder,
                    in: withEcosia
                )
            }

            orderedEngines = SearchProviderEngineOrdering.promoteSelectedSearchProvider(in: orderedEngines)

            ensureMainThread {
                SearchProviderSelection.syncSelectedEngineID(orderedEngines.first?.engineID)
                completion(migratedPrefs, orderedEngines)
            }
        }
    }
}
