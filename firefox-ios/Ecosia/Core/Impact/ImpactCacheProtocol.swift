// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Persists the last known seed/level/progress for whichever identity is active - a guest, or a
/// specific logged-in user - so the UI can show real numbers immediately on cold launch instead of
/// a placeholder. Shared by both the logged-in (`LoggedInImpactUpdater`) and logged-out
/// (`LoggedOutSeedProgressManager`) write paths: `ImpactSnapshot.loggedInUserID` records whose data
/// is currently stored, so a reader can tell whether the cached value is actually theirs.
public protocol ImpactCacheProtocol: Sendable {
    /// Returns the cached snapshot, or `nil` if there is none yet.
    func load() -> ImpactSnapshot?

    /// Persists a snapshot and posts `.EcosiaImpactCacheUpdated` so any observer reacts, regardless
    /// of which writer produced it.
    ///
    /// `seedsIncrement`/`didLevelUp` describe what genuinely changed *as part of this write* - the
    /// writer's own authoritative signal (e.g. `AccountVisitResponse.seedsIncrement`, which the
    /// backend only sets when it actually modified the balance during this visit). They must not be
    /// derived by diffing this snapshot against whatever was previously displayed: on a first login,
    /// the account's real balance can be wildly different from the guest's local count without a
    /// single new seed having been earned, so that diff would misreport a fake "you just earned N" animation.
    func save(_ snapshot: ImpactSnapshot, seedsIncrement: Int?, didLevelUp: Bool)
}

extension Notification.Name {
    /// Posted by `ImpactCacheProtocol.save` whenever the shared impact cache is written, by either
    /// the logged-in or logged-out path. `userInfo` carries `ImpactCache.snapshotUserInfoKey` (the
    /// new `ImpactSnapshot`), `ImpactCache.didLevelUpUserInfoKey` (`Bool`), and optionally
    /// `ImpactCache.seedsIncrementUserInfoKey` (`Int`, present only when seeds were actually earned).
    public static let EcosiaImpactCacheUpdated = Notification.Name("EcosiaImpactCacheUpdated")
}
