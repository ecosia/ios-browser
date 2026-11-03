// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import XCTest
@testable import Client
@testable import Ecosia

/// AI-free searching takes the place of Firefox's AI controls hub: turning it on switches page
/// summaries and translations off through Firefox's own settings, turning it off switches them
/// back on, and the user can change either afterwards (upgrade ticket 09, MOB-5035).
@MainActor
final class AIFreeSearchingBrowserAITests: XCTestCase, StoreTestUtility {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockStore: MockStoreForMiddleware<AppState>!
    private let profile = MockProfile()
    private var windows: [AIFreeSearchingBrowserAI.WindowObserver] = []

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
        setupStore()
        User.shared.aiFreeSearching = nil
    }

    override func tearDown() async throws {
        windows.removeAll()
        User.shared.aiFreeSearching = nil
        // Let the asynchronous `searchSettingsChanged` posts land here, not in the next suite.
        try await Task.sleep(nanoseconds: 50_000_000)
        resetStore()
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Turning AI-free searching on and off

    func testTurningAIFreeOnSwitchesSummariesOff() {
        apply(aiFreeSearching: true)

        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature), false)
        XCTAssertFalse(makeSummarizerUtils().isSummarizeFeatureToggledOn)
    }

    func testTurningAIFreeOnSwitchesTranslationsOffThroughFirefoxsSettings() {
        apply(aiFreeSearching: true)

        XCTAssertEqual(translationSettingChanges, [false])
    }

    func testTurningAIFreeOffSwitchesBothBackOn() {
        apply(aiFreeSearching: true)
        mockStore.dispatchedActions.removeAll()

        apply(aiFreeSearching: false)

        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature), true)
        XCTAssertTrue(makeSummarizerUtils().isSummarizeFeatureToggledOn)
        XCTAssertEqual(translationSettingChanges, [true])
    }

    func testTurningAIFreeOnOrOffRefreshesTheSummarizeButton() {
        apply(aiFreeSearching: true)

        XCTAssertTrue(mockStore.dispatchedActions.contains {
            $0.actionType as? ToolbarActionType == .didSummarizeSettingsChange
        })
    }

    // MARK: - Changes made anywhere

    /// Settings and the `ECNOAI` cookie both go through `setEnabled`, and every browser window
    /// switches its own page summaries and translations.
    func testTurningAIFreeOnAnywhereSwitchesBothOffInEveryWindow() {
        let windowUUIDs = [WindowUUID(), WindowUUID()]
        windowUUIDs.forEach(observeWindow)

        AIFreeSearchingSelection.setEnabled(true)

        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature), false)
        XCTAssertEqual(translationSettingChanges, [false, false])
        let summarizeRefreshes = mockStore.dispatchedActions.filter {
            $0.actionType as? ToolbarActionType == .didSummarizeSettingsChange
        }
        XCTAssertEqual(Set(summarizeRefreshes.map(\.windowUUID)), Set(windowUUIDs))
    }

    func testTurningAIFreeOffAnywhereSwitchesBothBackOn() {
        observeWindow(.XCTestDefaultUUID)
        AIFreeSearchingSelection.setEnabled(true)
        mockStore.dispatchedActions.removeAll()

        AIFreeSearchingSelection.setEnabled(false)

        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature), true)
        XCTAssertEqual(translationSettingChanges, [true])
    }

    func testSettingTheSameValueAgainLeavesTheUsersChoiceAlone() {
        observeWindow(.XCTestDefaultUUID)
        AIFreeSearchingSelection.setEnabled(true)
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)

        AIFreeSearchingSelection.setEnabled(true)

        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature), true)
    }

    // MARK: - Users who had AI-free searching on before

    func testExistingAIFreeUsersStartWithSummariesAndTranslationsOff() {
        User.shared.aiFreeSearching = true

        AIFreeSearchingBrowserAI.switchOffForExistingAIFreeUsers(prefs: profile.prefs)

        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature), false)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature), false)
    }

    func testExistingAIFreeUsersKeepWhatTheyChose() {
        User.shared.aiFreeSearching = true
        profile.prefs.setBool(true, forKey: PrefsKeys.Settings.translationsFeature)

        AIFreeSearchingBrowserAI.switchOffForExistingAIFreeUsers(prefs: profile.prefs)

        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature), true)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature), false)
    }

    func testUsersWithoutAIFreeAreLeftAlone() {
        for value in [nil, false] {
            User.shared.aiFreeSearching = value

            AIFreeSearchingBrowserAI.switchOffForExistingAIFreeUsers(prefs: profile.prefs)

            XCTAssertNil(profile.prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature))
            XCTAssertNil(profile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature))
        }
    }

    // MARK: - Helpers

    private func apply(aiFreeSearching: Bool) {
        AIFreeSearchingBrowserAI.apply(aiFreeSearching: aiFreeSearching,
                                       prefs: profile.prefs,
                                       windowUUID: .XCTestDefaultUUID)
    }

    /// The values sent to Firefox's translation settings, which store the setting, refresh the
    /// toolbar and delete the downloaded models when switching off.
    private var translationSettingChanges: [Bool?] {
        mockStore.dispatchedActions.compactMap { action in
            guard let action = action as? TranslationSettingsViewAction,
                  action.actionType as? TranslationSettingsViewActionType == .toggleTranslationsEnabled
            else { return nil }
            return action.newSettingValue
        }
    }

    /// A browser window, which holds an observer once its view has loaded.
    private func observeWindow(_ windowUUID: WindowUUID) {
        windows.append(.init(prefs: profile.prefs, windowUUID: windowUUID))
    }

    /// A device that can summarize on-device, in English.
    private func makeSummarizerUtils() -> DefaultSummarizerNimbusUtils {
        .make(profile: profile, appleIntelligenceAvailable: true)
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
