// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The level ladder shown in the 4×4 widget: a sliding window of four levels across the full
/// ladder — two unlocked behind, the current level, one locked ahead — clamped at both ends.
///
/// Pure value logic, deliberately free of SwiftUI so it can be unit tested from the app target.
public enum SeedLevelLadder {

    /// How many badges the ladder shows at once.
    public static let visibleRungCount = 4

    public enum BadgeState: Equatable {
        case unlocked
        case current
        case locked
    }

    public struct Rung: Equatable {
        public let level: Int
        public let name: String
        public let state: BadgeState

        public init(level: Int, name: String, state: BadgeState) {
            self.level = level
            self.name = name
            self.state = state
        }
    }

    /// The four badges to draw for a signed-in user.
    ///
    /// The window starts two levels behind the current one and is clamped so it never runs past
    /// either end of the ladder. At the top of the ladder the trailing badge is unlocked rather
    /// than locked — there is never more than one locked badge.
    public static func rungs(currentLevel: Int, levelNames: [String]) -> [Rung] {
        guard !levelNames.isEmpty else { return [] }

        let maxLevel = levelNames.count
        let clampedCurrent = min(max(currentLevel, 1), maxLevel)
        let lastPossibleStart = max(1, maxLevel - visibleRungCount + 1)
        let start = min(max(clampedCurrent - 2, 1), lastPossibleStart)
        let end = min(start + visibleRungCount - 1, maxLevel)

        return (start...end).map { level in
            Rung(level: level, name: levelNames[level - 1], state: badgeState(for: level, currentLevel: clampedCurrent))
        }
    }

    /// The teaser ladder shown to logged-out users: the first four levels, all locked.
    public static func teaserRungs(levelNames: [String]) -> [Rung] {
        levelNames.prefix(visibleRungCount).enumerated().map { index, name in
            Rung(level: index + 1, name: name, state: .locked)
        }
    }

    /// The localized name of a level, or `nil` when it is outside the ladder.
    public static func name(for level: Int, levelNames: [String]) -> String? {
        guard level >= 1, level <= levelNames.count else { return nil }
        return levelNames[level - 1]
    }

    /// The localized name of the next level, or `nil` at the top of the ladder.
    public static func nextLevelName(currentLevel: Int, levelNames: [String]) -> String? {
        name(for: currentLevel + 1, levelNames: levelNames)
    }

    /// Whether the user has reached the final level, where there is no next level to show.
    public static func isTopLevel(currentLevel: Int, levelNames: [String]) -> Bool {
        !levelNames.isEmpty && currentLevel >= levelNames.count
    }

    // MARK: - Private

    private static func badgeState(for level: Int, currentLevel: Int) -> BadgeState {
        if level < currentLevel { return .unlocked }
        if level == currentLevel { return .current }
        return .locked
    }
}
