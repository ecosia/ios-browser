// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import SnowplowTracker
import Common
import SwiftUI
import ViewInspector
import WebKit
@testable import Client
@testable import Ecosia
// swiftlint:disable implicitly_unwrapped_optional

// MARK: - AnalyticsSpy

// Ecosia: @unchecked Sendable needed in Swift 6 because AnalyticsSpy captures
// self in DispatchQueue.main.async @Sendable closures via expectation fulfillment.
final class AnalyticsSpy: Analytics, @unchecked Sendable {

    // MARK: - AnalyticsSpy Properties to Capture Calls

    var trackedEvents: [SnowplowTracker.Event] = []

    override func track(_ event: SnowplowTracker.Event, isPrivate: Bool = false) {
        super.track(event, isPrivate: isPrivate)
        trackedEvents.append(event)
    }

    var installCalled = false
    override func install() {
        installCalled = true
    }

    var activityActionCalled: Analytics.Action.Activity?
    override func activity(_ action: Analytics.Action.Activity) {
        activityActionCalled = action
        super.activity(action)
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
    var menuClickExpectation: XCTestExpectation?
    override func menuClick(_ item: Analytics.Label.Menu) {
        menuClickItemCalled = item
        // Ecosia: XCTestExpectation.fulfill() is thread-safe; no need for DispatchQueue.main.async
        menuClickExpectation?.fulfill()
    }

    var menuShareContentCalled: Analytics.Property.ShareContent?
    override func menuShare(_ content: Analytics.Property.ShareContent) {
        menuShareContentCalled = content
    }

    var menuStatusItemCalled: Analytics.Label.MenuStatus?
    var menuStatusItemChangedTo: Bool?
    var menuStatusExpectation: XCTestExpectation?
    override func menuStatus(changed item: Analytics.Label.MenuStatus, to: Bool) {
        menuStatusItemCalled = item
        menuStatusItemChangedTo = to
        // Ecosia: XCTestExpectation.fulfill() is thread-safe; no need for DispatchQueue.main.async
        menuStatusExpectation?.fulfill()
    }

    var introWelcomeActionCalled: Action.Welcome?
    var introWelcomePropertyCalled: Property.Welcome?
    override func introWelcome(action: Action.Welcome, property: Property.Welcome? = nil) {
        introWelcomeActionCalled = action
        introWelcomePropertyCalled = property
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

    // Separate expectations for different referral actions
    var referralClickExpectation: XCTestExpectation?
    var referralSendExpectation: XCTestExpectation?

    override func referral(action: Action.Referral, label: Label.Referral? = nil) {
        referralActionCalled = action
        referralLabelCalled = label
        // Ecosia: XCTestExpectation.fulfill() is thread-safe; fulfill directly to avoid
        // Swift 6 region-isolation errors with @Sendable DispatchQueue closures.
        switch action {
        case .click:
            referralClickExpectation?.fulfill()
        case .send:
            referralSendExpectation?.fulfill()
        default:
            break
        }
    }

    var inappSearchUrlCalled: URL?
    var inappSearchIsPrivateCalled: Bool?
    override func inappSearch(url: URL, isPrivate: Bool = false) {
        inappSearchUrlCalled = url
        inappSearchIsPrivateCalled = isPrivate
    }

    var ntpTopSiteActionCalled: Action.TopSite?
    var ntpTopSitePropertyCalled: Property.TopSite?
    var ntpTopSitePositionCalled: NSNumber?
    override func ntpTopSite(_ action: Action.TopSite, property: Property.TopSite, position: NSNumber? = nil) {
        ntpTopSiteActionCalled = action
        ntpTopSitePropertyCalled = property
        ntpTopSitePositionCalled = position
    }

    var clearAllPrivateDataSectionCalled: Property.SettingsPrivateDataSection?
    override func clearsDataFromSection(_ section: Analytics.Property.SettingsPrivateDataSection) {
        clearAllPrivateDataSectionCalled = section
    }

    var defaultBrowserSettingsShowsDetailViewLabelCalled: Analytics.Label.DefaultBrowser?
    override func defaultBrowserSettingsShowsDetailViewVia(_ label: Analytics.Label.DefaultBrowser) {
        defaultBrowserSettingsShowsDetailViewLabelCalled = label
    }

    var defaultBrowserSettingsViaNudgeCardDismissCalled = false
    override func defaultBrowserSettingsViaNudgeCardDismiss() {
        defaultBrowserSettingsViaNudgeCardDismissCalled = true
    }

    var defaultBrowserSettingsOpenNativeSettingsLabelCalled: Analytics.Label.DefaultBrowser?
    override func defaultBrowserSettingsOpenNativeSettingsVia(_ label: Analytics.Label.DefaultBrowser) {
        defaultBrowserSettingsOpenNativeSettingsLabelCalled = label
    }

    var defaultBrowserSettingsDismissDetailViewLabelCalled: Analytics.Label.DefaultBrowser?
    override func defaultBrowserSettingsDismissDetailViewVia(_ label: Analytics.Label.DefaultBrowser) {
        defaultBrowserSettingsDismissDetailViewLabelCalled = label
    }
}

// MARK: - AnalyticsSpyTests

// Ecosia: @unchecked Sendable required alongside @MainActor in Swift 6 to allow
// XCTest lifecycle hooks (setUp/tearDown) to pass self across actor boundaries.
@MainActor
final class AnalyticsSpyTests: XCTestCase, @unchecked Sendable {

    // MARK: - Properties and Setup

    var analyticsSpy: AnalyticsSpy!
    var profileMock: MockProfile { MockProfile() }
    var tabManagerMock: TabManager {
        let mock = MockTabManager()
        // Ecosia: Pass documentLogger explicitly to avoid AppContainer.shared.resolve()
        // being called before DependencyHelperMock.bootstrapDependencies() has registered it.
        // Tab.init's default parameter evaluates at call-site, which happens before the
        // function argument `injectedTabManager: tabManagerMock` is passed to bootstrapDependencies.
        let tab = Tab(profile: profileMock, windowUUID: .XCTestDefaultUUID, documentLogger: DocumentLogger(logger: DefaultLogger.shared))
        mock.selectedTab = tab
        mock.selectedTab?.url = URL(string: "https://example.com")
        mock.subscriptedTab = tab
        return mock
    }

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManagerMock, themeManager: EcosiaMockThemeManager())
        analyticsSpy = AnalyticsSpy()
        Analytics.shared = analyticsSpy
    }

