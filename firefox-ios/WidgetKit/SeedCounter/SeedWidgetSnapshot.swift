// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The WidgetKit `kind` identifier for the seed counter widget, shared between the
/// app target (for `WidgetCenter.shared.reloadTimelines`) and the extension target.
public let SeedCounterWidgetKind = "Seed Counter - Small"

/// A lightweight, Codable snapshot of the user's seed state written by the app into the shared
/// app-group UserDefaults so the WidgetKit extension can read it without accessing the main
/// app's private UserDefaults.
public struct SeedWidgetSnapshot: Codable {
    public let seedCount: Int
    /// Progress toward the next level, in the range 0…1.
    public let levelProgress: Double
    public let isSignedIn: Bool
    public let updatedAt: Date

    public init(seedCount: Int, levelProgress: Double, isSignedIn: Bool, updatedAt: Date = Date()) {
        self.seedCount = seedCount
        self.levelProgress = levelProgress
        self.isSignedIn = isSignedIn
        self.updatedAt = updatedAt
    }

    // MARK: - Shared UserDefaults persistence

    private static let key = "com.ecosia.widget.SeedWidgetSnapshot"

    public static func load(from userDefaults: UserDefaults) -> SeedWidgetSnapshot? {
        guard let data = userDefaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(SeedWidgetSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    public func save(to userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        userDefaults.set(data, forKey: Self.key)
    }
}
