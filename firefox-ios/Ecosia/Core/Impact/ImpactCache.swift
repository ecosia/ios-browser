// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// `UserDefaults`-backed implementation of `ImpactCacheProtocol`. Holds no state of its own beyond
/// `UserDefaults.standard`, so any number of instances are interchangeable.
public final class ImpactCache: ImpactCacheProtocol {

    /// Key into `.EcosiaImpactCacheUpdated`'s `userInfo` for the new `ImpactSnapshot`.
    public static let snapshotUserInfoKey = "snapshot"
    /// Key into `.EcosiaImpactCacheUpdated`'s `userInfo` for the `Int` seeds increment. Absent when
    /// no seeds were actually earned as part of this write.
    public static let seedsIncrementUserInfoKey = "seedsIncrement"
    /// Key into `.EcosiaImpactCacheUpdated`'s `userInfo` for the `Bool` level-up flag.
    public static let didLevelUpUserInfoKey = "didLevelUp"

    private static let seedCountKey = "ImpactCache.seedCount"
    private static let currentLevelNumberKey = "ImpactCache.currentLevelNumber"
    private static let currentProgressKey = "ImpactCache.currentProgress"
    private static let loggedInUserIDKey = "ImpactCache.loggedInUserID"

    public init() {}

    public func load() -> ImpactSnapshot? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Self.seedCountKey) != nil else { return nil }
        return ImpactSnapshot(
            seedCount: defaults.integer(forKey: Self.seedCountKey),
            currentLevelNumber: defaults.integer(forKey: Self.currentLevelNumberKey),
            currentProgress: defaults.double(forKey: Self.currentProgressKey),
            loggedInUserID: defaults.string(forKey: Self.loggedInUserIDKey)
        )
    }

    public func save(_ snapshot: ImpactSnapshot, seedsIncrement: Int?, didLevelUp: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(snapshot.seedCount, forKey: Self.seedCountKey)
        defaults.set(snapshot.currentLevelNumber, forKey: Self.currentLevelNumberKey)
        defaults.set(snapshot.currentProgress, forKey: Self.currentProgressKey)
        if let loggedInUserID = snapshot.loggedInUserID {
            defaults.set(loggedInUserID, forKey: Self.loggedInUserIDKey)
        } else {
            defaults.removeObject(forKey: Self.loggedInUserIDKey)
        }

        var userInfo: [String: Any] = [
            Self.snapshotUserInfoKey: snapshot,
            Self.didLevelUpUserInfoKey: didLevelUp
        ]
        if let seedsIncrement {
            userInfo[Self.seedsIncrementUserInfoKey] = seedsIncrement
        }
        NotificationCenter.default.post(name: .EcosiaImpactCacheUpdated, object: nil, userInfo: userInfo)
    }

    /// For testing: clears all persisted keys directly and silently (no notification) - unlike
    /// production writers, which always write a well-formed snapshot instead of a bare absence.
    func resetForTesting() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.seedCountKey)
        defaults.removeObject(forKey: Self.currentLevelNumberKey)
        defaults.removeObject(forKey: Self.currentProgressKey)
        defaults.removeObject(forKey: Self.loggedInUserIDKey)
    }
}