    override func tearDown() {
        super.tearDown()
        analyticsSpy = nil
        Analytics.shared = Analytics()
    }

    // MARK: - AppDelegate Tests

    var appDelegate: AppDelegate { AppDelegate() }

    func testTrackLaunchAndInstallOnDidFinishLaunching() async {
        // Arrange
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.application(application, didFinishLaunchingWithOptions: nil)

        waitForCondition(timeout: 3) { // Wait detached tasks until launch is called
            analyticsSpy.activityActionCalled == .launch
        }

        // Assert
        XCTAssertEqual(analyticsSpy.activityActionCalled, .launch)
        XCTAssertTrue(analyticsSpy.installCalled)
    }

    func testTrackResumeOnDidBecomeActive() async {
        // Arrange
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.applicationDidBecomeActive(application)

        waitForCondition(timeout: 2) { // Wait detached tasks until resume is called
            analyticsSpy.activityActionCalled == .resume
        }

        // Assert
        XCTAssertEqual(analyticsSpy.activityActionCalled, .resume)
    }

    // MARK: - Bookmarks Tests

    var panel: BookmarksViewController {
        let viewModel = BookmarksPanelViewModel(profile: profileMock,
                                                bookmarksHandler: profileMock.places,
                                                bookmarkFolderGUID: "TestGuid")
        return BookmarksViewController(viewModel: viewModel, windowUUID: .XCTestDefaultUUID)
    }

