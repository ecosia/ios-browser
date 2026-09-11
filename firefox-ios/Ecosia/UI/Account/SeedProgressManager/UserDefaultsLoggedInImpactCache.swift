// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// `UserDefaults`-backed implementation of `LoggedInImpactCacheProtocol`.
///
/// Keyed to the Auth0 `sub` that saved it, so a different account logging in on the same device
/// never inherits stale numbers from the previous one - `load(forUserId:)` returns `nil` unless the
/// stored snapshot belongs to the requested user.
public final class UserDefaultsLoggedInImpactCache: LoggedInImpactCacheProtocol {

    private static let seedCountKey = "LoggedInImpactCache.seedCount"
    private static let currentLevelNumberKey = "LoggedInImpactCache.currentLevelNumber"
    private static let currentProgressKey = "LoggedInImpactCache.currentProgress"
    private static let userIdKey = "LoggedInImpactCache.userId"

    private init() {}

    public static func load(forUserId userId: String) -> ImpactSnapshot? {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: userIdKey) == userId,
              defaults.object(forKey: seedCountKey) != nil else {
            return nil
        }
        return ImpactSnapshot(
            seedCount: defaults.integer(forKey: seedCountKey),
            currentLevelNumber: defaults.integer(forKey: currentLevelNumberKey),
            currentProgress: defaults.double(forKey: currentProgressKey)
        )
    }

    public static func save(_ snapshot: ImpactSnapshot, userId: String) {
        let defaults = UserDefaults.standard
        defaults.set(snapshot.seedCount, forKey: seedCountKey)
        defaults.set(snapshot.currentLevelNumber, forKey: currentLevelNumberKey)
        defaults.set(snapshot.currentProgress, forKey: currentProgressKey)
        defaults.set(userId, forKey: userIdKey)
    }

    public static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: seedCountKey)
        defaults.removeObject(forKey: currentLevelNumberKey)
        defaults.removeObject(forKey: currentProgressKey)
        defaults.removeObject(forKey: userIdKey)
    }
}
