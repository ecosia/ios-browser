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
///
/// The medium and large families additionally need the level state. Level names are resolved
/// app-side by `GrowthPointsLevelSystem` and handed over as finished localized strings — the
/// extension never derives them.
public struct SeedWidgetSnapshot: Codable {
    public let seedCount: Int
    /// Progress toward the next level, in the range 0…1.
    public let levelProgress: Double
    public let isSignedIn: Bool
    public let updatedAt: Date
    /// The user's current level number, 1-based. 1 when no level data is available.
    public let currentLevel: Int
    /// Localized names for every level, ordered by level; index 0 is level 1.
    /// Empty when the app has not resolved them yet (e.g. logged out).
    public let levelNames: [String]
    /// Growth points still needed to reach the next level.
    public let growthPointsRemaining: Int
    /// File name of the account avatar inside the shared app-group container, or `nil`
    /// when the user has no avatar. The avatar element is omitted entirely when this is `nil`.
    public let avatarFileName: String?

    public init(
        seedCount: Int,
        levelProgress: Double,
        isSignedIn: Bool,
        currentLevel: Int = 1,
        levelNames: [String] = [],
        growthPointsRemaining: Int = 0,
        avatarFileName: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.seedCount = seedCount
        self.levelProgress = levelProgress
        self.isSignedIn = isSignedIn
        self.currentLevel = currentLevel
        self.levelNames = levelNames
        self.growthPointsRemaining = growthPointsRemaining
        self.avatarFileName = avatarFileName
        self.updatedAt = updatedAt
    }

    // MARK: - Decoding

    /// Decoded field by field so a snapshot written by an older app version — which only carried
    /// the three small-widget values — still yields a usable entry after an app update.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seedCount = try container.decode(Int.self, forKey: .seedCount)
        levelProgress = try container.decode(Double.self, forKey: .levelProgress)
        isSignedIn = try container.decode(Bool.self, forKey: .isSignedIn)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        currentLevel = try container.decodeIfPresent(Int.self, forKey: .currentLevel) ?? 1
        levelNames = try container.decodeIfPresent([String].self, forKey: .levelNames) ?? []
        growthPointsRemaining = try container.decodeIfPresent(Int.self, forKey: .growthPointsRemaining) ?? 0
        avatarFileName = try container.decodeIfPresent(String.self, forKey: .avatarFileName)
    }

    // MARK: - Shared app-group container

    /// Directory shared between the app and the widget extension, used for the avatar image.
    public static func sharedContainerURL(appGroupIdentifier: String) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    /// Full URL of the avatar image, or `nil` when there is none to draw.
    public func avatarFileURL(appGroupIdentifier: String) -> URL? {
        guard let avatarFileName,
              let container = Self.sharedContainerURL(appGroupIdentifier: appGroupIdentifier)
        else { return nil }
        return container.appendingPathComponent(avatarFileName)
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
