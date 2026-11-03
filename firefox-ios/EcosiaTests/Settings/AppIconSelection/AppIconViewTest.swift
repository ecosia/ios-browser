// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import SnowplowTracker
@testable import Client
@testable import Ecosia

// MARK: - AnalyticsSpy

func makeAnalyticsSpyContextSUT(status: UNAuthorizationStatus = .notDetermined) -> AnalyticsSpy {
    let mockSettings = MockUNNotificationSettings(authorizationStatus: status)
    let mockNotificationCenter = MockAnalyticsUserNotificationCenter(mockSettings: mockSettings)
    let analyticsSpy = AnalyticsSpy(notificationCenter: mockNotificationCenter)
    return analyticsSpy
}

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
    
    func test_appIconView_invokesEcosiaTracking() {
        let analyticsSpy = makeAnalyticsSpyContextSUT()
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: Analytics.Category.settings.rawValue, action: Analytics.Action.Activity.launch.rawValue)
        
        let view = AppIconView(appIcon: .ecosiaLight, isSelected: false, windowUUID: UUID(), setAppIcon: { _ in })
        
        wait(for: [expectation], timeout: 2)
        
        //TODO: test the view constructor invokes tracking (analyticsSpy.changeAppIcon(...))
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click, "Analytics should track referral action as .click.")
    }
}