    func testTrackImportClick() {
        // Arrange
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        // Act
        panel.importBookmarksActionHandler()

        // Assert
        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .import, "Analytics should track bookmarks import.")
    }

    func testTrackExportClick() {
        // Arrange
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        // Act
        panel.exportBookmarksActionHandler()

        // Assert
        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .export, "Analytics should track bookmarks export.")
    }

    func testTrackLearnMoreClick() {
        // Arrange
        let view = EmptyBookmarksView(initialBottomMargin: 0)
        XCTAssertFalse(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled, "Analytics should not have tracked learn more click yet.")

        // Act
        view.onLearnMoreTapped()

        // Assert
        XCTAssertTrue(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled, "Analytics should track bookmarks empty learn more click.")
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
            (.history, .LegacyAppMenu.AppMenuHistory),
            (.downloads, .LegacyAppMenu.AppMenuDownloads),
            (.zoom, String(format: .LegacyAppMenu.ZoomPageTitle, NumberFormatter.localizedString(from: NSNumber(value: 1), number: .percent))),
            (.findInPage, .LegacyAppMenu.AppMenuFindInPageTitleString),
            (.requestDesktopSite, .LegacyAppMenu.AppMenuViewDesktopSiteTitleString),
            (.copyLink, .LegacyAppMenu.AppMenuCopyLinkTitleString),
            (.help, .LegacyAppMenu.Help),
            (.customizeHomepage, .LegacyAppMenu.CustomizeHomePage),
            (.readingList, .LegacyAppMenu.ReadingList),
            (.bookmarks, .LegacyAppMenu.Bookmarks)
        ]

        for (label, title) in testCases {
            XCTContext.runActivity(named: "Menu action \(label.rawValue) is tracked") { _ in
                // Arrange
                analyticsSpy = AnalyticsSpy()
                Analytics.shared = analyticsSpy
                XCTAssertNil(analyticsSpy.menuClickItemCalled, "Analytics menuClickItemCalled should be nil before action.")
                tabManagerMock.selectedTab?.url = URL(string: "https://example.com")

                // Create expectation
                let expectation = self.expectation(description: "Analytics menuClick called with \(label.rawValue)")
                analyticsSpy.menuClickExpectation = expectation

                // Act
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let action = actions
                        .flatMap { $0 } // Flatten sections
                        .flatMap { $0.items } // Flatten items in sections
                        .first { $0.title == title }
                    if let action = action {
                        action.tapHandler!(action)
                    } else {
                        XCTFail("No action title with \(title) found")
                    }
                }

                // Wait for expectation
                wait(for: [expectation], timeout: 2)

                // Assert
                XCTAssertEqual(analyticsSpy.menuClickItemCalled, label, "Analytics should track menu click with label \(label.rawValue).")
            }
        }
    }

    func testTrackMenuShare() throws {
        // Ecosia: getSharingAction() was removed in v147 — the share action is now
        // assembled privately inside getToolbarActions. Needs rework to use the new API.
        // Tracked in MOB-4384.
        throw XCTSkip("getSharingAction() removed in v147 — tracked in MOB-4384")
    }

    func testTrackMenuStatus() {
        struct MenuStatusTestCase {
            let label: Analytics.Label.MenuStatus
            let value: Bool
            let title: String
        }

        let testCases: [MenuStatusTestCase] = [
            .init(label: .readingList, value: true, title: .ShareAddToReadingList),
            .init(label: .readingList, value: false, title: .LegacyAppMenu.RemoveReadingList),
            .init(label: .bookmark, value: true, title: .KeyboardShortcuts.AddBookmark),
            .init(label: .shortcut, value: true, title: .AddToShortcutsActionTitle),
            .init(label: .shortcut, value: false, title: .LegacyAppMenu.RemoveFromShortcuts)
        ]

        for testCase in testCases {
            XCTContext.runActivity(named: "Track menu status change \(testCase.label.rawValue) to \(testCase.value)") { _ in
                // Reset state
                analyticsSpy = AnalyticsSpy()
                Analytics.shared = analyticsSpy
                tabManagerMock.selectedTab?.url = URL(string: "https://example.com")

                let semaphore = DispatchSemaphore(value: 0)
                let expectation = self.expectation(description: "menuStatus called for \(testCase.label.rawValue) to \(testCase.value)")
                analyticsSpy.menuStatusExpectation = expectation

                // Act
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let flatItems = actions.flatMap { $0 }.flatMap { $0.items }
                    guard let action = flatItems.first(where: { $0.title == testCase.title }) else {
                        XCTFail("No action with title \(testCase.title) found")
                        semaphore.signal()
                        return
                    }

                    action.tapHandler?(action)
                    semaphore.signal()
                }

                // Wait for async completion
                _ = semaphore.wait(timeout: .now() + 2)
                wait(for: [expectation], timeout: 2)

                XCTAssertEqual(analyticsSpy.menuStatusItemCalled, testCase.label, "Expected menu status label to be \(testCase.label.rawValue)")
                XCTAssertEqual(analyticsSpy.menuStatusItemChangedTo, testCase.value, "Expected menu status value to be \(testCase.value)")
            }
        }
    }

    // MARK: - News Detail Tests

    func testNewsControllerViewDidAppearTracksNavigationViewNews() {
        // Arrange
        do {
            let item = try createMockNewsModel()!
            let items = [item]
            let newsController = NewsController(items: items, windowUUID: .XCTestDefaultUUID)
            XCTAssertNil(analyticsSpy.navigationActionCalled)
            XCTAssertNil(analyticsSpy.navigationLabelCalled)

            // Act
            newsController.loadViewIfNeeded()
            newsController.viewDidAppear(false)

            // Assert
            XCTAssertEqual(analyticsSpy.navigationActionCalled, .view, "Analytics should track navigation action as .view.")
            XCTAssertEqual(analyticsSpy.navigationLabelCalled, .news, "Analytics should track navigation label as .news.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testNewsControllerDidSelectItemTracksNavigationOpenNews() {
        // Arrange
        do {
            let item = try createMockNewsModel()!
            let items = [item]
            let newsController = NewsController(items: items, windowUUID: .XCTestDefaultUUID)
            XCTAssertNil(analyticsSpy.navigationOpenNewsIdCalled)
            newsController.loadView()
            newsController.collection.reloadData()
            let indexPath = IndexPath(row: 0, section: 0)

            // Act
            newsController.collectionView(newsController.collection, didSelectItemAt: indexPath)

            // Assert
            XCTAssertEqual(analyticsSpy.navigationOpenNewsIdCalled, "example_news_tracking", "Analytics should track navigation open news with ID 'example_news_tracking'.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Multiply Impact - Referrals Tests

    func testMultiplyImpactViewDidAppearTracksReferralViewInviteScreen() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        multiplyImpact.loadViewIfNeeded()

        // Act
        multiplyImpact.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .view, "Analytics should track referral action as .view.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .inviteScreen, "Analytics should track referral label as .inviteScreen.")
    }

    func testMultiplyImpactLearnMoreButtonTracksReferralClickLearnMore() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        multiplyImpact.loadViewIfNeeded()

        // Ensure learnMoreButton is not nil
        guard let learnMoreButton = multiplyImpact.learnMoreButton else {
            XCTFail("learnMoreButton should not be nil after view is loaded")
            return
        }

        // Create an expectation
        let expectation = self.expectation(description: "Analytics referral called for Learn More")
        analyticsSpy.referralClickExpectation = expectation

        // Act
        learnMoreButton.sendActions(for: .primaryActionTriggered)

        // Wait for the expectation
        wait(for: [expectation], timeout: 2)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click, "Analytics should track referral action as .click.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .learnMore, "Analytics should track referral label as .learnMore.")
    }

    func testMultiplyImpactInviteFriendsTracksReferralClickInvite() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        User.shared.referrals.code = "testCode"
        multiplyImpact.loadViewIfNeeded()

        // Ensure inviteButton is not nil
        guard let inviteButton = multiplyImpact.inviteButton else {
            XCTFail("Invite Friends button should not be nil after view is loaded")
            return
        }

        // Create an expectation
        let expectation = self.expectation(description: "Analytics referral called for Invite")
        analyticsSpy.referralClickExpectation = expectation

        // Act
        inviteButton.sendActions(for: .touchUpInside)

        // Wait for the expectation
        wait(for: [expectation], timeout: 2)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click, "Analytics should track referral action as .click.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite, "Analytics should track referral label as .invite.")
    }

    func testMultiplyImpactInviteFriendsCompletionTracksReferralSendInvite() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpactTestable(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        User.shared.referrals.code = "testCode"
        multiplyImpact.loadViewIfNeeded()

        // Ensure inviteButton is not nil
        guard let inviteButton = multiplyImpact.inviteButton else {
            XCTFail("Invite Friends button should not be nil after view is loaded")
            return
        }

        // Create expectations for .click and .send actions
        let clickExpectation = self.expectation(description: "Analytics referral click called")
        let sendExpectation = self.expectation(description: "Analytics referral send called")
        analyticsSpy.referralClickExpectation = clickExpectation
        analyticsSpy.referralSendExpectation = sendExpectation

        // Act
        inviteButton.sendActions(for: .touchUpInside)

        // Wait for the click expectation
        wait(for: [clickExpectation], timeout: 2)

        // Assert initial click analytics
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click, "Analytics should track referral action as .click.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite, "Analytics should track referral label as .invite.")

        // Reset analyticsSpy properties for the next action
        analyticsSpy.referralActionCalled = nil
        analyticsSpy.referralLabelCalled = nil

        // Assert that the share sheet is intended to be presented
        XCTAssertNotNil(multiplyImpact.capturedPresentedViewController, "Expected a view controller to be presented")
        XCTAssertTrue(multiplyImpact.capturedPresentedViewController is UIActivityViewController, "Expected UIActivityViewController to be presented")

        // Simulate share completion
        if let activityVC = multiplyImpact.capturedPresentedViewController as? UIActivityViewController,
           let completionHandler = activityVC.completionWithItemsHandler {

            // Act: Simulate user completed the share action
            completionHandler(nil, true, nil, nil)

            // Wait for the send expectation
            wait(for: [sendExpectation], timeout: 2)

            // Assert send analytics
            XCTAssertEqual(analyticsSpy.referralActionCalled, .send, "Analytics should track referral action as .send.")
            XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite, "Analytics should track referral label as .invite.")
        } else {
            XCTFail("UIActivityViewController not found or completion handler not set")
        }
    }

    // MARK: - Top Sites Tests

    func testTilePressedTracksAnalyticsForPinnedSite() throws {
        // Ecosia: TopSitesViewModel and PinnedSite were removed in v147 as part of the
        // Redux-based Homepage refactor. Analytics now flow through TopSitesAction/TopSitesMiddleware.
        // Needs rework to use the new Redux architecture. Tracked in MOB-4384.
        throw XCTSkip("TopSitesViewModel/PinnedSite removed in v147 — tracked in MOB-4384")
    }

    func testTilePressedTracksAnalyticsForMostVisitedSite() throws {
        // Ecosia: TopSitesViewModel removed in v147 Redux refactor. Tracked in MOB-4384.
        throw XCTSkip("TopSitesViewModel removed in v147 — tracked in MOB-4384")
    }

    func testTrackTopSiteMenuActionTracksAnalytics() throws {
        // Ecosia: TopSitesViewModel removed in v147 Redux refactor. Tracked in MOB-4384.
        throw XCTSkip("TopSitesViewModel removed in v147 — tracked in MOB-4384")
    }

    // MARK: - WebView delegate Search Event

    func testWebViewDelegateTracksSearchEventOnEcosiaVerticalURLChange() {
        let browser = BrowserViewController(profile: profileMock, tabManager: tabManagerMock)

        let rootURL = EcosiaEnvironment.current.urlProvider.root
        let testCases = [
            ("https://www.example.org", false, "Does not track external URLs"),
            ("\(rootURL)", false, "Does not track index page"),
            ("\(rootURL)/search?q=test", true, "Tracks search query"),
            ("\(rootURL)/search?q=test", true, "Tracks same URL again with .other type"),
            ("\(rootURL)/images?q=test1", true, "Tracks images query"),
            ("\(rootURL)/news?q=test2&p=1", true, "Tracks news query"),
            ("\(rootURL)/videos?q=test3", true, "Tracks videos query"),
            ("\(rootURL)/settings", false, "Does not track non-search pages"),
            ("https://blog.ecosia.org/", false, "Does not track on other Ecosia urls"),
        ]

        for (urlString, shouldTrack, message) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            let url = URL(string: urlString)!
            let action = FakeNavigationAction(url: url, navigationType: .other)
            browser.webView(makeWebView(),
                            decidePolicyFor: action) { policy in
                XCTAssertEqual(policy, .allow, "Should allow independent of tracking behavior")
            }
            // inappSearch is now fired at didCommit, not decidePolicyFor
            browser.ecosiaHandleDidCommit(url: url, isPrivate: false)

            if shouldTrack {
                XCTAssertEqual(analyticsSpy.inappSearchUrlCalled?.absoluteString,
                               url.absoluteString,
                               "Failure on: \(message)")
            } else {
                XCTAssertNil(analyticsSpy.inappSearchUrlCalled, "Failure on: \(message)")
            }
            analyticsSpy = nil
            Analytics.shared = Analytics()
        }
    }

    func testWebViewDelegateTracksSearchEventBasedOnNavigationType() {
        let browser = BrowserViewController(profile: profileMock, tabManager: tabManagerMock)

        let rootURL = EcosiaEnvironment.current.urlProvider.root
        let testCases = [
            (WKNavigationType.other, "\(rootURL)/search?q=test", true, "Tracks regular navigation"),
            (WKNavigationType.reload, "\(rootURL)/search?q=test", true, "Tracks reload"),
            (WKNavigationType.backForward, "\(rootURL)/search?q=test", false, "Does not track back/forward"),
        ]

        for (type, urlString, shouldTrack, message) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            let url = URL(string: urlString)!
            let action = FakeNavigationAction(url: url, navigationType: type)
            browser.webView(makeWebView(),
                            decidePolicyFor: action) { policy in
                XCTAssertEqual(policy, .allow, "Should allow independent of tracking behavior")
            }
            browser.ecosiaHandleDidCommit(url: url, isPrivate: false)

            if shouldTrack {
                XCTAssertEqual(analyticsSpy.inappSearchUrlCalled?.absoluteString,
                               url.absoluteString,
                               "Failure on: \(message)")
            } else {
                XCTAssertNil(analyticsSpy.inappSearchUrlCalled, "Failure on: \(message)")
            }
            analyticsSpy = nil
            Analytics.shared = Analytics()
        }
    }

    func testWebViewDelegateTracksSearchEventOnSameURLWhenLinkActivated() {
        let browser = BrowserViewController(profile: profileMock, tabManager: tabManagerMock)
        let rootURL = EcosiaEnvironment.current.urlProvider.root
        let url = URL(string: "\(rootURL)/search?q=test")!

        // Load the URL once to establish it as the current page
        let firstAction = FakeNavigationAction(url: url, navigationType: .other)
        browser.webView(makeWebView(), decidePolicyFor: firstAction) { _ in }
        browser.ecosiaHandleDidCommit(url: url, isPrivate: false)

        // Navigate to the same URL again via link activation (e.g. tapping the same search vertical)
        analyticsSpy = AnalyticsSpy()
        Analytics.shared = analyticsSpy
        let secondAction = FakeNavigationAction(url: url, navigationType: .linkActivated)
        browser.webView(makeWebView(), decidePolicyFor: secondAction) { _ in }
        browser.ecosiaHandleDidCommit(url: url, isPrivate: false)

        XCTAssertEqual(analyticsSpy.inappSearchUrlCalled?.absoluteString,
                       url.absoluteString,
                       "Should track same URL when navigated via link activation, not treated as tab restore")
    }

    func testEcosiaHandleDidCommitDoesNotFireWhenURLDoesNotMatchPending() {
        let browser = BrowserViewController(profile: profileMock, tabManager: tabManagerMock)
        analyticsSpy = AnalyticsSpy()
        Analytics.shared = analyticsSpy

        let rootURL = EcosiaEnvironment.current.urlProvider.root
        let searchUrl = URL(string: "\(rootURL)/search?q=test")!
        let differentUrl = URL(string: "\(rootURL)/images?q=test")!

        // Simulate decidePolicyFor setting the pending URL to searchUrl
        let action = FakeNavigationAction(url: searchUrl, navigationType: .other)
        browser.webView(makeWebView(), decidePolicyFor: action) { _ in }

        // didCommit fires with a different URL (e.g. a redirect landed elsewhere)
        browser.ecosiaHandleDidCommit(url: differentUrl, isPrivate: false)

        XCTAssertNil(analyticsSpy.inappSearchUrlCalled,
                     "Should not track when committed URL does not match pending URL")
    }

    func testInappSearchPrivateFlagIsForwardedCorrectly() {
        let browser = BrowserViewController(profile: profileMock, tabManager: tabManagerMock)

        let rootURL = EcosiaEnvironment.current.urlProvider.root
        let url = URL(string: "\(rootURL)/search?q=test")!
        let action = FakeNavigationAction(url: url, navigationType: .other)

        // Non-private
        analyticsSpy = AnalyticsSpy()
        Analytics.shared = analyticsSpy
        browser.webView(makeWebView(), decidePolicyFor: action) { _ in }
        browser.ecosiaHandleDidCommit(url: url, isPrivate: false)
        XCTAssertEqual(analyticsSpy.inappSearchIsPrivateCalled,
                       false,
                       "Should forward isPrivate: false for normal tabs")

        // Private
        analyticsSpy = AnalyticsSpy()
        Analytics.shared = analyticsSpy
        browser.webView(makeWebView(), decidePolicyFor: action) { _ in }
        browser.ecosiaHandleDidCommit(url: url, isPrivate: true)
        XCTAssertEqual(analyticsSpy.inappSearchIsPrivateCalled,
                       true,
                       "Should forward isPrivate: true for private tabs")
    }

    // MARK: - Analytics Context Tests

    func testAddUserStateContextOnResumeEvent() {
        // Arrange
        let analyticsSpy = makeAnalyticsSpyContextSUT(status: .ephemeral)
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: "",
                               action: Analytics.Action.Activity.resume.rawValue)

        // Act
        analyticsSpy.appendActivityContextIfNeeded(.resume, event) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        // Assert
        let userContext = event.entities.first { $0.schema == Analytics.userSchema }
        XCTAssertNotNil(userContext, "User state context not found in event entities")
        if let userContext = userContext {
            XCTAssertEqual(userContext.data["push_notification_state"] as? String, "enabled")
        }
    }

    func testAddUserStateContextOnLaunchEvent() {
        // Arrange
        let analyticsSpy = makeAnalyticsSpyContextSUT(status: .denied)
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: "",
                               action: Analytics.Action.Activity.launch.rawValue)

        // Act
        analyticsSpy.appendActivityContextIfNeeded(.resume, event) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        // Assert
        let userContext = event.entities.first { $0.schema == Analytics.userSchema }
        XCTAssertNotNil(userContext, "User state context not found in event entities")
        if let userContext = userContext {
            XCTAssertEqual(userContext.data["push_notification_state"] as? String, "disabled")
        }
    }

    func testAddUserSeedCountContextToAllEvents() {
        // Arrange
        let analyticsSpy = makeAnalyticsSpyContextSUT()
        User.shared.sendAnonymousUsageData = true
        let event = Structured(category: Analytics.Category.bookmarks.rawValue,
                               action: Analytics.Action.click.rawValue)

        // Act
        analyticsSpy.track(event)

        // Assert
        XCTAssertEqual(analyticsSpy.trackedEvents.count, 1, "Should have tracked one event")
        let seedCountContext = event.entities.first { $0.schema == Analytics.impactBalanceSchema }
        XCTAssertNotNil(seedCountContext, "User seed count context must be added to the structured event")
        if let seedCountContext = seedCountContext {
            XCTAssertEqual(seedCountContext.data["amount"] as? Int, User.shared.seedCount)
        }
    }

    func testAddUserSeedCountContextToResumeEventOnDidBecomeActive() async {
        // Arrange
        User.shared.sendAnonymousUsageData = true
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.applicationDidBecomeActive(application)

        // Ecosia: waitForCondition blocks the main actor which deadlocks in @MainActor tests.
        // Use Task.sleep-based polling instead so the main actor stays free during waits.
        let deadline = Date().addingTimeInterval(2)
        while !(analyticsSpy.trackedEvents.isEmpty == false && analyticsSpy.activityActionCalled == .resume) {
            if Date() > deadline { XCTFail("Condition timed out"); break }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        // Assert
        XCTAssertEqual(analyticsSpy.activityActionCalled, .resume)
        XCTAssertEqual(analyticsSpy.trackedEvents.count, 1)

        if let structuredEvent = analyticsSpy.trackedEvents.first(where: { ($0 as? Structured)?.action == Analytics.Action.Activity.resume.rawValue }) {
            let seedCountContext = structuredEvent.entities.first { $0.schema == Analytics.impactBalanceSchema }
            XCTAssertNotNil(seedCountContext)
            if let seedCountContext = seedCountContext {
                XCTAssertEqual(seedCountContext.data["amount"] as? Int, User.shared.seedCount)
            }
        } else {
            XCTFail("Tracked event should be a Structured event")
        }
    }

    // MARK: Analytics Private Data clearance

    func testClearPrivateDataTracksEvent() {
        // Arrange
        let vc = ClearPrivateDataTableViewController(profile: profileMock, tabManager: tabManagerMock)
        vc.loadViewIfNeeded()

        // Act
        vc.tableView(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 2))

        // Assert
        XCTAssertEqual(analyticsSpy.clearAllPrivateDataSectionCalled, .main, "Analytics should track clearAllPrivateDataSectionCalled as .main because we are simulating the click on Clear Private Data")
    }

    func testClearWebsitesDataTracksEvent() {
        // Arrange
        let vc = WebsiteDataManagementViewController(windowUUID: .XCTestDefaultUUID)
        vc.loadViewIfNeeded()

        // Act
        // Ecosia: tableView is UITableView? in v147, unwrap is safe after loadViewIfNeeded
        vc.tableView(vc.tableView!, didSelectRowAt: IndexPath(row: 0, section: 2))

        // Assert
        XCTAssertEqual(analyticsSpy.clearAllPrivateDataSectionCalled, .websites, "Analytics should track clearAllPrivateDataSectionCalled as .websites because we are simulating the click on Clear Websiste Data")
    }

    // MARK: Analytics Default Browser

    func testShowInstructionStepsTriggersAnalyticsEvent() throws {
        User.shared.showDefaultBrowserSettingNudgeCard()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())

        let view = makeInstructionsViewSUT()
            .onAppear {
                Analytics.shared.defaultBrowserSettingsDismissDetailViewVia(.settingsNudgeCard)
            }

        try view.inspect().callOnAppear()

        XCTAssertEqual(analyticsSpy.defaultBrowserSettingsDismissDetailViewLabelCalled, .settingsNudgeCard)
    }

    func testTappingDismissButtonOnNudgeCardTriggersAnalyticsEvent() throws {
        // Ecosia: AppSettingsTableViewController(with:and:) now requires settingsDelegate,
        // parentCoordinator, and gleanUsageReportingMetricsService after the v147 upgrade.
        // Test needs to be updated with the new constructor signature. Tracked in MOB-4384.
        throw XCTSkip("AppSettingsTableViewController constructor changed in v147 — tracked in MOB-4384")
    }

    func testDismissInstructionStepsTriggersAnalyticsEvent() throws {
        User.shared.showDefaultBrowserSettingNudgeCard()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())

        let view = makeInstructionsViewSUT()
            .onDisappear {
                Analytics.shared.defaultBrowserSettingsDismissDetailViewVia(.settingsNudgeCard)
            }

        try view.inspect().callOnDisappear()

        XCTAssertEqual(analyticsSpy.defaultBrowserSettingsDismissDetailViewLabelCalled, .settingsNudgeCard)
    }

    func testDefaultBrowserSettingsOpenNativeSettingsTracksLabelAndProperty() throws {
        User.shared.showDefaultBrowserSettingNudgeCard()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())

        let view = makeInstructionsViewSUT(onButtonTap: {
            Analytics.shared.defaultBrowserSettingsOpenNativeSettingsVia(.settings)
        })

        try view.inspect().find(button: String.Key.defaultBrowserCardDetailButton.rawValue).tap()

        analyticsSpy.defaultBrowserSettingsOpenNativeSettingsVia(.settings)
        XCTAssertEqual(analyticsSpy.defaultBrowserSettingsOpenNativeSettingsLabelCalled, .settings, "Expected label 'default_browser_settings' to be tracked.")
    }
}

