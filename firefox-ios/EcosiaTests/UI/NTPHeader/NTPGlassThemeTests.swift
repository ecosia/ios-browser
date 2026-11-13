// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Client
@testable import Ecosia

@MainActor
final class NTPGlassThemeTests: XCTestCase {

    private let lightTheme = EcosiaLightTheme()
    private let darkTheme = EcosiaDarkTheme()

    func testApplyTheme_usesGlassStaticTokens() {
        // Given
        var glass = NTPGlassTheme()
        let colors = lightTheme.colors.ecosia

        // When
        glass.applyTheme(theme: lightTheme)

        // Then
        let tint = glass.tint
        let tintPressed = glass.tintPressed
        let border = glass.border
        XCTAssertEqual(tint, Color(colors.buttonBgGlassStatic))
        XCTAssertEqual(tintPressed, Color(colors.buttonBgGlassStaticActive))
        XCTAssertEqual(border, Color(colors.borderGlassStatic))
    }

    func testApplyTheme_glassIsTheSameInLightAndDarkTheme() {
        // Given
        var lightGlass = NTPGlassTheme()
        var darkGlass = NTPGlassTheme()

        // When
        lightGlass.applyTheme(theme: lightTheme)
        darkGlass.applyTheme(theme: darkTheme)

        // Then
        let lightTint = lightGlass.tint
        let lightTintPressed = lightGlass.tintPressed
        let lightBorder = lightGlass.border
        let darkTint = darkGlass.tint
        let darkTintPressed = darkGlass.tintPressed
        let darkBorder = darkGlass.border
        XCTAssertEqual(lightTint, darkTint)
        XCTAssertEqual(lightTintPressed, darkTintPressed)
        XCTAssertEqual(lightBorder, darkBorder)
    }
}
