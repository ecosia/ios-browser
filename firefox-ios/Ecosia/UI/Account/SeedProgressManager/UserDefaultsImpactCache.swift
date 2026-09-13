// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// `UserDefaults`-backed implementation of `ImpactCacheProtocol`, shared by both the logged-in
/// cache in `EcosiaAuthUIStateProvider` and `UserDefaultsSeedProgressManager`'s logged-out storage.
public final class UserDefaultsImpactCache: ImpactCacheProtocol {

    private static let seedCountKey = "ImpactCache.seedCount"
    private static let currentLevelNumberKey = "ImpactCache.currentLevelNumber"
    private static let currentProgressKey = "ImpactCache.currentProgress"
    private static let userIdKey = "ImpactCache.userId"

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
