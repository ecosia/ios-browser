// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
// swiftlint:disable implicitly_unwrapped_optional

@MainActor
final class PrivateModeButtonTests: XCTestCase {

    var button: PrivateModeButton!
    var lightTheme = EcosiaLightTheme()
    var darkTheme = EcosiaDarkTheme()

    override func setUp() {
        super.setUp()
        button = PrivateModeButton(frame: .zero)
    }

    func testApplyUIMode_Private_LightMode() {
        button.applyUIMode(isPrivate: true, theme: lightTheme)

        XCTAssertEqual(button.tintColor, lightTheme.colors.ecosia.backgroundPrimary)
        XCTAssertEqual(button.imageView?.tintColor, lightTheme.colors.ecosia.backgroundPrimary)
        XCTAssertEqual(button.accessibilityValue, .TabsTray.TabTrayToggleAccessibilityValueOn)
    }

    func testApplyUIMode_NotPrivate_LightMode() {
        button.applyUIMode(isPrivate: false, theme: lightTheme)

        XCTAssertEqual(button.tintColor, lightTheme.colors.textPrimary)
        XCTAssertEqual(button.imageView?.tintColor, lightTheme.colors.textPrimary)
        XCTAssertEqual(button.accessibilityValue, .TabsTray.TabTrayToggleAccessibilityValueOff)
    }

    func testApplyUIMode_Private_DarkMode() {
        button.applyUIMode(isPrivate: true, theme: darkTheme)

        // Ecosia: selected/private state uses buttonContentPrimary (White), not Firefox's iconOnColor.
        // See PrivateModeButton.applyUIMode comment for the intentional icon/background inversion.
        XCTAssertEqual(button.tintColor, darkTheme.colors.ecosia.buttonContentPrimary)
        XCTAssertEqual(button.imageView?.tintColor, darkTheme.colors.ecosia.buttonContentPrimary)
        XCTAssertEqual(button.accessibilityValue, .TabsTray.TabTrayToggleAccessibilityValueOn)
    }

    func testApplyUIMode_NotPrivate_DarkMode() {
        button.applyUIMode(isPrivate: false, theme: darkTheme)

        XCTAssertEqual(button.tintColor, darkTheme.colors.textPrimary)
        XCTAssertEqual(button.imageView?.tintColor, darkTheme.colors.textPrimary)
        XCTAssertEqual(button.accessibilityValue, .TabsTray.TabTrayToggleAccessibilityValueOff)
    }

    func testApplyTheme_Selected_LightMode() {
        button.isSelected = true
        button.applyTheme(theme: lightTheme)

        // Ecosia: selected state uses buttonContentPrimary (White), not Firefox's iconOnColor.
        // See PrivateModeButton.applyTheme comment for the intentional icon/background inversion.
        XCTAssertEqual(button.tintColor, lightTheme.colors.ecosia.buttonContentPrimary)
        XCTAssertEqual(button.imageView?.tintColor, lightTheme.colors.ecosia.buttonContentPrimary)
    }

    func testApplyTheme_NotSelected_LightMode() {
        button.isSelected = false
        button.applyTheme(theme: lightTheme)

        XCTAssertEqual(button.tintColor, lightTheme.colors.iconPrimary)
        XCTAssertEqual(button.imageView?.tintColor, lightTheme.colors.iconPrimary)
    }

    func testApplyTheme_Selected_DarkMode() {
        button.isSelected = true
        button.applyTheme(theme: darkTheme)

        // Ecosia: selected state uses buttonContentPrimary (White), not Firefox's iconOnColor.
        // See PrivateModeButton.applyTheme comment for the intentional icon/background inversion.
        XCTAssertEqual(button.tintColor, darkTheme.colors.ecosia.buttonContentPrimary)
        XCTAssertEqual(button.imageView?.tintColor, darkTheme.colors.ecosia.buttonContentPrimary)
    }

    func testApplyTheme_NotSelected_DarkMode() {
        button.isSelected = false
        button.applyTheme(theme: darkTheme)

        XCTAssertEqual(button.tintColor, darkTheme.colors.iconPrimary)
        XCTAssertEqual(button.imageView?.tintColor, darkTheme.colors.iconPrimary)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
