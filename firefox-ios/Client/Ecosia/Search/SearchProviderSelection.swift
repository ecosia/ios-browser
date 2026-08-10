// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

/// Keeps `User.shared.selectedSearchEngineID` in sync with the active default search engine.
/// Used by analytics, omnibox gating, and Ecosia-only settings visibility.
enum SearchProviderSelection {

    static let ecosiaEngineID = "ecosia"

    static var isEcosiaDefault: Bool {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return true }
        return User.shared.selectedSearchEngineID == ecosiaEngineID
    }

    static func isEcosiaEngineID(_ engineID: String) -> Bool {
        engineID == ecosiaEngineID
    }

    static func syncSelectedEngineID(_ engineID: String?) {
        guard CustomSearchProviderFeatureFlag.isEnabled else {
            if User.shared.selectedSearchEngineID != ecosiaEngineID {
                User.shared.selectedSearchEngineID = ecosiaEngineID
            }
            return
        }

        let resolvedID = engineID ?? ecosiaEngineID
        guard User.shared.selectedSearchEngineID != resolvedID else { return }
        User.shared.selectedSearchEngineID = resolvedID
    }

    /// Records a Snowplow event when the user returns from the search provider picker
    /// with a different default engine than when they opened it.
    static func recordSearchProviderChangedIfNeeded(from previousEngineID: String, to newEngineID: String) {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return }
        guard previousEngineID != newEngineID else { return }
        Analytics.shared.searchProviderChanged(to: newEngineID)
    }
}
