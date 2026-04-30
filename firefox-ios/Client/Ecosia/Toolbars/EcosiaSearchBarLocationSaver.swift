// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Ecosia

struct EcosiaSearchBarLocationSaver: SearchBarLocationProvider, FeatureFlaggable, SearchBarLocationSaverProtocol {
    /// One-shot upgrade migration introduced with the AI-ready Omnibox (MOB-4304).
    /// Existing users who had the address bar pinned to the top are moved to the
    /// bottom on next launch, so the Omnibox can replace the URL bar on the NTP
    /// for everyone. Users may opt back to top afterwards — we never override again.
    static let didMigrateToBottomToolbarKey = "EcosiaDidMigrateToBottomToolbarForOmnibox"

    @MainActor
    func saveUserSearchBarLocation(profile: Profile,
                                   userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        let hasSearchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition) != nil

        if !hasSearchBarPosition, User.shared.firstTime {
            featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.bottom)
            UserDefaults.standard.set(true, forKey: Self.didMigrateToBottomToolbarKey)
            return
        }

        migrateExistingTopUserToBottomIfNeeded(profile: profile)
    }

    @MainActor
    private func migrateExistingTopUserToBottomIfNeeded(profile: Profile) {
        guard !UserDefaults.standard.bool(forKey: Self.didMigrateToBottomToolbarKey) else { return }
        defer { UserDefaults.standard.set(true, forKey: Self.didMigrateToBottomToolbarKey) }

        guard isBottomSearchBar == false else { return }
        featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.bottom)
    }
}
