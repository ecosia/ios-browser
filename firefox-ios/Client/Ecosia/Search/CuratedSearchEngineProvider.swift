// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Shared

/// Search engine provider used when `CustomSearchProviderFeatureFlag` is enabled.
///
/// The list comes entirely from the bundled `SearchProvider` catalog rather than from
/// Remote Settings: the offered providers and their result URLs are fixed, and two of
/// them are not search engines Remote Settings knows about.
///
/// - TODO: Revisit if locale-specific engine variants (google.de and similar) are wanted.
/// Remote Settings supplies those, but also brings back its client-tagged result
/// templates, so they would need overriding from the catalog.
final class CuratedSearchEngineProvider: SearchEngineProvider, Sendable {

    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v2

    private let configProvider: @Sendable () -> SearchRouterConfig

    init(configProvider: @escaping @Sendable () -> SearchRouterConfig = { CustomSearchProviderFeatureFlag.config }) {
        self.configProvider = configProvider
    }

    /// `customEngines` is ignored: the picker offers a fixed list and has no add or
    /// delete affordance while the router is on.
    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        let engines = SearchProviderEngineOrdering.promoteSelectedSearchProvider(
            in: CuratedSearchEngines.engines(for: configProvider().providers)
        )

        ensureMainThread {
            SearchProviderSelection.syncSelectedEngineID(engines.first?.engineID)
            completion(engineOrderingPrefs, engines)
        }
    }
}
