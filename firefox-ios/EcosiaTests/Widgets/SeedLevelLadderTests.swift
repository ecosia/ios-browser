// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

/// Tests for the sliding window of four levels shown by the 4×4 seed widget's ladder.
final class SeedLevelLadderTests: XCTestCase {

    private let levelNames = (1...20).map { "Level \($0) name" }

    // MARK: - Window position

    func testWindowShowsTwoUnlockedBehindCurrentAndOneLockedAhead() {
        // Given a user in the middle of the ladder
        // When the rungs are computed
        let rungs = SeedLevelLadder.rungs(currentLevel: 5, levelNames: levelNames)

        // Then the window spans levels 3 to 6 with the current level third
        XCTAssertEqual(rungs.map(\.level), [3, 4, 5, 6])
        XCTAssertEqual(rungs.map(\.state), [.unlocked, .unlocked, .current, .locked])
    }

    func testWindowNamesComeFromTheSuppliedLevelNames() {
        // Given level names resolved app-side
        // When the rungs are computed
        let rungs = SeedLevelLadder.rungs(currentLevel: 5, levelNames: levelNames)

        // Then each badge carries the name of its own level
        XCTAssertEqual(rungs.map(\.name), ["Level 3 name", "Level 4 name", "Level 5 name", "Level 6 name"])
    }

    // MARK: - Clamping

    func testWindowPinsToTheFirstFourLevelsAtTheBottomOfTheLadder() {
        // Given a user on one of the first two levels
        for currentLevel in 1...2 {
            // When the rungs are computed
            let rungs = SeedLevelLadder.rungs(currentLevel: currentLevel, levelNames: levelNames)

            // Then the window pins to levels 1 to 4
            XCTAssertEqual(rungs.map(\.level), [1, 2, 3, 4], "level \(currentLevel)")
            XCTAssertEqual(rungs.first(where: { $0.state == .current })?.level, currentLevel)
        }
    }

    func testWindowPinsToTheLastFourLevelsAtTheTopOfTheLadder() {
        // Given a user on the final level
        // When the rungs are computed
        let rungs = SeedLevelLadder.rungs(currentLevel: 20, levelNames: levelNames)

        // Then the window pins to the last four and the trailing badge is unlocked, not locked
        XCTAssertEqual(rungs.map(\.level), [17, 18, 19, 20])
        XCTAssertEqual(rungs.map(\.state), [.unlocked, .unlocked, .unlocked, .current])
    }

    func testWindowShowsOneLockedBadgeOnceItIsNoLongerClampedAtTheBottom() {
        // Given any level from which the window can look two levels back
        for currentLevel in 3...20 {
            // When the rungs are computed
            let rungs = SeedLevelLadder.rungs(currentLevel: currentLevel, levelNames: levelNames)

            // Then there are four badges, exactly one current, and at most one locked
            XCTAssertEqual(rungs.count, 4, "level \(currentLevel)")
            XCTAssertLessThanOrEqual(rungs.filter { $0.state == .locked }.count, 1, "level \(currentLevel)")
            XCTAssertEqual(rungs.filter { $0.state == .current }.count, 1, "level \(currentLevel)")
        }
    }

    /// The window pinned to levels 1–4 is the one place where more than one badge is locked.
    /// The spec's drawn level-1 state shows three padlocks, and the drawn states are normative.
    func testBottomClampShowsEveryLevelAheadOfTheCurrentOneAsLocked() {
        // Given a brand-new user on level 1
        // When the rungs are computed
        let rungs = SeedLevelLadder.rungs(currentLevel: 1, levelNames: levelNames)

        // Then the current level leads and the three levels ahead of it are all locked
        XCTAssertEqual(rungs.map(\.state), [.current, .locked, .locked, .locked])
    }

    func testLevelOutsideTheLadderIsClamped() {
        // Given a level number beyond the ladder
        // When the rungs are computed
        let rungs = SeedLevelLadder.rungs(currentLevel: 99, levelNames: levelNames)

        // Then it is treated as the final level
        XCTAssertEqual(rungs.map(\.level), [17, 18, 19, 20])
        XCTAssertEqual(rungs.last?.state, .current)
    }

    func testShortLadderReturnsEveryLevelItHas() {
        // Given fewer levels than the window size
        let shortLadder = ["One", "Two"]

        // When the rungs are computed
        let rungs = SeedLevelLadder.rungs(currentLevel: 2, levelNames: shortLadder)

        // Then only the levels that exist are returned
        XCTAssertEqual(rungs.map(\.level), [1, 2])
        XCTAssertEqual(rungs.map(\.state), [.unlocked, .current])
    }

    func testNoLevelNamesYieldsNoRungs() {
        // Given no level data, as for a logged-out user before the app has written it
        // When the rungs are computed
        // Then the ladder is empty rather than showing placeholder levels
        XCTAssertTrue(SeedLevelLadder.rungs(currentLevel: 3, levelNames: []).isEmpty)
    }

    // MARK: - Teaser ladder

    func testTeaserLadderShowsTheFirstFourLevelsAllLocked() {
        // Given a logged-out user
        // When the teaser rungs are computed
        let rungs = SeedLevelLadder.teaserRungs(levelNames: levelNames)

        // Then the first four levels are shown, every one of them locked
        XCTAssertEqual(rungs.map(\.level), [1, 2, 3, 4])
        XCTAssertTrue(rungs.allSatisfy { $0.state == .locked })
    }

    // MARK: - Names

    func testNextLevelName() {
        XCTAssertEqual(SeedLevelLadder.nextLevelName(currentLevel: 3, levelNames: levelNames), "Level 4 name")
    }

    func testNextLevelNameIsAbsentAtTheTopOfTheLadder() {
        XCTAssertNil(SeedLevelLadder.nextLevelName(currentLevel: 20, levelNames: levelNames))
    }

    func testIsTopLevel() {
        XCTAssertFalse(SeedLevelLadder.isTopLevel(currentLevel: 19, levelNames: levelNames))
        XCTAssertTrue(SeedLevelLadder.isTopLevel(currentLevel: 20, levelNames: levelNames))
    }

    func testIsTopLevelIsFalseWithoutLevelData() {
        XCTAssertFalse(SeedLevelLadder.isTopLevel(currentLevel: 1, levelNames: []))
    }
}
