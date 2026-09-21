// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import Foundation

/// Records every write and mirrors production `ImpactCache.save`'s notification-posting contract,
/// so tests exercising `LoggedInImpactUpdater`/`LoggedOutSeedProgressManager` end-to-end through
/// `EcosiaAuthUIStateProvider` see the same reactive behavior a real `ImpactCache` would produce -
/// backed by an in-memory value instead of `UserDefaults`, so tests never touch real storage or
/// leak state between runs.
final class MockImpactCache: ImpactCacheProtocol, @unchecked Sendable {
    var stored: ImpactSnapshot?
    private(set) var savedSnapshots: [ImpactSnapshot] = []
    private(set) var lastSeedsIncrement: Int?
    private(set) var lastDidLevelUp: Bool?

    func load() -> ImpactSnapshot? {
        stored
    }

    func save(_ snapshot: ImpactSnapshot, seedsIncrement: Int?, didLevelUp: Bool) {
        stored = snapshot
        savedSnapshots.append(snapshot)
        lastSeedsIncrement = seedsIncrement
        lastDidLevelUp = didLevelUp

        var userInfo: [String: Any] = [
            ImpactCache.snapshotUserInfoKey: snapshot,
            ImpactCache.didLevelUpUserInfoKey: didLevelUp
        ]
        if let seedsIncrement {
            userInfo[ImpactCache.seedsIncrementUserInfoKey] = seedsIncrement
        }
        NotificationCenter.default.post(name: .EcosiaImpactCacheUpdated, object: nil, userInfo: userInfo)
    }
}
