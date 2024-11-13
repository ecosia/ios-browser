// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Core
import Storage
@testable import Client

final class AnalyticsSpy: Analytics {

    // MARK: - AnalyticsSpy Properties to Capture Calls

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

    // Added property for expectation
    var referralExpectation: XCTestExpectation?

    override func referral(action: Action.Referral, label: Label.Referral? = nil) {
        referralActionCalled = action
        referralLabelCalled = label
        // Ensure fulfillment on the main thread
        DispatchQueue.main.async {
            self.referralExpectation?.fulfill()
        }
    }

    var ntpTopSiteActionCalled: Action.TopSite?
    var ntpTopSitePropertyCalled: Property.TopSite?
    var ntpTopSitePositionCalled: NSNumber?
    override func ntpTopSite(_ action: Action.TopSite, property: Property.TopSite, position: NSNumber? = nil) {
        ntpTopSiteActionCalled = action
        ntpTopSitePropertyCalled = property
        ntpTopSitePositionCalled = position
    }
}

final class AnalyticsSpyTests: XCTestCase {

    // MARK: - Properties and Setup

    var analyticsSpy: AnalyticsSpy!

    var profileMock: MockProfile { MockProfile() }
    var tabManagerMock: TabManager {
        let mock = MockTabManager()
        mock.selectedTab = .init(profile: profileMock, configuration: .init())
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

    // MARK: - Helper Functions

    /// Helper function to wait for a condition with a timeout
    func waitForCondition(timeout: TimeInterval, condition: @escaping () -> Bool) {
        let expectation = self.expectation(description: "Waiting for condition")
        let checkInterval: TimeInterval = 0.05
        var timeElapsed: TimeInterval = 0

        Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            if condition() {
                expectation.fulfill()
                timer.invalidate()
            } else if timeElapsed >= timeout {
                timer.invalidate()
                XCTFail("Condition not met within \(timeout) seconds")
                expectation.fulfill()
            }
            timeElapsed += checkInterval
        }

        wait(for: [expectation], timeout: timeout + 0.1)
    }

    // MARK: - AppDelegate Tests

    var appDelegate: AppDelegate { AppDelegate() }

    func testTrackLaunchAndInstallOnDidFinishLaunching() async {
        // Arrange
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.application(application, didFinishLaunchingWithOptions: nil)

        // Assert
        XCTAssert(analyticsSpy.installCalled)
        waitForCondition(timeout: 3) { // Wait detached tasks until launch is called
            self.analyticsSpy.activityActionCalled == .launch
        }
    }

    func testTrackResumeOnDidFinishLaunching() async {
        // Arrange
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.applicationDidBecomeActive(application)

        // Assert
        waitForCondition(timeout: 2) { // Wait detached tasks until resume is called
            self.analyticsSpy.activityActionCalled == .resume
        }
    }

    // MARK: - Bookmarks Tests

    var panel: BookmarksPanel {
        let viewModel = BookmarksPanelViewModel(profile: profileMock, bookmarkFolderGUID: "TestGuid")
        return BookmarksPanel(viewModel: viewModel)
    }

