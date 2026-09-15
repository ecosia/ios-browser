// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Persists the last known server-reported seed/level/progress for a logged-in user, so the UI can
/// show real numbers immediately on cold launch instead of the logged-out cap
/// (`SeedProgressManager.maxSeedsForLoggedOutUsers`) while a fresh value is fetched.
///
/// A single slot, not tagged by user id: at cold launch, auth state can still be resolving when
/// this is read (`isLoggedIn`/the user id can lag behind by however long the userinfo network
/// call takes), so a cached snapshot must be readable before any user id is even known - the
/// alternative is flashing the logged-out number for a returning logged-in user. `clear()` on
/// logout, before a different account could read it, is what protects against a stale value
/// crossing accounts.
public protocol LoggedInImpactCacheProtocol {
    /// Returns the cached snapshot, or `nil` if there is none.
    static func load() -> ImpactSnapshot?

    /// Persists a snapshot.
    static func save(_ snapshot: ImpactSnapshot)

    /// Clears any cached snapshot.
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
