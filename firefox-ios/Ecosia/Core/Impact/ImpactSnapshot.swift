// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A point-in-time impact snapshot - seed count, level and progress - regardless of whether it
/// came from the server (logged in) or was computed locally (logged out).
public struct ImpactSnapshot: Equatable, Sendable {
    public let seedCount: Int
    public let currentLevelNumber: Int
    public let currentProgress: Double
    /// The Auth0 `sub` of the user this snapshot belongs to, or `nil` for the guest/logged-out
    /// snapshot. Lets a single shared cache slot be validated against whoever is currently active
    /// instead of trusted blindly.
    public let loggedInUserID: String?

    public init(seedCount: Int, currentLevelNumber: Int, currentProgress: Double, loggedInUserID: String? = nil) {
        self.seedCount = seedCount
        self.currentLevelNumber = currentLevelNumber
        self.currentProgress = currentProgress
        self.loggedInUserID = loggedInUserID
    }

    /// The default snapshot for a guest with no history yet: 0 seeds, level 1, no progress.
    public static let loggedOutZero = ImpactSnapshot(seedCount: 0, currentLevelNumber: 1, currentProgress: 0, loggedInUserID: nil)
}
