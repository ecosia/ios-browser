// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import MozillaAppServices
import WebKit
import XCTest

@testable import Client

@MainActor
final class BrowserCoordinatorTests: XCTestCase, FeatureFlaggable {
    private var mockRouter: MockRouter!
    private var profile: MockProfile!
    private var overlayModeManager: MockOverlayModeManager!
    private var screenshotService: ScreenshotService!
    private var tabManager: MockTabManager!
    private var applicationHelper: MockApplicationHelper!
    private var glean: MockGleanWrapper!
    private var scrollDelegate: MockStatusBarScrollDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        let mockTabManager = MockTabManager()
        self.tabManager = mockTabManager
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: mockTabManager)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.profile = MockProfile()
        self.overlayModeManager = MockOverlayModeManager()
        self.screenshotService = ScreenshotService()
        self.applicationHelper = MockApplicationHelper()
        self.glean = MockGleanWrapper()
        self.scrollDelegate = MockStatusBarScrollDelegate()
    }

    override func tearDown() {
        self.mockRouter = nil
        self.profile = nil
        self.overlayModeManager = nil
        self.screenshotService = nil
        self.tabManager = nil
        self.applicationHelper = nil
        self.glean = nil
        self.scrollDelegate = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertNotNil(subject.browserViewController)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
    }

    func testWithoutLaunchType_startsBrowserOnly() {
        let subject = createSubject()
        subject.start(with: nil)

        // Ecosia: start(with:) installs the browser as the router's root view controller (setRootViewController),
        // not via push.
        XCTAssertNotNil(mockRouter.rootViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testWithLaunchType_startsLaunchCoordinator() {
        let subject = createSubject()
        subject.start(with: .defaultBrowser)

        // Ecosia: start(with:) installs the browser as the router's root view controller (setRootViewController),
        // not via push.
        XCTAssertNotNil(mockRouter.rootViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    func testChildLaunchCoordinatorIsDone_deallocatesAndDismiss() throws {
        let subject = createSubject()
        subject.start(with: .defaultBrowser)

        let childLaunchCoordinator = try XCTUnwrap(subject.childCoordinators[0] as? LaunchCoordinator)
        subject.didFinishLaunch(from: childLaunchCoordinator)

        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    // MARK: - Show homepage

    /* Ecosia: showLegacyHomepage and LegacyHomepageViewController removed in v147
    func testShowHomepage_addsOneHomepageOnly() { ... }
    func testShowHomepage_reuseExistingHomepage() { ... }
    */

    // MARK: - Show new homepage

    func testShowNewHomepage_setsProperViewController() {
        let subject = createSubject()
        subject.showHomepage(overlayManager: overlayModeManager,
                             isZeroSearch: false,
                             statusBarScrollDelegate: scrollDelegate,
                             toastContainer: UIView())

        XCTAssertNotNil(subject.homepageViewController)
        XCTAssertNil(subject.webviewController)
        // Ecosia: privateViewController removed in v147
    }

    func testShowNewHomepage_hasSameInstance() {
        let subject = createSubject()
        subject.showHomepage(overlayManager: overlayModeManager,
                             isZeroSearch: false,
                             statusBarScrollDelegate: scrollDelegate,
                             toastContainer: UIView())
        let firstHomepage = subject.homepageViewController
        XCTAssertNotNil(subject.homepageViewController)

        subject.showHomepage(overlayManager: overlayModeManager,
                             isZeroSearch: false,
                             statusBarScrollDelegate: scrollDelegate,
                             toastContainer: UIView())
        let secondHomepage = subject.homepageViewController
        XCTAssertEqual(firstHomepage, secondHomepage)
    }

    // MARK: - Show webview

    func testShowWebview_embedNewWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.show(webView: webview)

        // Ecosia: legacyHomepageViewController removed in v147
        XCTAssertNotNil(subject.webviewController)
        XCTAssertEqual(mbvc.embedContentCalled, 1)
        XCTAssertEqual(mbvc.saveEmbeddedContent?.contentType, .webview)
    }

    func testShowWebview_reuseExistingWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.show(webView: webview)
        let firstWebview = subject.webviewController
        XCTAssertNotNil(firstWebview)

        subject.show(webView: webview)
        let secondWebview = subject.webviewController

        XCTAssertEqual(firstWebview, secondWebview)
        XCTAssertEqual(mbvc.embedContentCalled, 1)
        XCTAssertEqual(mbvc.frontEmbeddedContentCalled, 1)
        XCTAssertEqual(mbvc.saveEmbeddedContent?.contentType, .webview)
    }

    func testShowWebview_setsScreenshotService() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.show(webView: webview)

        XCTAssertNotNil(screenshotService.screenshotableView)
    }

    // MARK: - BrowserNavigationHandler

    func testShowSettings() throws {
        let subject = createSubject()
        subject.show(settings: .general)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? ThemedNavigationController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is AppSettingsTableViewController)
    }

    func testShowLibrary() throws {
        let subject = createSubject()
        subject.show(homepanelSection: .bookmarks)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LibraryCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is LibraryViewController)
    }

    func testShowEnhancedTrackingProtection() throws {
        let subject = createSubject()
        subject.showEnhancedTrackingProtection(sourceView: UIView())

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? EnhancedTrackingProtectionCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)

        if featureFlags.isFeatureEnabled(.trackingProtectionRefactor, checking: .buildOnly) {
            XCTAssertTrue(mockRouter.presentedViewController is UINavigationController)
        } else {
            XCTAssertTrue(mockRouter.presentedViewController is EnhancedTrackingProtectionMenuVC)
        }
    }

    func testShowShareSheet_addsShareSheetCoordinator() {
        let subject = createSubject()

        subject.showShareSheet(
            shareType: .site(url: URL(string: "https://www.google.com")!),
            shareMessage: nil,
            sourceView: UIView(),
            sourceRect: nil,
            toastContainer: UIView(),
            popoverArrowDirection: .any
        )

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is ShareSheetCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is UIActivityViewController)
    }

    func testShowCreditCardAutofill_addsCredentialAutofillCoordinator() {
        let subject = createSubject()

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .save,
            frame: nil,
            alertContainer: UIView()
        )

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is CredentialAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    @MainActor
    func testShowSavedLoginAutofill_addsCredentialAutofillCoordinator() {
        let subject = createSubject()
        let testURL = URL(string: "https://example.com")!
        let currentRequestId = "testRequestID"
        let field = FocusFieldType.password
        subject.showSavedLoginAutofill(tabURL: testURL, currentRequestId: currentRequestId, field: field)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is CredentialAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    func testShowRequiredPassCode_addsCredentialAutofillCoordinator() {
        let subject = createSubject()

        subject.showRequiredPassCode()

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is CredentialAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DevicePasscodeRequiredViewController)
    }

    func testShowQRCode_addsQRCodeCoordinator() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()
        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is QRCodeCoordinator)
    }

    func testShowQRCode_presentsQRCodeNavigationController() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()
        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is QRCodeNavigationController)
    }

    func testShowBackForwardList_presentsBackForwardListViewController() {
        let mockTab = Tab(profile: profile, windowUUID: windowUUID)
        mockTab.url = URL(string: "https://www.google.com")
        mockTab.createWebview(configuration: .init())
        tabManager.selectedTab = mockTab

        let subject = createSubject()
        subject.showBackForwardList()

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BackForwardListViewController)
    }

    func testShowTabTray() throws {
        let subject = createSubject()
        subject.showTabTray(selectedPanel: .tabs)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? TabTrayCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is TabTrayViewController)
    }

    func testDismissTabTray_removesChild() throws {
        let subject = createSubject()
        subject.showTabTray(selectedPanel: .tabs)
        guard let tabTrayCoordinator = subject.childCoordinators[0] as? TabTrayCoordinator else {
            XCTFail("Tab tray coordinator was expected to be resolved")
            return
        }

        subject.didDismissTabTray(from: tabTrayCoordinator)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testShowPasswordGenerator_presentsPasswordGeneratorBottomSheet() {
        let subject = createSubject()
        let mockTab = Tab(profile: profile, windowUUID: windowUUID)
        let URL = URL(string: "https://foo.com")!
        let webView = WKWebViewMock(URL)
        let frame = WKFrameInfoMock(webView: webView, frameURL: URL, isMainFrame: true)

        subject.showPasswordGenerator(tab: mockTab, frame: frame)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    // MARK: - ParentCoordinatorDelegate

    func testRemoveChildCoordinator_whenDidFinishCalled() {
        let subject = createSubject()
        let childCoordinator = ShareSheetCoordinator(
            alertContainer: UIView(),
            router: mockRouter,
            profile: profile,
            parentCoordinator: subject,
            tabManager: tabManager)

        subject.add(child: childCoordinator)
        subject.didFinish(from: childCoordinator)

        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    // MARK: - Search route

    func testHandleSearchQuery_returnsTrue() {
        let query = "test query"
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .searchQuery(query: query, isPrivate: false))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.handleQueryCalled)
        XCTAssertEqual(mbvc.handleQuery, query)
        XCTAssertEqual(mbvc.handleQueryCount, 1)
    }

    func testHandleSearch_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .search(url: URL(string: "https://example.com")!,
                                                                    isPrivate: false,
                                                                    options: nil))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleSearchWithNormalMode_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .search(url: URL(string: "https://example.com")!,
                                                                    isPrivate: false))

        XCTAssertTrue(result)
        XCTAssertFalse(mbvc.switchToPrivacyModeCalled)
        XCTAssertFalse(mbvc.switchToPrivacyModeIsPrivate)
        XCTAssertTrue(mbvc.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleSearchWithNilURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .search(url: nil, isPrivate: false))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.openBlankNewTabCalled)
        XCTAssertFalse(mbvc.openBlankNewTabIsPrivate)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
    }

    func testHandleSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(
            subject,
            route: .searchURL(
                url: URL(string: "https://example.com")!,
                tabId: "1234"
            )
        )

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleNilSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .searchURL(url: nil, tabId: "1234"))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.openBlankNewTabCalled)
        XCTAssertFalse(mbvc.openBlankNewTabIsPrivate)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
    }

    // MARK: - Homepanel route

    func testHandleHomepanelBookmarks_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .bookmarks))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .bookmarks)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelHistory_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .history))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .history)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelReadingList_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .readingList))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .readingList)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelDownloads_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .downloads))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .downloads)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelTopSites_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .topSites))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.openURLInNewTabCount, 1)
        XCTAssertEqual(mbvc.openURLInNewTabURL, HomePanelType.topSites.internalUrl)
        XCTAssertEqual(mbvc.openURLInNewTabIsPrivate, false)
    }

    func testHandleNewPrivateTab_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .search(url: nil, isPrivate: true))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
        XCTAssertFalse(mbvc.openBlankNewTabFocusLocationField)
        XCTAssertEqual(mbvc.openBlankNewTabIsPrivate, true)
    }

    func testHandleHomepanelNewTab_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .search(url: nil, isPrivate: false))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
        XCTAssertFalse(mbvc.openBlankNewTabFocusLocationField)
        XCTAssertEqual(mbvc.openBlankNewTabIsPrivate, false)
    }

    // MARK: - Default browser route

    func testDefaultBrowser_systemSettings_handlesRoute() {
        let route = Route.defaultBrowser(section: .systemSettings)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: route)

        XCTAssertTrue(result)
        XCTAssertEqual(applicationHelper.openSettingsCalled, 1)
    }

    func testDefaultBrowser_tutorial_handlesRoute() {
        let route = Route.defaultBrowser(section: .tutorial)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: route)

        XCTAssertTrue(result)
        XCTAssertNotNil(mockRouter.presentedViewController as? DefaultBrowserOnboardingViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    // MARK: - Glean route

    func testGleanRoute_handlesRoute() {
        let expectedURL = URL(string: "www.example.com")!
        let route = Route.glean(url: expectedURL)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: route)

        XCTAssertTrue(result)
        XCTAssertEqual(glean.handleDeeplinkUrlCalled, 1)
        XCTAssertEqual(glean.savedHandleDeeplinkUrl, expectedURL)
    }

    // MARK: - Settings route

    func testGeneralSettingsRoute_showsGeneralSettingsPage() throws {
        let route = Route.settings(section: .general)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: route)

        XCTAssertTrue(result)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? ThemedNavigationController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is AppSettingsTableViewController)
    }

    func testSettingsRoute_addSettingsCoordinator() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .settings(section: .general))

        XCTAssertTrue(result)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
    }

    func testSettingsRoute_addSettingsCoordinatorOnlyOnce() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result1 = testCanHandleAndHandle(subject, route: .settings(section: .general))
        let result2 = testCanHandleAndHandle(subject, route: .settings(section: .general))

        XCTAssertTrue(result1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
        XCTAssertFalse(result2)
    }

    func testPresentedCompletion_callsDidFinishSettings_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .settings(section: .general))
        mockRouter.savedCompletion?()

        XCTAssertTrue(result)
    }

    func testSettingsCoordinatorDelegate_openURLinNewTab() {
        let expectedURL = URL(string: "www.mozilla.com")!
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        subject.openURLinNewTab(expectedURL)

        XCTAssertEqual(mbvc.openURLInNewTabCount, 1)
        XCTAssertEqual(mbvc.openURLInNewTabURL, expectedURL)
    }

    func testSettingsCoordinatorDelegate_didFinishSettings_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .settings(section: .general))
        let settingsCoordinator = subject.childCoordinators[0] as! SettingsCoordinator
        subject.didFinishSettings(from: settingsCoordinator)

        XCTAssertTrue(result)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testETPCoordinatorDelegate_settingsOpenPage() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        subject.settingsOpenPage(settings: .contentBlocker)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
    }

    func testEnhancedTrackingProtectionCoordinatorDelegate_didFinishETP_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        subject.showEnhancedTrackingProtection(sourceView: UIView())
        let etpCoordinator = subject.childCoordinators[0] as! EnhancedTrackingProtectionCoordinator
        subject.didFinishEnhancedTrackingProtection(from: etpCoordinator)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Sign in route

    func testHandleFxaSignIn_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let params = FxALaunchParams(entrypoint: .fxaDeepLinkNavigation,
                                     query: ["signin": "coolcodes", "user": "foo", "email": "bar"])
        let result = testCanHandleAndHandle(subject, route: .fxaSignIn(params: params))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.presentSignInCount, 1)
        XCTAssertEqual(mbvc.presentSignInFlowType, .emailLoginFlow)
        XCTAssertEqual(mbvc.presentSignInFxaOptions, params)
        XCTAssertEqual(mbvc.presentSignInReferringPage, ReferringPage.none)
    }

    // MARK: - App action route

    // Ecosia: Route.AppAction.showQRCode removed in v147
    /*
    func testHandleHandleQRCode_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .action(action: .showQRCode))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.qrCodeCount, 1)
    }
    */

    func testHandleClosePrivateTabs_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .action(action: .closePrivateTabs))

        // Then
        XCTAssertTrue(result)
        let windowManager = (AppContainer.shared.resolve() as WindowManager) as! MockWindowManager
        XCTAssertEqual(windowManager.closePrivateTabsMultiActionCalled, 1)
    }

    /* Ecosia: Disable Onboarding dependant tests since LaunchCoordinator.presentIntroOnboarding is temporarily disabled
    func testHandleShowOnboarding_returnsTrueAndShowsOnboarding() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .action(action: .showIntroOnboarding))

        XCTAssertTrue(result)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }
    */

    // MARK: - Saved route

    func testSavesRoute_whenLaunchFinished() throws {
        let subject = createSubject()
        subject.findAndHandle(route: .defaultBrowser(section: .tutorial))
        subject.start(with: nil)

        subject.didFinishLaunch(
            from: LaunchCoordinator(
                router: mockRouter,
                windowUUID: .XCTestDefaultUUID
            )
        )

        XCTAssertNotNil(subject.savedRoute)
    }

    func testSavedRouteCalled_whenBrowserHasLoaded() throws {
        let subject = createSubject()
        subject.findAndHandle(route: .defaultBrowser(section: .tutorial))
        subject.start(with: nil)

        subject.browserHasLoaded()

        XCTAssertNotNil(mockRouter.presentedViewController as? DefaultBrowserOnboardingViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    func testSavesRoute_whenBrowserNotLoaded() {
        let subject = createSubject()

        let coordinator = subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        XCTAssertNotNil(subject.savedRoute)
        XCTAssertNil(coordinator)
    }

    func testSavesRoute_whenTabManagerIsRestoring() {
        tabManager.isRestoringTabs = true
        let subject = createSubject()
        subject.browserHasLoaded()

        let coordinator = subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        XCTAssertNotNil(subject.savedRoute)
        XCTAssertNil(coordinator)
    }

    func testSavedRouteCalled_whenRestoredTabsIsCalled() {
        tabManager.isRestoringTabs = true
        let subject = createSubject()
        subject.browserHasLoaded()
        subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        tabManager.isRestoringTabs = false
        subject.tabManagerDidRestoreTabs(tabManager)

        XCTAssertNotNil(mockRouter.presentedViewController as? DefaultBrowserOnboardingViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    // MARK: - Library

    func testOneLibraryCoordinatorInstanceExists_whenPresetingMultipleLibraryTabs() {
        let subject = createSubject()

        // When the coordinator is created, there should no instance of LibraryCoordinator
        XCTAssertFalse(subject.childCoordinators.contains { $0 is LibraryCoordinator })

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        // Checking to see if there's one library coordinator instance presented
        XCTAssertEqual(subject.childCoordinators.filter { $0 is LibraryCoordinator }.count, 1)

        // We try to show the library again on downloads tab (notice for now the Done
        // button is not connected and will not remove the coordinator). Showing the
        // library again should use the existing instance of the LibraryCoordinator
        subject.show(homepanelSection: .downloads)

        // Checking to see if there's only one library coordinator instance presented
        XCTAssertEqual(subject.childCoordinators.filter { $0 is LibraryCoordinator }.count, 1)
    }

    func testTappingOpenUrl_CallsTheDidSelectUrlOnBrowserViewController() throws {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        let coordinator = try XCTUnwrap(
            subject.childCoordinators.first { $0 is LibraryCoordinator } as? LibraryCoordinator)
        let url = URL(string: "http://google.com")!
        coordinator.libraryPanel(didSelectURL: url, visitType: .bookmark)

        XCTAssertTrue(mbvc.didSelectURLCalled)
        XCTAssertEqual(mbvc.lastOpenedURL, url)
        XCTAssertEqual(mbvc.lastVisitType, .bookmark)
    }

    func testTappingOpenUrlInNewTab_CallsTheDidSelectUrlInNewTapOnBrowserViewController() throws {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        let coordinator = try XCTUnwrap(
            subject.childCoordinators.first { $0 is LibraryCoordinator } as? LibraryCoordinator)
        let url = URL(string: "http://google.com")!
        coordinator.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: true)

        XCTAssertTrue(mbvc.didRequestToOpenInNewTabCalled)
        XCTAssertEqual(mbvc.lastOpenedURL, url)
        XCTAssertTrue(mbvc.isPrivate)
    }

    /* Ecosia: openRecentlyClosedSiteInSameTab removed in v147
    func testOpenRecentlyClosedTabInSameTab_callsReletedMethodInBrowserViewController() { ... }
    */

    func testOpenRecentlyClosedSiteInNewTab_addsOneTabToTabManager() {
        let subject = createSubject()

        subject.openRecentlyClosedSiteInNewTab(URL(string: "https://www.google.com")!, isPrivate: false)

        XCTAssertEqual(tabManager.lastSelectedTabs.count, 1)
    }

    /* Ecosia: Fakespot removed in v147 — FakespotCoordinator, FakespotViewController,
       showFakespotFlowAsModal/AsSidebar, dismissFakespotModal/Sidebar, updateFakespotSidebar all removed
    func testFakespotCoordinatorDelegate_didDidDismiss_removesChild() { ... }
    func testTappingShopping_startsFakespotCoordinatorAsModal() { ... }
    func testTappingShopping_startsFakespotCoordinatorAsSidebar() { ... }
    func testTappingShopping_dismissFakespotModal() { ... }
    func testTappingShopping_dismissFakespotModal_noCoordinator() { ... }
    func testTappingShopping_dismissFakespotSidebar() { ... }
    func testTappingShopping_dismissFakespotSidebar_noCoordinator() { ... }
    func testChangeShoppingURL_updatesSidebar() { ... }
    */

    func testShowAddressAutofill_addsAddressAutofillCoordinator() {
        // Arrange
        let subject = createSubject()

        // Act
        subject.showAddressAutofill(frame: nil)
        // Assert
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is AddressAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    // MARK: - Menu
    func testShowMainMenu_addsMainMenuCoordinator() {
        let subject = createSubject()
        XCTAssertTrue(subject.childCoordinators.isEmpty)

        subject.showMainMenu()

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is MainMenuCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DismissableNavigationViewController)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is MainMenuViewController)
    }

    func testMainMenuCoordinatorDelegate_didDidDismiss_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        subject.showMainMenu()
        guard let menuCoordinator = subject.childCoordinators[0] as? MainMenuCoordinator else {
            XCTFail("Main menu coordinator was expected to be resolved")
            return
        }

        menuCoordinator.dismissMenuModal(animated: false)

        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testMainMenuCoordinatorDelegate_navigatesToSettings() {
        let subject = createSubject()
        subject.browserHasLoaded()

        subject.showMainMenu()
        guard let menuCoordinator = subject.childCoordinators[0] as? MainMenuCoordinator else {
            XCTFail("Main menu coordinator was expected to be resolved")
            return
        }

        // Ecosia: .customizeHomepage removed in v147, use .settings instead
        menuCoordinator.navigateTo(MenuNavigationDestination(.settings), animated: false)

        XCTAssertTrue(subject.childCoordinators[0] is SettingsCoordinator)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is AppSettingsTableViewController)
    }

    // MARK: - Search Engine Selection
    func testShowSearchEngineSelection_addsSearchEngineSelectionCoordinator() {
        let subject = createSubject()
        XCTAssertTrue(subject.childCoordinators.isEmpty)

        subject.showSearchEngineSelection(forSourceView: UIView())

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is SearchEngineSelectionCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DismissableNavigationViewController)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is SearchEngineSelectionViewController)
    }

    func testSearchEngineSelectionCoordinatorDelegate_navigatesToSettings() {
        let subject = createSubject()
        subject.browserHasLoaded()

        subject.showSearchEngineSelection(forSourceView: UIView())
        guard let searchEngineSelectionCoordinator = subject.childCoordinators[0] as? SearchEngineSelectionCoordinator else {
            XCTFail("Search engine selection coordinator was expected to be resolved")
            return
        }

        searchEngineSelectionCoordinator.navigateToSearchSettings(animated: false)

        XCTAssertTrue(subject.childCoordinators[0] is SettingsCoordinator)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is AppSettingsTableViewController)
    }

    // MARK: - Microsurvey
    func testShowMicrosurvey_addsMicrosurveyCoordinator() {
        let subject = createSubject()

        subject.showMicrosurvey(model: MicrosurveyMock.model)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is MicrosurveyCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DismissableNavigationViewController)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is MicrosurveyViewController)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> BrowserCoordinator {
        let subject = BrowserCoordinator(router: mockRouter,
                                         screenshotService: screenshotService,
                                         tabManager: tabManager,
                                         profile: profile,
                                         glean: glean,
                                         applicationHelper: applicationHelper)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func testCanHandleAndHandle(_ subject: Coordinator, route: Route) -> Bool {
        let result = subject.canHandle(route: route)
        subject.handle(route: route)
        return result
    }
}
