// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Client
@testable import Ecosia

@MainActor
final class BalanceIncrementAnimationViewThemeTests: XCTestCase {

    private let lightTheme = EcosiaLightTheme()
    private let darkTheme = EcosiaDarkTheme()

    func testApplyTheme_usesBalanceIncrementTokens() {
        // Given
        var pillTheme = BalanceIncrementAnimationViewTheme()
        let colors = lightTheme.colors.ecosia

        // When
        pillTheme.applyTheme(theme: lightTheme)

        // Then
        let textColor = pillTheme.textColor
        let backgroundColor = pillTheme.backgroundColor
        XCTAssertEqual(textColor, Color(colors.textBalanceIncrement))
        XCTAssertEqual(backgroundColor, Color(colors.backgroundBalanceIncrement))
    }

    func testApplyTheme_pillIsTheSameInLightAndDarkTheme() {
        // Given
        var lightPillTheme = BalanceIncrementAnimationViewTheme()
        var darkPillTheme = BalanceIncrementAnimationViewTheme()

        // When
        lightPillTheme.applyTheme(theme: lightTheme)
        darkPillTheme.applyTheme(theme: darkTheme)

        // Then
        let lightText = lightPillTheme.textColor
        let lightBackground = lightPillTheme.backgroundColor
        let darkText = darkPillTheme.textColor
        let darkBackground = darkPillTheme.backgroundColor
        XCTAssertEqual(lightText, darkText)
        XCTAssertEqual(lightBackground, darkBackground)
    }
}