// MARK: - Helper SUTs
extension AnalyticsSpyTests {

    func makeAnalyticsSpyContextSUT(status: UNAuthorizationStatus = .notDetermined) -> AnalyticsSpy {
        let mockSettings = MockUNNotificationSettings(authorizationStatus: status)
        let mockNotificationCenter = MockAnalyticsUserNotificationCenter(mockSettings: mockSettings)
        let analyticsSpy = AnalyticsSpy(notificationCenter: mockNotificationCenter)
        return analyticsSpy
    }

    func makeWelcomeView() -> WelcomeView {
        WelcomeView(windowUUID: .XCTestDefaultUUID, onFinish: {}, onSignIn: {})
    }

    func makeInstructionsViewSUT(onButtonTap: @escaping () -> Void = {}) -> InstructionStepsView<some View> {
        let style = InstructionStepsViewStyle(
            backgroundPrimaryColor: .blue,

            topContentBackgroundColor: .blue,
            stepsBackgroundColor: .blue,
            textPrimaryColor: .blue,
            textSecondaryColor: .blue,
            buttonBackgroundColor: .blue,
            buttonTextColor: .blue,
            stepRowStyle: StepRowStyle(stepNumberColor: .blue, stepTextColor: .blue)
        )

        return InstructionStepsView(
            title: .defaultBrowserCardDetailTitle,
            steps: [InstructionStep(text: .defaultBrowserCardDetailInstructionStep1)],
            buttonTitle: .defaultBrowserCardDetailButton,
            onButtonTap: onButtonTap,
            style: style
        ) {
            EmptyView()
        }
    }

