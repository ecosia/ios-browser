// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Client
@testable import Ecosia

@MainActor
final class NTPSolidButtonThemeTests: XCTestCase {

    func testApplyTheme_lightTheme_usesElevatedBackgroundAndSecondaryPressedTokens() {
        assertUsesElevatedBackgroundAndSecondaryPressedTokens(of: EcosiaLightTheme())
    }

    func testApplyTheme_darkTheme_usesElevatedBackgroundAndSecondaryPressedTokens() {
        assertUsesElevatedBackgroundAndSecondaryPressedTokens(of: EcosiaDarkTheme())
    }

    func testApplyTheme_darkTheme_standsOutFromPlainNTPBackground() {
        // Given
        var solid = NTPSolidButtonTheme()
        let theme = EcosiaDarkTheme()

        // When
        solid.applyTheme(theme: theme)

        // Then
        let background = solid.background
        XCTAssertNotEqual(background, Color(theme.colors.ecosia.backgroundPrimaryDecorative))
    }

    private func assertUsesElevatedBackgroundAndSecondaryPressedTokens(of theme: Theme, file: StaticString = #filePath, line: UInt = #line) {
        // Given
        var solid = NTPSolidButtonTheme()
        let colors = theme.colors.ecosia

        // When
        solid.applyTheme(theme: theme)

        // Then
        let background = solid.background
        let backgroundPressed = solid.backgroundPressed
        XCTAssertEqual(background, Color(colors.backgroundElevation1), file: file, line: line)
        XCTAssertEqual(backgroundPressed, Color(colors.buttonBackgroundSecondaryActive), file: file, line: line)
    }
}
