// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Ecosia

class EcosiaAISearchButtonThemeTests: XCTestCase {
    
    func testDefaultValues() {
        // Given
        let theme = EcosiaAISearchButtonTheme()
        
        // Then
        XCTAssertEqual(theme.backgroundColor, Color.gray.opacity(0.2))
        XCTAssertEqual(theme.iconColor, Color.primary)
    }
    
    func testApplyLightTheme() {
        // Given
        var theme = EcosiaAISearchButtonTheme()
        let ecosiaTheme = EcosiaLightTheme()
        
        // When
        theme.applyTheme(theme: ecosiaTheme)
        
        // Then
        XCTAssertEqual(theme.backgroundColor, Color(ecosiaTheme.colors.ecosia.backgroundElevation1))
        XCTAssertEqual(theme.iconColor, Color(ecosiaTheme.colors.ecosia.textPrimary))
    }
    
    func testApplyDarkTheme() {
        // Given
        var theme = EcosiaAISearchButtonTheme()
        let ecosiaTheme = EcosiaDarkTheme()
        
        // When
        theme.applyTheme(theme: ecosiaTheme)
        
        // Then
        XCTAssertEqual(theme.backgroundColor, Color(ecosiaTheme.colors.ecosia.backgroundElevation1))
        XCTAssertEqual(theme.iconColor, Color(ecosiaTheme.colors.ecosia.textPrimary))
    }
}
