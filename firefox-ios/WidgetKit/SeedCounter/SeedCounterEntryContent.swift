// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import Foundation
// Ecosia: import Ecosia for String.localized, which resolves the Ecosia strings table
// from the framework bundle linked into this extension.
import Ecosia

/// The copy deck of the seed widgets, derived from the entry in one place so the medium and
/// large layouts — and their accessibility labels — can never drift apart.
extension SeedCounterEntry {

    /// Placeholder stand-in used wherever a value would otherwise be read from data.
    private static let redactedValue = "—"

    // MARK: State

    /// Signed in but nothing collected yet: the layout stays intact and the copy switches.
    var isEmptyState: Bool { isSignedIn && seedCount == 0 && !isPlaceholder }

    var isTopLevel: Bool { SeedLevelLadder.isTopLevel(currentLevel: currentLevel, levelNames: levelNames) }

    var currentLevelName: String? { SeedLevelLadder.name(for: currentLevel, levelNames: levelNames) }

    var nextLevelName: String? {
        SeedLevelLadder.nextLevelName(currentLevel: currentLevel, levelNames: levelNames)
    }

    /// The value both the jar and the bar are drawn from — they restate the same number and
    /// must never disagree. The bar renders full once there is no next level to reach.
    var displayProgress: Double {
        isTopLevel ? 1 : max(0, min(1, levelProgress))
    }

    // MARK: Counts

    var countText: String {
        isPlaceholder ? Self.redactedValue : "\(seedCount)"
    }

    // MARK: Capsule

    var capsuleText: String {
        guard !isPlaceholder else {
            return "\(String.localized(.level)) \(Self.redactedValue) · \(Self.redactedValue)"
        }
        let name = currentLevelName ?? Self.redactedValue
        return "\(String.localized(.level)) \(currentLevel) · \(name)"
    }

    // MARK: Captions

    /// 4×2 — one line under the bar.
    var mediumCaption: String {
        if isPlaceholder { return Self.redactedValue }
        if isEmptyState { return String.localized(.searchToPlantYourFirstSeed) }
        guard let nextLevelName else { return String.localized(.topLevelReached) }
        return String(format: String.localized(.growthPointsToLevel), growthPointsRemaining, nextLevelName)
    }

    /// 4×4 — the left half of the caption row.
    var largeLeadingCaption: String {
        if isPlaceholder { return Self.redactedValue }
        if isEmptyState { return String.localized(.searchToEarnGrowthPoints) }
        guard nextLevelName != nil else { return String.localized(.topLevelReached) }
        return String(format: String.localized(.growthPointsToGo), growthPointsRemaining)
    }

    /// 4×4 — the right half of the caption row, which carries the emphasis colour because it is
    /// the reward. Absent at the top of the ladder, where there is no next level.
    var largeTrailingCaption: String? {
        if isPlaceholder { return Self.redactedValue }
        guard let nextLevelName else { return nil }
        return String(format: String.localized(.nextLevelName), nextLevelName)
    }

    // MARK: Ladder

    /// The four badges to draw: the sliding window for signed-in users, the teaser for
    /// logged-out ones.
    var ladderRungs: [SeedLevelLadder.Rung] {
        isSignedIn
            ? SeedLevelLadder.rungs(currentLevel: currentLevel, levelNames: levelNames)
            : SeedLevelLadder.teaserRungs(levelNames: levelNames)
    }

    var ladderLabel: String {
        isSignedIn ? String.localized(.levelsUnlocked) : String.localized(.levelsYouWillUnlock)
    }

    // MARK: Accessibility

    /// One combined label per widget; the children are ignored.
    var mediumAccessibilityLabel: String {
        sentences(mediumAccessibilitySentences)
    }

    var largeAccessibilityLabel: String {
        sentences(mediumAccessibilitySentences + ladderAccessibilitySentences)
    }

    private var mediumAccessibilitySentences: [String] {
        let seeds = String(format: String.localized(.seedCountAccessibilityLabel), seedCount)
        guard isSignedIn else {
            return [seeds, String.localized(.signUpToKeepSeedsAndLevelUp)]
        }
        var result = [seeds]
        if let currentLevelName {
            result.append(String(format: String.localized(.widgetLevelAccessibilityLabel),
                                 currentLevel,
                                 currentLevelName))
        }
        result.append(mediumCaption)
        return result
    }

    private var ladderAccessibilitySentences: [String] {
        let rungs = ladderRungs
        guard !rungs.isEmpty else { return [] }

        var result: [String] = []
        let unlocked = rungs.filter { $0.state != .locked }.map(\.name)
        if !unlocked.isEmpty {
            result.append(String(format: String.localized(.widgetUnlockedLevelsAccessibilityLabel),
                                 unlocked.joined(separator: ", ")))
        }
        if let locked = rungs.first(where: { $0.state == .locked }) {
            result.append(String(format: String.localized(.widgetNextLevelLockedAccessibilityLabel), locked.name))
        }
        return result
    }

    private func sentences(_ parts: [String]) -> String {
        parts
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
            .joined(separator: " ")
    }
}
#endif
