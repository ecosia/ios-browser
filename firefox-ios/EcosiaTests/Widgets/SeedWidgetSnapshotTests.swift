// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

/// Tests for the snapshot the app writes into the shared app group for the seed widget.
final class SeedWidgetSnapshotTests: XCTestCase {

    func testRoundTripPreservesLevelState() throws {
        // Given a snapshot carrying the level state the medium and large widgets need
        let snapshot = SeedWidgetSnapshot(
            seedCount: 128,
            levelProgress: 0.62,
            isSignedIn: true,
            currentLevel: 3,
            levelNames: ["Ecocurious", "Green explorer", "Planet pal"],
            growthPointsRemaining: 37,
            avatarFileName: "seed-widget-avatar.png"
        )

        // When it is encoded and decoded again
        let decoded = try JSONDecoder().decode(SeedWidgetSnapshot.self, from: JSONEncoder().encode(snapshot))

        // Then every field survives
        XCTAssertEqual(decoded.seedCount, 128)
        XCTAssertEqual(decoded.levelProgress, 0.62, accuracy: 0.0001)
        XCTAssertTrue(decoded.isSignedIn)
        XCTAssertEqual(decoded.currentLevel, 3)
        XCTAssertEqual(decoded.levelNames, ["Ecocurious", "Green explorer", "Planet pal"])
        XCTAssertEqual(decoded.growthPointsRemaining, 37)
        XCTAssertEqual(decoded.avatarFileName, "seed-widget-avatar.png")
    }

    func testSnapshotWrittenBeforeLevelStateExistedStillDecodes() throws {
        // Given a snapshot written by an app version that only carried the small-widget values
        let legacy = """
        {"seedCount":12,"levelProgress":0.4,"isSignedIn":false,"updatedAt":760000000}
        """.data(using: .utf8)!

        // When it is decoded after an app update
        let decoded = try JSONDecoder().decode(SeedWidgetSnapshot.self, from: legacy)

        // Then the original values are kept and the new ones fall back to empty defaults,
        // so the widget renders instead of failing to decode.
        XCTAssertEqual(decoded.seedCount, 12)
        XCTAssertEqual(decoded.levelProgress, 0.4, accuracy: 0.0001)
        XCTAssertFalse(decoded.isSignedIn)
        XCTAssertEqual(decoded.currentLevel, 1)
        XCTAssertTrue(decoded.levelNames.isEmpty)
        XCTAssertEqual(decoded.growthPointsRemaining, 0)
        XCTAssertNil(decoded.avatarFileName)
    }

    func testAvatarFileURLIsAbsentWithoutAnAvatar() {
        // Given a snapshot for a user with no avatar
        let snapshot = SeedWidgetSnapshot(seedCount: 0, levelProgress: 0, isSignedIn: true)

        // When the avatar URL is resolved
        // Then there is none, and the widget omits the element rather than drawing an empty ring
        XCTAssertNil(snapshot.avatarFileURL(appGroupIdentifier: "group.com.ecosia.test"))
    }
}
