// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// `UserDefaults`-backed implementation of `LoggedInImpactCacheProtocol`. A single slot, cleared
/// on logout before a different account could read it.
public final class LoggedInImpactCache: LoggedInImpactCacheProtocol {

    private static let seedCountKey = "LoggedInImpactCache.seedCount"
    private static let currentLevelNumberKey = "LoggedInImpactCache.currentLevelNumber"
    private static let currentProgressKey = "LoggedInImpactCache.currentProgress"

    private init() {}

    public static func load() -> ImpactSnapshot? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: seedCountKey) != nil else {
            return nil
        }
        return ImpactSnapshot(
            seedCount: defaults.integer(forKey: seedCountKey),
            currentLevelNumber: defaults.integer(forKey: currentLevelNumberKey),
            currentProgress: defaults.double(forKey: currentProgressKey)
        )
    }

    public static func save(_ snapshot: ImpactSnapshot) {
        let defaults = UserDefaults.standard
        defaults.set(snapshot.seedCount, forKey: seedCountKey)
        defaults.set(snapshot.currentLevelNumber, forKey: currentLevelNumberKey)
        defaults.set(snapshot.currentProgress, forKey: currentProgressKey)
    }

    public static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: seedCountKey)
        defaults.removeObject(forKey: currentLevelNumberKey)
        defaults.removeObject(forKey: currentProgressKey)
    }
}
