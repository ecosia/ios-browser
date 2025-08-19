// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Ecosia

class FeedbackThemeTests: XCTestCase {
    
    func testDefaultValues() {
        // Given
        let theme = FeedbackTheme()
        
        // Then
        XCTAssertEqual(theme.backgroundColor, Color.white)
        XCTAssertEqual(theme.sectionBackgroundColor, Color.white)
        XCTAssertEqual(theme.textPrimaryColor, Color.black)
        XCTAssertEqual(theme.textSecondaryColor, Color.gray)
        XCTAssertEqual(theme.buttonBackgroundColor, Color.blue)
        XCTAssertEqual(theme.buttonDisabledBackgroundColor, Color.gray)
        XCTAssertEqual(theme.brandPrimaryColor, Color.blue)
        XCTAssertEqual(theme.borderColor, Color.gray.opacity(0.2))
        XCTAssertEqual(theme.borderWidth, 1)
    }
    
    func testApplyLightTheme() {
        // Given
        var theme = FeedbackTheme()
        let ecosiaTheme = EcosiaLightTheme()
        
        // When
        theme.applyTheme(theme: ecosiaTheme)
        
        // Then
        XCTAssertEqual(theme.backgroundColor, Color(ecosiaTheme.colors.ecosia.backgroundPrimaryDecorative))
        XCTAssertEqual(theme.sectionBackgroundColor, Color(ecosiaTheme.colors.ecosia.backgroundElevation1))
        XCTAssertEqual(theme.textPrimaryColor, Color(ecosiaTheme.colors.ecosia.textPrimary))
        XCTAssertEqual(theme.textSecondaryColor, Color(ecosiaTheme.colors.ecosia.textSecondary))
        XCTAssertEqual(theme.buttonBackgroundColor, Color(ecosiaTheme.colors.ecosia.buttonBackgroundPrimaryActive))
        XCTAssertEqual(theme.buttonDisabledBackgroundColor, Color(ecosiaTheme.colors.ecosia.stateDisabled))
        XCTAssertEqual(theme.brandPrimaryColor, Color(ecosiaTheme.colors.ecosia.brandPrimary))
        XCTAssertEqual(theme.borderColor, Color(ecosiaTheme.colors.ecosia.borderDecorative))
    }
    
    func testApplyDarkTheme() {
        // Given
        var theme = FeedbackTheme()
        let ecosiaTheme = EcosiaDarkTheme()
        
        // When
        theme.applyTheme(theme: ecosiaTheme)
        
        // Then
        XCTAssertEqual(theme.backgroundColor, Color(ecosiaTheme.colors.ecosia.backgroundPrimaryDecorative))
        XCTAssertEqual(theme.sectionBackgroundColor, Color(ecosiaTheme.colors.ecosia.backgroundElevation1))
        XCTAssertEqual(theme.textPrimaryColor, Color(ecosiaTheme.colors.ecosia.textPrimary))
        XCTAssertEqual(theme.textSecondaryColor, Color(ecosiaTheme.colors.ecosia.textSecondary))
        XCTAssertEqual(theme.buttonBackgroundColor, Color(ecosiaTheme.colors.ecosia.buttonBackgroundPrimaryActive))
        XCTAssertEqual(theme.buttonDisabledBackgroundColor, Color(ecosiaTheme.colors.ecosia.stateDisabled))
        XCTAssertEqual(theme.brandPrimaryColor, Color(ecosiaTheme.colors.ecosia.brandPrimary))
        XCTAssertEqual(theme.borderColor, Color(ecosiaTheme.colors.ecosia.borderDecorative))
    }
}
