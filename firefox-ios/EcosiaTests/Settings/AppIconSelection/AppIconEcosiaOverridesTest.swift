// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class AppIconEcosiaOverridesTest: XCTestCase {

    func test_enumValues_arePresent() throws {
        XCTAssertTrue(AppIcon.allCases.count == 8)
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaLight))
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaDark))
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaForest))
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaMushroom))
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaLeaf))
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaWood))
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaSea))
        XCTAssertTrue(AppIcon.allCases.contains(AppIcon.ecosiaMountain))
    }

    @MainActor
    func test_initFromSystem() throws {
        try XCTSkipIf(UIApplication.shared.alternateIconName != nil, "An alternate icon is set on this simulator")
        let defaultIcon = AppIcon.initFromSystem()
        XCTAssertTrue(defaultIcon == AppIcon.ecosiaLight)
    }

    func test_isFunIcon_isFalse() throws {
        XCTAssertFalse(AppIcon.ecosiaLight.isFunIcon)
        XCTAssertFalse(AppIcon.ecosiaDark.isFunIcon)
        XCTAssertFalse(AppIcon.ecosiaForest.isFunIcon)
        XCTAssertFalse(AppIcon.ecosiaMushroom.isFunIcon)
        XCTAssertFalse(AppIcon.ecosiaLeaf.isFunIcon)
        XCTAssertFalse(AppIcon.ecosiaWood.isFunIcon)
        XCTAssertFalse(AppIcon.ecosiaSea.isFunIcon)
        XCTAssertFalse(AppIcon.ecosiaMountain.isFunIcon)
    }
}
