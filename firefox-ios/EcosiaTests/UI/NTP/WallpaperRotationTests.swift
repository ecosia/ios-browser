// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class WallpaperRotationTests: XCTestCase {

    private let first = Wallpaper(id: "first", textColor: nil, cardColor: nil, logoTextColor: nil)
    private let second = Wallpaper(id: "second", textColor: nil, cardColor: nil, logoTextColor: nil)
    private let third = Wallpaper(id: "third", textColor: nil, cardColor: nil, logoTextColor: nil)
    private let utc = TimeZone(identifier: "UTC")!
    private let berlin = TimeZone(identifier: "Europe/Berlin")!

    private func makeRotation(
        wallpapers: [Wallpaper]? = nil,
        interval: TimeInterval = 30,
        at date: Date,
        timeZone: TimeZone? = nil,
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> WallpaperRotation {
        WallpaperRotation(
            wallpapers: wallpapers ?? [first, second, third],
            interval: interval,
            now: { date },
            timeZone: timeZone ?? utc,
            notificationCenter: notificationCenter
        )
    }

    private func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string)!
    }

    // MARK: - Current wallpaper

    func testCurrentWallpaper_atStartOfFirstPeriod_isFirst() {
        // Given
        let rotation = makeRotation(at: Date(timeIntervalSinceReferenceDate: 0))

        // Then
        XCTAssertEqual(rotation.currentWallpaper?.id, "first")
    }

    func testCurrentWallpaper_withinAPeriod_doesNotChange() {
        // Given
        let rotation = makeRotation(at: Date(timeIntervalSinceReferenceDate: 29))

        // Then
        XCTAssertEqual(rotation.currentWallpaper?.id, "first")
    }

    func testCurrentWallpaper_atNextPeriod_isNext() {
        // Given
        let rotation = makeRotation(at: Date(timeIntervalSinceReferenceDate: 30))

        // Then
        XCTAssertEqual(rotation.currentWallpaper?.id, "second")
    }

    func testCurrentWallpaper_afterLastWallpaper_wrapsToFirst() {
        // Given
        let rotation = makeRotation(at: Date(timeIntervalSinceReferenceDate: 90))

        // Then
        XCTAssertEqual(rotation.currentWallpaper?.id, "first")
    }

    func testCurrentWallpaper_withoutWallpapers_isNil() {
        // Given
        let rotation = makeRotation(wallpapers: [], at: Date(timeIntervalSinceReferenceDate: 0))

        // Then
        XCTAssertNil(rotation.currentWallpaper)
    }

    // MARK: - Daily

    func testCurrentWallpaper_daily_changesAtLocalMidnight() {
        // Given
        let beforeMidnight = makeRotation(
            interval: WallpaperRotation.daily,
            at: date("2026-11-05T22:59:59Z"),
            timeZone: berlin
        )
        let afterMidnight = makeRotation(
            interval: WallpaperRotation.daily,
            at: date("2026-11-05T23:00:00Z"),
            timeZone: berlin
        )

        // Then
        XCTAssertNotEqual(beforeMidnight.currentWallpaper?.id, afterMidnight.currentWallpaper?.id)
    }

    func testNextRotationDate_daily_isNextLocalMidnight() {
        // Given
        let rotation = makeRotation(
            interval: WallpaperRotation.daily,
            at: date("2026-11-05T10:00:00Z"),
            timeZone: berlin
        )

        // Then
        XCTAssertEqual(rotation.nextRotationDate, date("2026-11-05T23:00:00Z"))
    }

    func testNextRotationDate_isStartOfNextPeriod() {
        // Given
        let rotation = makeRotation(at: Date(timeIntervalSinceReferenceDate: 45))

        // Then
        XCTAssertEqual(rotation.nextRotationDate, Date(timeIntervalSinceReferenceDate: 60))
    }

    // MARK: - Notifications

    func testStart_postsDidRotate() {
        // Given
        let notificationCenter = NotificationCenter()
        let rotation = makeRotation(at: Date(), notificationCenter: notificationCenter)
        let didRotate = expectation(forNotification: WallpaperRotation.didRotate, object: rotation, notificationCenter: notificationCenter)

        // When
        rotation.start()

        // Then
        wait(for: [didRotate], timeout: 1)
        rotation.stop()
    }

    func testStop_postsDidRotate() {
        // Given
        let notificationCenter = NotificationCenter()
        let rotation = makeRotation(at: Date(), notificationCenter: notificationCenter)
        rotation.start()
        let didRotate = expectation(forNotification: WallpaperRotation.didRotate, object: rotation, notificationCenter: notificationCenter)

        // When
        rotation.stop()

        // Then
        wait(for: [didRotate], timeout: 1)
    }

    // MARK: - Bundled configuration

    func testConfigurationForBundled_withoutAsset_hasNoImage() {
        // When
        let configuration = EcosiaHomepageAdapter.configuration(forBundled: .baseWallpaper)

        // Then
        XCTAssertFalse(configuration.hasImage)
    }

    func testConfigurationForBundled_withMissingAsset_hasNoImage() {
        // Given
        let wallpaper = Wallpaper(id: "missing", textColor: nil, cardColor: nil, logoTextColor: nil, bundledAssetName: "missing")

        // When
        let configuration = EcosiaHomepageAdapter.configuration(forBundled: wallpaper)

        // Then
        XCTAssertFalse(configuration.hasImage)
    }

    func testConfigurationForBundled_withBundledAsset_hasImageAndColors() {
        // When
        let configuration = EcosiaHomepageAdapter.configuration(forBundled: .ecosiaDefault)

        // Then
        XCTAssertTrue(configuration.hasImage)
        XCTAssertNotNil(configuration.portraitImage)
        XCTAssertEqual(configuration.textColor, Wallpaper.ecosiaDefault.textColor)
    }
}
