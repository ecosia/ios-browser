// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Ecosia

struct EcosiaSearchBarLocationSaver: SearchBarLocationProvider,
                                     UserFeaturePreferenceProvider,
                                     SearchBarLocationSaverProtocol {
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
            userPreferences.setSearchBarPosition(.bottom)
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
        userPreferences.setSearchBarPosition(.bottom)
    }

    /// Ecosia: `SearchBarLocationSaverProtocol` gained this member in Firefox 155.1. Ecosia does not
    /// call it (see `AppLaunchUtil.setUpPreLaunchDependencies`) because the MOB-4304 migration above
    /// deliberately puts every device on the bottom Omnibox; both `isBottomSearchBar` and
    /// `UserFeaturePreferenceManager.searchBarPosition` already clamp iPad to `.top`, so the stored
    /// value is not observable there. Delegating keeps upstream's semantics for any other caller.
    @MainActor
    func migrateBottomBarPositionToTopOnIPad(
        profile: Profile,
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) {
        SearchBarLocationSaver().migrateBottomBarPositionToTopOnIPad(
            profile: profile,
            userInterfaceIdiom: userInterfaceIdiom
        )
    }
}