    func testTrackImportClick() {
        // Arrange
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        // Act
        panel.importBookmarksActionHandler()

        // Assert
        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .import)
    }

    func testTrackExportClick() {
        // Arrange
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        // Act
        panel.exportBookmarksActionHandler()

        // Assert
        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .export)
    }

    func testTrackLearnMoreClick() {
        // Arrange
        let view = EmptyBookmarksView(initialBottomMargin: 0)
        XCTAssertFalse(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled)

        // Act
        view.onLearnMoreTapped()

        // Assert
        XCTAssertTrue(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled)
    }

    // MARK: - Menu Tests

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
                // Arrange
                XCTAssertNil(analyticsSpy.menuClickItemCalled)
                tabManagerMock.selectedTab?.url = URL(string: "https://example.com")
                let expectation = self.expectation(description: "Actions for \(title) are returned")

                // Act
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let action = actions
                        .flatMap { $0 } // Flatten sections
                        .flatMap { $0.items } // Flatten items in sections
                        .first { $0.title == title }
                    if let action = action {
                        action.tapHandler!(action)
                        // Assert
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
                // Arrange
                XCTAssertNil(analyticsSpy.menuShareContentCalled)
                tabManagerMock.selectedTab?.url = url

                // Create an expectation if the analytics call is asynchronous
                // If not, this can be omitted
                // For safety, we include it
                let expectation = self.expectation(description: "Analytics menuShare called")
                analyticsSpy.referralExpectation = expectation

                // Act
                let action = menuHelper.getSharingAction().items.first
                if let action = action {
                    action.tapHandler!(action)
                } else {
                    XCTFail("No sharing action found for url \(url?.absoluteString ?? "nil")")
                }

                // Wait for the expectation
                waitForExpectations(timeout: 1)

                // Assert
                XCTAssertEqual(analyticsSpy.menuShareContentCalled, label)
            }
        }
    }

    func testTrackMenuStatus() {
        struct MenuStatusTestCase {
            let label: Analytics.Label.MenuStatus
            let value: Bool
            let title: String
        }

        let testCases: [MenuStatusTestCase] = [
            MenuStatusTestCase(label: .readingList, value: true, title: .ShareAddToReadingList),
            MenuStatusTestCase(label: .readingList, value: false, title: .AppMenu.RemoveReadingList),
            MenuStatusTestCase(label: .bookmark, value: true, title: .KeyboardShortcuts.AddBookmark),
            MenuStatusTestCase(label: .shortcut, value: true, title: .AddToShortcutsActionTitle),
            MenuStatusTestCase(label: .shortcut, value: false, title: .AppMenu.RemoveFromShortcuts)
        ]

        for testCase in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            let label = testCase.label
            let value = testCase.value
            let title = testCase.title
            XCTContext.runActivity(named: "Menu status change \(label.rawValue) to \(value) is tracked") { _ in
                // Arrange
                XCTAssertNil(analyticsSpy.menuStatusItemCalled)
                XCTAssertNil(analyticsSpy.menuStatusItemChangedTo)
                let testUrl = "https://example.com"
                tabManagerMock.selectedTab?.url = URL(string: testUrl)
                let expectation = self.expectation(description: "Actions are returned")

                // Act
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let action = actions
                        .flatMap { $0 } // Flatten sections
                        .flatMap { $0.items } // Flatten items in sections
                        .first { $0.title == title }
                    if let action = action {
                        action.tapHandler!(action)
                        // Assert
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

    // MARK: - Onboarding / Welcome Tests

    func testWelcomeViewDidAppearTracksIntroDisplayingAndIntroClickStart() {
        // Arrange
        let welcomeDelegate = MockWelcomeDelegate()
        let welcome = Welcome(delegate: welcomeDelegate)
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)
        XCTAssertNil(analyticsSpy.introDisplayingIndexCalled)

        // Act
        welcome.loadViewIfNeeded()
        welcome.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .start)
        XCTAssertEqual(analyticsSpy.introDisplayingIndexCalled, 0)
    }

    func testWelcomeGetStartedTracksIntroClickNext() {
        // Arrange
        let welcomeDelegate = MockWelcomeDelegate()
        let welcome = Welcome(delegate: welcomeDelegate)
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcome.getStarted()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 0)
    }

    func testWelcomeSkipTracksIntroClickSkip() {
        // Arrange
        let welcomeDelegate = MockWelcomeDelegate()
        let welcome = Welcome(delegate: welcomeDelegate)
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcome.skip()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 0)
    }

    // MARK: - Onboarding / Welcome Tour Tests

    func testWelcomeTourViewDidAppearTracksIntroDisplaying() {
        // Arrange
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)
        XCTAssertNil(analyticsSpy.introDisplayingIndexCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .greenSearch)
        XCTAssertEqual(analyticsSpy.introDisplayingIndexCalled, 1)
    }

    func testWelcomeTourNextTracksIntroClickNext() {
        // Arrange
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)
        welcomeTour.forward()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 1)
    }

    func testWelcomeTourSkipTracksIntroClickSkip() {
        // Arrange
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)
        welcomeTour.skip()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip)
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch)
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 1)
    }

    func testWelcomeTourTracksAnalyticsForAllPages() {
        // Arrange
        let welcomeTourDelegate = MockWelcomeTourDelegate()
        let welcomeTour = WelcomeTour(delegate: welcomeTourDelegate)
        let pages: [Analytics.Property.OnboardingPage] = [
            .greenSearch,
            .profits,
            .action,
            .transparentFinances
        ]
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        for (index, page) in pages.enumerated() {
            // Reset analyticsSpy properties
            analyticsSpy.introDisplayingPageCalled = nil
            analyticsSpy.introDisplayingIndexCalled = nil

            if index < pages.count - 1 {
                // Act
                welcomeTour.forward()

                // Assert
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

    // MARK: - News Detail Tests

    func testNewsControllerViewDidAppearTracksNavigationViewNews() {
        // Arrange
        do {
            let item = try createMockNewsModel()!
            let items = [item]
            let newsController = NewsController(items: items)
            XCTAssertNil(analyticsSpy.navigationActionCalled)
            XCTAssertNil(analyticsSpy.navigationLabelCalled)

            // Act
            newsController.loadViewIfNeeded()
            newsController.viewDidAppear(false)

            // Assert
            XCTAssertEqual(analyticsSpy.navigationActionCalled, .view)
            XCTAssertEqual(analyticsSpy.navigationLabelCalled, .news)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testNewsControllerDidSelectItemTracksNavigationOpenNews() {
        // Arrange
        do {
            let item = try createMockNewsModel()!
            let items = [item]
            let newsController = NewsController(items: items)
            XCTAssertNil(analyticsSpy.navigationOpenNewsIdCalled)
            newsController.loadView()
            newsController.collection.reloadData()
            let indexPath = IndexPath(row: 0, section: 0)

            // Act
            newsController.collectionView(newsController.collection, didSelectItemAt: indexPath)

            // Assert
            XCTAssertEqual(analyticsSpy.navigationOpenNewsIdCalled, "example_news_tracking")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Multiply Impact - Referrals Tests

    func testMultiplyImpactViewDidAppearTracksReferralViewInviteScreen() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        multiplyImpact.loadViewIfNeeded()

        // Act
        multiplyImpact.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .view)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .inviteScreen)
    }

    func testMultiplyImpactLearnMoreButtonTracksReferralClickLearnMore() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        multiplyImpact.loadViewIfNeeded()

        // Ensure learnMoreButton is not nil
        XCTAssertNotNil(multiplyImpact.learnMoreButton, "learnMoreButton should not be nil after view is loaded")

        // Create an expectation
        let expectation = self.expectation(description: "Analytics referral called")
        analyticsSpy.referralExpectation = expectation

        // Act
        multiplyImpact.learnMoreButton.sendActions(for: .primaryActionTriggered)

        // Wait for the expectation
        waitForExpectations(timeout: 1)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .learnMore)
    }

    func testMultiplyImpactCopyCodeTracksReferralClickLinkCopying() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        multiplyImpact.loadViewIfNeeded()
        XCTAssertNotNil(multiplyImpact.copyControl, "copyControl should not be nil after view is loaded")

        // Create an expectation
        let expectation = self.expectation(description: "Analytics referral called")
        analyticsSpy.referralExpectation = expectation

        // Act
        multiplyImpact.copyControl?.sendActions(for: .touchUpInside)

        // Wait for the expectation
        waitForExpectations(timeout: 1)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .linkCopying)
    }

    func testMultiplyImpactInviteFriendsTracksReferralClickInvite() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals)
        User.shared.referrals.code = "testCode"
        multiplyImpact.loadViewIfNeeded()

        // Act
        if let inviteButton = multiplyImpact.inviteButton {
            inviteButton.sendActions(for: .touchUpInside)
        } else {
            XCTFail("Invite Friends button not found")
        }

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click)
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite)
    }

    func testMultiplyImpactInviteFriendsCompletionTracksReferralSendInvite() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpactTestable(referrals: referrals)
        User.shared.referrals.code = "testCode"
        multiplyImpact.loadViewIfNeeded()

        // Act
        if let inviteButton = multiplyImpact.inviteButton {
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

        // Assert that the share sheet is intended to be presented
        XCTAssertNotNil(multiplyImpact.capturedPresentedViewController, "Expected a view controller to be presented")
        XCTAssertTrue(multiplyImpact.capturedPresentedViewController is UIActivityViewController, "Expected UIActivityViewController to be presented")

        // Simulate share completion
        if let activityVC = multiplyImpact.capturedPresentedViewController as? UIActivityViewController,
           let completionHandler = activityVC.completionWithItemsHandler {
            // Simulate user completed the share action
            completionHandler(nil, true, nil, nil)

            // Assert
            XCTAssertEqual(analyticsSpy.referralActionCalled, .send)
            XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite)
        } else {
            XCTFail("UIActivityViewController not found or completion handler not set")
        }
    }

    // MARK: - Top Sites Tests

    func testTilePressedTracksAnalyticsForPinnedSite() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let topSite = TopSite(site: PinnedSite(site: Site(url: "http://www.example.com", title: "Example Site")))
        let position = 1

        // Act
        viewModel.tilePressed(site: topSite, position: position)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, .click)
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .pinned)
        XCTAssertEqual(analyticsSpy.ntpTopSitePositionCalled, NSNumber(value: position))
    }

    func testTilePressedTracksAnalyticsForDefaultSite() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let topSite = TopSite(site: Site(url: Environment.current.urlProvider.financialReports.absoluteString, title: "Example Site"))
        let position = 1

        // Act
        viewModel.tilePressed(site: topSite, position: position)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, .click)
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .default)
        XCTAssertEqual(analyticsSpy.ntpTopSitePositionCalled, NSNumber(value: position))
    }

    func testTilePressedTracksAnalyticsForMostVisitedSite() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let topSite = TopSite(site: Site(url: "http://www.example.org", title: "Example Site"))
        let position = 1

        // Act
        viewModel.tilePressed(site: topSite, position: position)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, .click)
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .mostVisited)
        XCTAssertEqual(analyticsSpy.ntpTopSitePositionCalled, NSNumber(value: position))
    }

    func testTrackTopSiteMenuActionTracksAnalytics() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let action: Analytics.Action.TopSite = .remove
        let site = Site(url: "http://www.example.org", title: "Example Site")

        // Act
        viewModel.trackTopSiteMenuAction(site: site, action: action)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, action)
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .mostVisited) // Assuming site is mostVisited
        XCTAssertNil(analyticsSpy.ntpTopSitePositionCalled)
    }

    func testNTPAboutEcosiaCellLearnMoreActionTracksNavigationOpen() {
        // Arrange

        // Create an instance of the real NTPAboutEcosiaCellViewModel
        let aboutViewModel = NTPAboutEcosiaCellViewModel(theme: EcosiaLightTheme())
        let sections = aboutViewModel.sections

        // Ensure that there are sections available
        guard let testSection = sections.first else {
            XCTFail("No sections available in NTPAboutEcosiaCellViewModel")
            return
        }

        // Create an instance of NTPAboutEcosiaCell
        let aboutCell = NTPAboutEcosiaCell(frame: CGRect(x: 0, y: 0, width: 320, height: 64))

        // Configure the cell with the real section and view model
        aboutCell.configure(section: testSection, viewModel: aboutViewModel)

        // Ensure that the analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.navigationActionCalled)
        XCTAssertNil(analyticsSpy.navigationLabelCalled)

        // Act

        // Simulate tapping the "Learn More" button by sending the touchUpInside action
        aboutCell.learnMoreButton.sendActions(for: .touchUpInside)

        // Assert

        // Verify that the analytics event was called with the correct action and label
        XCTAssertEqual(analyticsSpy.navigationActionCalled, .open)
        XCTAssertEqual(analyticsSpy.navigationLabelCalled, testSection.label)
    }
}

// MARK: - Helper Classes

class MultiplyImpactTestable: MultiplyImpact {
    var capturedPresentedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        capturedPresentedViewController = viewControllerToPresent
    }
}
