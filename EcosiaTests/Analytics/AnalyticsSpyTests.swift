// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import Client

final class AnalyticsSpy: Analytics {
    var installCalled = false
    override func install() {
        installCalled = true
    }
    
    var activityActionCalled: Analytics.Action.Activity? = nil
    override func activity(_ action: Analytics.Action.Activity) {
        activityActionCalled = action
    }
    
    var menuClickItemCalled: Analytics.Label.Menu?
    override func menuClick(_ item: Analytics.Label.Menu) {
        menuClickItemCalled = item
    }
}

final class AnalyticsSpyTests: XCTestCase {
    var analyticsSpy: AnalyticsSpy!
    
    var profileMock: Profile { MockProfile() }
    var tabManagerMock: TabManager {
        let mock = MockTabManager()
        mock.selectedTab = .init(profile: profileMock,
                                 configuration: .init())
        mock.selectedTab?.url = URL(string: "https://example.com")
        return mock
    }
    
    override func setUp() {
        super.setUp()
        
        analyticsSpy = AnalyticsSpy()
        Analytics.shared = analyticsSpy
    }
    
    override func tearDown() {
        super.tearDown()
        
        analyticsSpy = nil
        Analytics.shared = Analytics()
    }
    
    // MARK:  AppDelegate
    var appDelegate: AppDelegate { AppDelegate() }
    
    func testTrackLaunchAndInstallOnDidFinishLaunching() async {
        XCTAssertNil(analyticsSpy.activityActionCalled)
        
        let application = await UIApplication.shared
        let _ = await appDelegate.application(application, didFinishLaunchingWithOptions: nil)
        
        
        XCTAssert(analyticsSpy.installCalled)
        wait(1) // Wait detached tasks
        XCTAssertEqual(analyticsSpy.activityActionCalled, .launch)
    }
    
    func testTrackResumeOnDidFinishLaunching() async {
        XCTAssertNil(analyticsSpy.activityActionCalled)
        
        let application = await UIApplication.shared
        let _ = await appDelegate.applicationDidBecomeActive(application)
        
        wait(1) // Wait detached tasks
        XCTAssertEqual(analyticsSpy.activityActionCalled, .resume)
    }
    
    // MARK:  Menu
    var menuHelper: MainMenuActionHelper {
        MainMenuActionHelper(profile: profileMock,
                             tabManager: tabManagerMock,
                             buttonView: .init(),
                             toastContainer: .init(),
                             themeManager: MockThemeManager())
    }
    
    func testTrackOpenInSafariAction() {
        XCTAssertNil(analyticsSpy.menuClickItemCalled)
        
        // Requires valid url to add action
        tabManagerMock.selectedTab?.url = URL(string: "https://example.com")
        
        let expectation = self.expectation(description: "Actions are returned")
        menuHelper.getToolbarActions(navigationController: .init()) { actions in
            let openInSafariAction = actions
                .flatMap { $0 } // Flattens sections
                .flatMap { $0.items } // Flattens items in sections
                .first { $0.title == .localized(.openInSafari) }
            openInSafariAction!.tapHandler!(openInSafariAction!)
            
            XCTAssertEqual(self.analyticsSpy.menuClickItemCalled, .openInSafari)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    // TODO: Add tests for other events
}
