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
    
    var activityActionCalled: Analytics.Action.Activity?
    override func activity(_ action: Analytics.Action.Activity) {
        activityActionCalled = action
    }
    
    var menuClickItemCalled: Analytics.Label.Menu?
    override func menuClick(_ item: Analytics.Label.Menu) {
        menuClickItemCalled = item
    }
    
    var menuShareContentCalled: Analytics.Property.ShareContent?
    override func menuShare(_ content: Analytics.Property.ShareContent) {
        menuShareContentCalled = content
    }
    
    var menuStatusItemCalled: Analytics.Label.MenuStatus?
    var menuStatusItemChangedTo: Bool?
    override func menuStatus(changed item: Analytics.Label.MenuStatus, to: Bool) {
        menuStatusItemCalled = item
        menuStatusItemChangedTo = to
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
    
    // MARK: AppDelegate
    var appDelegate: AppDelegate { AppDelegate() }
    
    func testTrackLaunchAndInstallOnDidFinishLaunching() async {
        XCTAssertNil(analyticsSpy.activityActionCalled)
        
        let application = await UIApplication.shared
        _ = await appDelegate.application(application, didFinishLaunchingWithOptions: nil)
        
        XCTAssert(analyticsSpy.installCalled)
        wait(1) // Wait detached tasks
        XCTAssertEqual(analyticsSpy.activityActionCalled, .launch)
    }
    
    func testTrackResumeOnDidFinishLaunching() async {
        XCTAssertNil(analyticsSpy.activityActionCalled)
        
        let application = await UIApplication.shared
        _ = await appDelegate.applicationDidBecomeActive(application)
        
        wait(1) // Wait detached tasks
        XCTAssertEqual(analyticsSpy.activityActionCalled, .resume)
    }
    
    // MARK: Menu
    var menuHelper: MainMenuActionHelper {
        MainMenuActionHelper(profile: profileMock,
                             tabManager: tabManagerMock,
                             buttonView: .init(),
                             toastContainer: .init(),
                             themeManager: MockThemeManager())
    }
    
    func testTrackMenuAction() {
        let testCases: [(Analytics.Label.Menu, String)] = [
            (.openInSafari, .localized(.openInSafari)),
            (.history, .AppMenu.AppMenuHistory),
            (.downloads, .AppMenu.AppMenuDownloads),
            (.zoom, String(format: .AppMenu.ZoomPageTitle, "100%")),
            (.findInPage, .AppMenu.AppMenuFindInPageTitleString),
            (.requestDesktopSite, .AppMenu.AppMenuViewDesktopSiteTitleString),
            (.copyLink, .AppMenu.AppMenuCopyLinkTitleString),
            (.help, .AppMenu.Help),
            (.customizeHomepage, .AppMenu.CustomizeHomePage),
            (.readingList, .AppMenu.ReadingList),
            (.bookmarks, .AppMenu.Bookmarks)
        ]
        for (label, title) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            XCTContext.runActivity(named: "Menu action \(label.rawValue) is tracked") { _ in
                XCTAssertNil(analyticsSpy.menuClickItemCalled)
                
                // Requires valid url to add action
                tabManagerMock.selectedTab?.url = URL(string: "https://example.com")
                
                let expectation = self.expectation(description: "Actions are returned")
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let action = actions
                        .flatMap { $0 } // Flattens sections
                        .flatMap { $0.items } // Flattens items in sections
                        .first { $0.title == title }
                    if let action = action {
                        action.tapHandler!(action)
                        
                        XCTAssertEqual(self.analyticsSpy.menuClickItemCalled, label)
                    } else {
                        XCTFail("No action title with \(title) found")
                    }
                    
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 1)
            }
        }
    }
    
    func testTrackMenuShare() {
        let testCases: [(Analytics.Property.ShareContent, URL?)] = [
            (.ntp, URL(string: "file://example.com")),
            (.web, URL(string: "https://example.com")),
            (.ntp, nil)
        ]
        for (label, url) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            XCTContext.runActivity(named: "Menu share \(label.rawValue) is tracked") { _ in
                XCTAssertNil(analyticsSpy.menuShareContentCalled)
                
                // Requires valid url to add action
                tabManagerMock.selectedTab?.url = url
                
                let action = menuHelper.getSharingAction().items.first
                if let action = action {
                    action.tapHandler!(action)
                } else {
                    XCTFail("No sharing action found for url \(url?.absoluteString ?? "nil")")
                }
            }
        }
    }
    
    func testTrackMenuStatus() {
        let testCases: [(Analytics.Label.MenuStatus, Bool, String, ((String) -> Void)?)] = [
            (.readingList, true, .ShareAddToReadingList, nil),
            (.readingList, false, .AppMenu.RemoveReadingList, self.setReadingList),
            (.bookmark, true, .KeyboardShortcuts.AddBookmark, nil),
            // TODO: Investigate why `setBookmark` doesn't work
            // (.bookmark, false, .RemoveBookmarkContextMenuTitle, self.setBookmark),
            (.shortcut, true, .AddToShortcutsActionTitle, nil),
            (.shortcut, false, .AppMenu.RemoveFromShortcuts, self.setBookmark)
        ]
        for (label, value, title, given) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            XCTContext.runActivity(named: "Menu share \(label.rawValue) is tracked") { _ in
                XCTAssertNil(analyticsSpy.menuStatusItemCalled)
                XCTAssertNil(analyticsSpy.menuStatusItemChangedTo)
                
                let testUrl = "https://example.com"
                given?(testUrl)
                tabManagerMock.selectedTab?.url = URL(string: testUrl)
                
                let expectation = self.expectation(description: "Actions are returned")
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let action = actions
                        .flatMap { $0 } // Flattens sections
                        .flatMap { $0.items } // Flattens items in sections
                        .first { $0.title == title }
                    if let action = action {
                        action.tapHandler!(action)
                        
                        XCTAssertEqual(self.analyticsSpy.menuStatusItemCalled, label)
                        XCTAssertEqual(self.analyticsSpy.menuStatusItemChangedTo, value)
                    } else {
                        XCTFail("No action title with \(title) found")
                    }
                    
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 1)
            }
        }
    }
}
