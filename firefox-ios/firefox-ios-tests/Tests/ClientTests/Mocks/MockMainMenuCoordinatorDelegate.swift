// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SummarizeKit
@testable import Client

class MockMainMenuCoordinatorDelegate: MainMenuCoordinatorDelegate {
    private(set) var editBookmarkForCurrentTabCalled = 0
    private(set) var showLibraryPanelCalled = 0
    private(set) var showSettingsCalled = 0
    private(set) var showFindInPageCalled = 0
    private(set) var showSignInViewCalled = 0
    private(set) var updateZoomPageBarVisibilityCalled = 0
    private(set) var presentSavePDFControllerCalled = 0
    private(set) var presentSiteProtectionsCalled = 0
    private(set) var presentReportBrokenSiteCalled = 0
    private(set) var presentReportBrokenSiteURL: URL?
    private(set) var presentAdBlockerSettingsCalled = 0
    private(set) var showPrintSheetCalled = 0
    private(set) var showShareSheetForCurrentlySelectedTabCalled = 0
    private(set) var showSummarizePanelCalled = 0
    private(set) var showSummarizePanelTrigger: SummarizerTrigger?
    // Ecosia: Help and Report Issue actions for the compact menu
    private(set) var showHelpCalled = 0
    private(set) var showFeedbackCalled = 0
    private(set) var showFeedbackWindowUUID: WindowUUID?

    func editBookmarkForCurrentTab() {
        editBookmarkForCurrentTabCalled += 1
    }

    func showLibraryPanel(_ panel: Route.HomepanelSection) {
        showLibraryPanelCalled += 1
    }

    func showSettings(at destination: Route.SettingsSection) {
        showSettingsCalled += 1
    }

    func showFindInPage() {
        showFindInPageCalled += 1
    }

    func showSignInView(fxaParameters: FxASignInViewParameters?) {
        showSignInViewCalled += 1
    }

    func updateZoomPageBarVisibility() {
        updateZoomPageBarVisibilityCalled += 1
    }

    func presentSavePDFController() {
        presentSavePDFControllerCalled += 1
    }

    func presentSiteProtections() {
        presentSiteProtectionsCalled += 1
    }

    func presentReportBrokenSite(url: URL?) {
        presentReportBrokenSiteCalled += 1
        presentReportBrokenSiteURL = url
    }

    func presentAdBlockerSettings() {
        presentAdBlockerSettingsCalled += 1
    }

    func showPrintSheet() {
        showPrintSheetCalled += 1
    }

    func showShareSheetForCurrentlySelectedTab() {
        showShareSheetForCurrentlySelectedTabCalled += 1
    }

    func showSummarizePanel(_ trigger: SummarizerTrigger, config: SummarizerConfig?) {
        showSummarizePanelCalled += 1
        showSummarizePanelTrigger = trigger
    }

    // Ecosia: Help and Report Issue actions for the compact menu
    func showHelp() {
        showHelpCalled += 1
    }

    func showFeedback(windowUUID: WindowUUID) {
        showFeedbackCalled += 1
        showFeedbackWindowUUID = windowUUID
    }
}
