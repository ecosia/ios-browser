// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client
@testable import Ecosia

final class NTPGlassAppearanceTests: XCTestCase {

    private let lightTheme = EcosiaLightTheme()
    private let darkTheme = EcosiaDarkTheme()
    private let staticLight = UIColor(rgb: 0xFFFFFF)
    private let staticStrong = UIColor(rgb: 0x333333)

    // MARK: - Background

    func testInit_withWallpaper_isWallpaper() {
        // When
        let appearance = NTPGlassAppearance(hasWallpaper: true)

        // Then
        XCTAssertEqual(appearance, .wallpaper)
    }

    func testInit_withoutWallpaper_isThemed() {
        // When
        let appearance = NTPGlassAppearance(hasWallpaper: false)

        // Then
        XCTAssertEqual(appearance, .themed)
    }

    // MARK: - Glass

    func testWallpaper_forcesDarkGlass() {
        XCTAssertEqual(NTPGlassAppearance.wallpaper.interfaceStyle, .dark)
    }

    func testThemed_followsThemeForGlass() {
        XCTAssertEqual(NTPGlassAppearance.themed.interfaceStyle, .unspecified)
    }

    // MARK: - Content

    func testWallpaper_contentIsStaticLight_inLightAndDarkTheme() {
        XCTAssertEqual(NTPGlassAppearance.wallpaper.contentColor(for: lightTheme), staticLight)
        XCTAssertEqual(NTPGlassAppearance.wallpaper.contentColor(for: darkTheme), staticLight)
    }

    func testThemed_contentFollowsTheme() {
        XCTAssertEqual(NTPGlassAppearance.themed.contentColor(for: lightTheme), staticStrong)
        XCTAssertEqual(NTPGlassAppearance.themed.contentColor(for: darkTheme), staticLight)
    }
}
