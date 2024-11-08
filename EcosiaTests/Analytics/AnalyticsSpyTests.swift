// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Core
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

    var bookmarksImportExportPropertyCalled: Analytics.Property.Bookmarks?
    override func bookmarksPerformImportExport(_ property: Analytics.Property.Bookmarks) {
        bookmarksImportExportPropertyCalled = property
    }

    var bookmarksEmptyLearnMoreClickedCalled = false
    override func bookmarksEmptyLearnMoreClicked() {
        bookmarksEmptyLearnMoreClickedCalled = true
    }

    var bookmarksImportEndedPropertyCalled: Analytics.Property.Bookmarks?
    override func bookmarksImportEnded(_ property: Analytics.Property.Bookmarks) {
        bookmarksImportEndedPropertyCalled = property
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
    
    var introDisplayingPageCalled: Property.OnboardingPage?
    var introDisplayingIndexCalled: Int?

    override func introDisplaying(page: Property.OnboardingPage?, at index: Int) {
        introDisplayingPageCalled = page
        introDisplayingIndexCalled = index
    }

    var introClickLabelCalled: Label.Onboarding?
    var introClickPageCalled: Property.OnboardingPage?
    var introClickIndexCalled: Int?
    
    override func introClick(_ label: Label.Onboarding, page: Property.OnboardingPage?, index: Int) {
        introClickLabelCalled = label
        introClickPageCalled = page
        introClickIndexCalled = index
    }
    
    var navigationActionCalled: Action?
    var navigationLabelCalled: Label.Navigation?
    
    override func navigation(_ action: Action, label: Label.Navigation) {
        navigationActionCalled = action
        navigationLabelCalled = label
    }

    var navigationOpenNewsIdCalled: String?
    
    override func navigationOpenNews(_ id: String) {
        navigationOpenNewsIdCalled = id
    }
    
    var referralActionCalled: Action.Referral?
    var referralLabelCalled: Label.Referral?

    override func referral(action: Action.Referral, label: Label.Referral? = nil) {
        referralActionCalled = action
        referralLabelCalled = label
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
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()

        analyticsSpy = nil
        Analytics.shared = Analytics()
        DependencyHelperMock().reset()
    }

    // MARK: AppDelegate
    var appDelegate: AppDelegate { AppDelegate() }

    func testTrackLaunchAndInstallOnDidFinishLaunching() async {
        XCTAssertNil(analyticsSpy.activityActionCalled)

        let application = await UIApplication.shared
        _ = await appDelegate.application(application, didFinishLaunchingWithOptions: nil)

        XCTAssert(analyticsSpy.installCalled)

        waitForCondition(timeout: 3) { // Wait detached tasks until launch is called
            analyticsSpy.activityActionCalled == .launch
        }
    }

    func testTrackResumeOnDidFinishLaunching() async {
        XCTAssertNil(analyticsSpy.activityActionCalled)

        let application = await UIApplication.shared
        _ = await appDelegate.applicationDidBecomeActive(application)

        waitForCondition(timeout: 2) { // Wait detached tasks until resume is called
            analyticsSpy.activityActionCalled == .resume
        }
    }

    // MARK: Bookmarks
    var panel: BookmarksPanel {
        let viewModel = BookmarksPanelViewModel(profile: profileMock, bookmarkFolderGUID: "TestGuid")
        return BookmarksPanel(viewModel: viewModel)
    }

    func testTrackImportClick() {
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        panel.importBookmarksActionHandler()

        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .import)
    }

    func testTrackExportClick() {
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        panel.exportBookmarksActionHandler()

        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .export)
    }

    func testTrackLearnMoreClick() {
        let view = EmptyBookmarksView(initialBottomMargin: 0)
        XCTAssertFalse(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled)

        view.onLearnMoreTapped()

        XCTAssertTrue(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled)
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
            (.zoom, String(format: .AppMenu.ZoomPageTitle, NumberFormatter.localizedString(from: NSNumber(value: 1), number: .percent))),
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

                let expectation = self.expectation(description: "Actions for \(title) are returned")
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
        // swiftlint:disable:next large_tuple
        let testCases: [(Analytics.Label.MenuStatus, Bool, String)] = [
            // Adding and then removing for each case, this order matters!
            (.readingList, true, .ShareAddToReadingList),
            (.readingList, false, .AppMenu.RemoveReadingList),
            (.bookmark, true, .KeyboardShortcuts.AddBookmark),
            // Removing bookmark does not work since it requires additional user interaction
            // (.bookmark, false, .RemoveBookmarkContextMenuTitle),
            (.shortcut, true, .AddToShortcutsActionTitle),
            (.shortcut, false, .AppMenu.RemoveFromShortcuts)
        ]
        for (label, value, title) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            XCTContext.runActivity(named: "Menu share \(label.rawValue) is tracked") { _ in
                XCTAssertNil(analyticsSpy.menuStatusItemCalled)
                XCTAssertNil(analyticsSpy.menuStatusItemChangedTo)

                let testUrl = "https://example.com"
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
    
    // MARK: Onboarding / Welcome
    
    func testWelcomeViewDidAppearTracksIntroDisplayingAndIntroClickStart() {
        let welcomeDelegate = MockWelcomeDelegate()
        let welcome = Welcome(delegate: welcomeDelegate)
        
        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)
        XCTAssertNil(analyticsSpy.introDisplayingIndexCalled)
        
        // Simulate view lifecycle
        welcome.loadViewIfNeeded()
        welcome.viewDidAppear(false)
        
        // Verify analytics method was called with correct parameters
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .start)
        XCTAssertEqual(analyticsSpy.introDisplayingIndexCalled, 0)
    }
    
    func testWelcomeGetStartedTracksIntroClickNext() {
        let welcomeDelegate = MockWelcomeDelegate()
        let welcome = Welcome(delegate: welcomeDelegate)
        
        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)
        
        // Simulate user tapping "Get Started"
        welcome.getStarted()
        
        // Verify analytics method was called with correct parameters
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 0)
    }
    
    func testWelcomeSkipTracksIntroClickSkip() {
        let welcomeDelegate = MockWelcomeDelegate()
        let welcome = Welcome(delegate: welcomeDelegate)
        
        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)
        
        // Simulate user tapping "Skip"
        welcome.skip()
        
        // Verify analytics method was called with correct parameters
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 0)
    }

    
    // MARK: Onboarding / Welcome Tour

    func testWelcomeTourViewDidAppearTracksIntroDisplaying() {
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)

        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)
        XCTAssertNil(analyticsSpy.introDisplayingIndexCalled)

        // Simulate view lifecycle
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        // Verify analytics method was called with correct parameters
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .greenSearch)
        XCTAssertEqual(analyticsSpy.introDisplayingIndexCalled, 1)
    }

    func testWelcomeTourNextTracksIntroClickNext() {
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)

        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Simulate view lifecycle
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        // Simulate user navigating to the next screen in WelcomeTour
        welcomeTour.forward()

        // Verify analytics method was called with correct parameters
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 1)
    }

    func testWelcomeTourSkipTracksIntroClickSkip() {
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)

        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)
        
        // Simulate view lifecycle
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        // Simulate user tapping "Skip" in WelcomeTour
        welcomeTour.skip()

        // Verify analytics method was called with correct parameters
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 1)
    }
    
    func testWelcomeTourTracksAnalyticsForAllPages() {
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)

        // List of pages in the WelcomeTour
        let pages: [Analytics.Property.OnboardingPage] = [
            .greenSearch,
            .profits,
            .action,
            .transparentFinances
        ]
        
        // Simulate view lifecycle
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        for (index, page) in pages.enumerated() {

            // Reset analyticsSpy properties
            analyticsSpy.introDisplayingPageCalled = nil
            analyticsSpy.introDisplayingIndexCalled = nil
            
            if index < pages.count - 1 {
                // Simulate user tapping 'Next'
                welcomeTour.forward()

                // Verify introClick called with 'next'
                XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next)
                XCTAssertEqual(analyticsSpy.introClickPageCalled, page)
                XCTAssertEqual(analyticsSpy.introClickIndexCalled, index + 1)
            }
            
            // Reset analyticsSpy properties
            analyticsSpy.introClickLabelCalled = nil
            analyticsSpy.introClickPageCalled = nil
            analyticsSpy.introClickIndexCalled = nil
        }
    }
    
    // MARK: News Detail
    
    func testNewsControllerViewDidAppearTracksNavigationViewNews() {
        // Create sample NewsModel
        let item = try! createMockNewsModel()!
        let items = [item]
        let newsController = NewsController(items: items)
        
        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.navigationActionCalled)
        XCTAssertNil(analyticsSpy.navigationLabelCalled)
        
        // Simulate view lifecycle
        newsController.loadViewIfNeeded()
        newsController.viewDidAppear(false)
        
        // Verify that navigation(.view, label: .news) was called
        XCTAssertEqual(analyticsSpy.navigationActionCalled, .view)
        XCTAssertEqual(analyticsSpy.navigationLabelCalled, .news)
    }
    
    func testNewsControllerDidSelectItemTracksNavigationOpenNews() {
        // Create sample NewsModel
        let item = try! createMockNewsModel()!
        let items = [item]
        let newsController = NewsController(items: items)
        
        // Ensure analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.navigationOpenNewsIdCalled)
        
        // Simulate view loading
        newsController.loadView()
        newsController.collection.reloadData()
        
        // Simulate item selection
        let indexPath = IndexPath(row: 0, section: 0)
        newsController.collectionView(newsController.collection, didSelectItemAt: indexPath)
        
        // Verify that navigationOpenNews was called with the correct id
        XCTAssertEqual(analyticsSpy.navigationOpenNewsIdCalled, "example_news_tracking")
    }
    
    // MARK: Multiply Impact - Referrals
    
    func testMultiplyImpactViewDidAppearTracksReferralViewInviteScreen() {
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        
        multiplyImpact.loadViewIfNeeded()
        multiplyImpact.viewDidAppear(false)
        
        XCTAssertEqual(analyticsSpy.referralActionCalled, .view)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .inviteScreen)
    }
    
    func testMultiplyImpactLearnMoreButtonTracksReferralClickLearnMore() {
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        
        multiplyImpact.loadViewIfNeeded()
        
        if let learnMoreButton = multiplyImpact.learnMoreButton {
            learnMoreButton.sendActions(for: .primaryActionTriggered)
        } else {
            XCTFail("Learn More button not found")
        }
        
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .learnMore)
    }
    
    func testMultiplyImpactCopyCodeTracksReferralClickLinkCopying() {
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        
        multiplyImpact.loadViewIfNeeded()
        
        if let copyControl = multiplyImpact.copyControl {
            copyControl.sendActions(for: .touchUpInside)
        } else {
            XCTFail("Copy Control not found")
        }
        
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .linkCopying)
    }
    
    func testMultiplyImpactInviteFriendsTracksReferralClickInvite() {
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        User.shared.referrals.code = "testCode"
        
        multiplyImpact.loadViewIfNeeded()
        
        if let inviteButton = multiplyImpact.inviteButton {
            inviteButton.sendActions(for: .touchUpInside)
        } else {
            XCTFail("Invite Friends button not found")
        }
        
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite)
    }
    
    func testMultiplyImpactInviteFriendsCompletionTracksReferralSendInvite() {
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpactTestable(referrals: referrals)
        User.shared.referrals.code = "testCode"
        
        multiplyImpact.loadViewIfNeeded()
        
        if let inviteButton = multiplyImpact.inviteButton {
            // Simulate user tapping the "Invite Friends" button
            inviteButton.sendActions(for: .touchUpInside)
        } else {
            XCTFail("Invite Friends button not found")
        }
        
        // Verify initial click analytics
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite)
        
        // Reset analyticsSpy properties
        analyticsSpy.referralActionCalled = nil
        analyticsSpy.referralLabelCalled = nil
        
        // Verify that the share sheet is intended to be presented
        XCTAssertNotNil(multiplyImpact.capturedPresentedViewController, "Expected a view controller to be presented")
        XCTAssertTrue(multiplyImpact.capturedPresentedViewController is UIActivityViewController, "Expected UIActivityViewController to be presented")
        
        // Simulate share completion
        if let activityVC = multiplyImpact.capturedPresentedViewController as? UIActivityViewController,
           let completionHandler = activityVC.completionWithItemsHandler {
            // Simulate user completed the share action
            completionHandler(nil, true, nil, nil)
            
            // Verify that referral(action: .send, label: .invite) was called
            XCTAssertEqual(analyticsSpy.referralActionCalled, .send)
            XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite)
        } else {
            XCTFail("UIActivityViewController not found or completion handler not set")
        }
    }
}

class MultiplyImpactTestable: MultiplyImpact {
    var capturedPresentedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        capturedPresentedViewController = viewControllerToPresent
    }
}
