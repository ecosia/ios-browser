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

    func testInit_wallpaperWithWhiteText_isDark() {
        // When
        let appearance = NTPGlassAppearance(hasWallpaper: true, wallpaperTextColor: .white)

        // Then
        XCTAssertEqual(appearance, .dark)
    }

    func testInit_wallpaperWithDarkText_isLight() {
        // When
        let appearance = NTPGlassAppearance(hasWallpaper: true, wallpaperTextColor: .black)

        // Then
        XCTAssertEqual(appearance, .light)
    }

    func testInit_wallpaperWithDarkRGBText_isLight() {
        // When
        let appearance = NTPGlassAppearance(hasWallpaper: true, wallpaperTextColor: UIColor(rgb: 0x333333))

        // Then
        XCTAssertEqual(appearance, .light)
    }

    func testInit_wallpaperWithoutTextColor_isDark() {
        // When
        let appearance = NTPGlassAppearance(hasWallpaper: true, wallpaperTextColor: nil)

        // Then
        XCTAssertEqual(appearance, .dark)
    }

    func testInit_defaultWallpaper_isDark() {
        // When
        let appearance = NTPGlassAppearance(hasWallpaper: true, wallpaperTextColor: Wallpaper.ecosiaDefault.textColor)

        // Then
        XCTAssertEqual(appearance, .dark)
    }

    func testInit_withoutWallpaper_isThemed_whateverTheTextColor() {
        XCTAssertEqual(NTPGlassAppearance(hasWallpaper: false, wallpaperTextColor: nil), .themed)
        XCTAssertEqual(NTPGlassAppearance(hasWallpaper: false, wallpaperTextColor: .black), .themed)
    }

    // MARK: - Glass

    func testDark_forcesDarkGlass() {
        XCTAssertEqual(NTPGlassAppearance.dark.interfaceStyle, .dark)
    }

    func testLight_forcesLightGlass() {
        XCTAssertEqual(NTPGlassAppearance.light.interfaceStyle, .light)
    }

    func testThemed_followsThemeForGlass() {
        XCTAssertEqual(NTPGlassAppearance.themed.interfaceStyle, .unspecified)
    }

    // MARK: - Content

    func testDark_contentIsStaticLight_inLightAndDarkTheme() {
        XCTAssertEqual(NTPGlassAppearance.dark.contentColor(for: lightTheme), staticLight)
        XCTAssertEqual(NTPGlassAppearance.dark.contentColor(for: darkTheme), staticLight)
    }

    func testLight_contentIsStaticStrong_inLightAndDarkTheme() {
        XCTAssertEqual(NTPGlassAppearance.light.contentColor(for: lightTheme), staticStrong)
        XCTAssertEqual(NTPGlassAppearance.light.contentColor(for: darkTheme), staticStrong)
    }

    func testThemed_contentFollowsTheme() {
        XCTAssertEqual(NTPGlassAppearance.themed.contentColor(for: lightTheme), staticStrong)
        XCTAssertEqual(NTPGlassAppearance.themed.contentColor(for: darkTheme), staticLight)
    }
}
