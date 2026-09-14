// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A point-in-time impact snapshot - seedCount/currentLevelNumber/currentProgress - regardless of
/// whether it came from the server (logged-in, via `LoggedInImpactCacheProtocol`) or was computed
/// locally (logged-out, via `SeedProgressManagerProtocol.currentSnapshot()`). `EcosiaAuthUIStateProvider`
/// publishes these three values as flat properties either way, so the shape is shared on purpose.
public struct ImpactSnapshot: Equatable {
    public let seedCount: Int
    public let currentLevelNumber: Int
    public let currentProgress: Double

    public init(seedCount: Int, currentLevelNumber: Int, currentProgress: Double) {
        self.seedCount = seedCount
        self.currentLevelNumber = currentLevelNumber
        self.currentProgress = currentProgress
    }
}