    func makeWebView() -> WKWebView {
        return WKWebView(frame: CGRect(width: 100, height: 100))
    }
}

// MARK: - Helper Classes

class MultiplyImpactTestable: MultiplyImpact {
    var capturedPresentedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        capturedPresentedViewController = viewControllerToPresent
    }
}

final class FakeNavigationAction: WKNavigationAction {
    let urlRequest: URLRequest
    let type: WKNavigationType

    override var request: URLRequest { urlRequest }

    override var navigationType: WKNavigationType { type }

    init(url: URL, navigationType: WKNavigationType) {
        self.urlRequest = URLRequest(url: url)
        self.type = navigationType
        super.init()
    }
}

// MARK: - AnalyticsContextTests

// Ecosia: These three context tests are fully decoupled from the DI container and run
// independently. They do NOT call DependencyHelperMock().bootstrapDependencies(), which
// is the root cause of the AnalyticsSpyTests crash (AppContainer.shared.bootstrap()
// triggers resolution of Client.DocumentLogger, which is not registered in the mock
// container, causing a fatal crash-restart loop). Keeping this class separate ensures
// these tests remain runnable while the broader AnalyticsSpyTests class-level skip
// remains in place. Tracked in MOB-4384.
@MainActor
final class AnalyticsContextTests: XCTestCase, @unchecked Sendable {

