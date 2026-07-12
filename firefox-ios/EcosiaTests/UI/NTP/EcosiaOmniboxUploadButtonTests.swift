// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client
@testable import Ecosia

@MainActor
final class EcosiaOmniboxUploadButtonTests: XCTestCase {

    func testAccessibilityMetadata() {
        let button = EcosiaOmniboxUploadButton(frame: .zero)

        XCTAssertEqual(button.accessibilityIdentifier, "NTPSearchBarUploadButton")
        XCTAssertEqual(button.accessibilityLabel, String.localized(.upload))
        XCTAssertEqual(button.accessibilityHint, String.localized(.uploadAccessibilityHint))
        XCTAssertTrue(button.accessibilityTraits.contains(.button))
    }

    func testPressedStateShowsHighlightCircle() {
        let button = EcosiaOmniboxUploadButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let highlight = button.subviews.first { $0.layer.cornerRadius == .ecosia.space._3l / 2 }

        XCTAssertNotNil(highlight)
        XCTAssertTrue(highlight?.isHidden == true)

        button.isHighlighted = true
        XCTAssertFalse(highlight?.isHidden == true)

        button.isHighlighted = false
        XCTAssertTrue(highlight?.isHidden == true)
    }

    func testPlusIconLoadsFromFrameworkBundle() {
        XCTAssertNotNil(UIImage.ecosia(named: "plus"))
    }

    func testApplyThemeSetsIconTint() {
        let button = EcosiaOmniboxUploadButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let theme = EcosiaLightTheme()

        button.applyTheme(theme: theme)

        let iconView = button.subviews.compactMap { $0 as? UIImageView }.first
        XCTAssertEqual(iconView?.tintColor, theme.colors.ecosia.buttonContentSecondary)
    }
}
