// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Ecosia

struct EcosiaSearchBarLocationSaver: SearchBarLocationProvider, FeatureFlaggable, SearchBarLocationSaverProtocol {
    @MainActor
    func saveUserSearchBarLocation(profile: Profile,
                                   userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        let hasSearchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition) != nil

        guard !hasSearchBarPosition else { return }

        if User.shared.firstTime {
            featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.bottom)
        }
    }
}
