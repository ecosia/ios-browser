// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
@testable import Client

@MainActor
class AppIconViewTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // AppIconView reads `\.themeManager` from the environment, which resolves from AppContainer
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func test_appIconView_rendersEcosiaIcon() {
        let view = AppIconView(appIcon: .ecosiaLight, isSelected: false, windowUUID: UUID(), setAppIcon: { _ in })
        let size = UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 500, height: 500))
        XCTAssertGreaterThan(size.height, 0, "AppIconView rendered nothing, is it still using UIImage.ecosia(named:)?")
    }

    func test_allAppIcons_haveEcosiaImage() {
        for icon in AppIcon.allCases {
            XCTAssertNotNil(UIImage.ecosia(named: icon.imageSetAssetName), "Missing image for \(icon)")
        }
    }
}