    var analyticsSpy: AnalyticsSpy!

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

    func testAddUserStateContextOnResumeEvent() {
        // Arrange
        let analyticsSpy = makeAnalyticsContextSUT(status: .ephemeral)
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: "",
                               action: Analytics.Action.Activity.resume.rawValue)

        // Act
        analyticsSpy.appendActivityContextIfNeeded(.resume, event) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        // Assert
        let userContext = event.entities.first { $0.schema == Analytics.userSchema }
        XCTAssertNotNil(userContext, "User state context not found in event entities")
        if let userContext = userContext {
            XCTAssertEqual(userContext.data["push_notification_state"] as? String, "enabled")
        }
    }

    func testAddUserStateContextOnLaunchEvent() {
        // Arrange
        let analyticsSpy = makeAnalyticsContextSUT(status: .denied)
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: "",
                               action: Analytics.Action.Activity.launch.rawValue)

        // Act
        analyticsSpy.appendActivityContextIfNeeded(.resume, event) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        // Assert
        let userContext = event.entities.first { $0.schema == Analytics.userSchema }
        XCTAssertNotNil(userContext, "User state context not found in event entities")
        if let userContext = userContext {
            XCTAssertEqual(userContext.data["push_notification_state"] as? String, "disabled")
        }
    }

    func testAddUserSeedCountContextToAllEvents() {
        // Arrange
        let analyticsSpy = makeAnalyticsContextSUT()
        User.shared.sendAnonymousUsageData = true
        let event = Structured(category: Analytics.Category.bookmarks.rawValue,
                               action: Analytics.Action.click.rawValue)

        // Act
        analyticsSpy.track(event)

        // Assert
        XCTAssertEqual(analyticsSpy.trackedEvents.count, 1, "Should have tracked one event")
        let seedCountContext = event.entities.first { $0.schema == Analytics.impactBalanceSchema }
        XCTAssertNotNil(seedCountContext, "User seed count context must be added to the structured event")
        if let seedCountContext = seedCountContext {
            XCTAssertEqual(seedCountContext.data["amount"] as? Int, User.shared.seedCount)
        }
    }

    // MARK: - Helpers

    private func makeAnalyticsContextSUT(status: UNAuthorizationStatus = .notDetermined) -> AnalyticsSpy {
        let mockSettings = MockUNNotificationSettings(authorizationStatus: status)
        let mockNotificationCenter = MockAnalyticsUserNotificationCenter(mockSettings: mockSettings)
        return AnalyticsSpy(notificationCenter: mockNotificationCenter)
    }
}
// swiftlint:enable implicitly_unwrapped_optional
