// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// `UserDefaults`-backed implementation of `ImpactCacheProtocol`. Holds no state of its own beyond
/// `UserDefaults.standard`, so any number of instances are interchangeable.
public final class ImpactCache: ImpactCacheProtocol {

    private static let seedCountKey = "ImpactCache.seedCount"
    private static let currentLevelNumberKey = "ImpactCache.currentLevelNumber"
    private static let currentProgressKey = "ImpactCache.currentProgress"

    public init() {}

    public func load() -> ImpactSnapshot? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Self.seedCountKey) != nil else {
            return nil
        }
        return ImpactSnapshot(
            seedCount: defaults.integer(forKey: Self.seedCountKey),
            currentLevelNumber: defaults.integer(forKey: Self.currentLevelNumberKey),
            currentProgress: defaults.double(forKey: Self.currentProgressKey)
        )
    }

    public func save(_ snapshot: ImpactSnapshot) {
        let defaults = UserDefaults.standard
        defaults.set(snapshot.seedCount, forKey: Self.seedCountKey)
        defaults.set(snapshot.currentLevelNumber, forKey: Self.currentLevelNumberKey)
        defaults.set(snapshot.currentProgress, forKey: Self.currentProgressKey)
    }

    public func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.seedCountKey)
        defaults.removeObject(forKey: Self.currentLevelNumberKey)
        defaults.removeObject(forKey: Self.currentProgressKey)
    }
}
