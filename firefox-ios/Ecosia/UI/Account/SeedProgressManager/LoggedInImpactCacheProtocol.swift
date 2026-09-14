// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Persists the last known server-reported seed/level/progress for a logged-in user, so the UI can
/// show real numbers immediately on cold launch instead of the logged-out cap
/// (`SeedProgressManager.maxSeedsForLoggedOutUsers`) while a fresh value is fetched.
public protocol LoggedInImpactCacheProtocol {
    /// Returns the cached snapshot, or `nil` if there is none or it belongs to a different user.
    static func load(forUserId userId: String) -> ImpactSnapshot?

    /// Persists a snapshot, tagged with the user it belongs to.
    static func save(_ snapshot: ImpactSnapshot, userId: String)

    /// Clears any cached snapshot, regardless of which user it belonged to.
    static func clear()
}

extension LoggedInImpactCacheProtocol {
    /// Shared vocabulary with `SeedProgressManagerProtocol.clearOnLogout()`: `EcosiaAuthUIStateProvider`
    /// calls both stores by this same name on logout, without needing to know each store's own
    /// reason for clearing.
    public static func clearOnLogout() {
        clear()
    }
}
