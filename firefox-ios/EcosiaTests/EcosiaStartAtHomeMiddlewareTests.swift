// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Redux
import Shared
import XCTest

final class EcosiaStartAtHomeMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockProfile: MockProfile!
    private var mockTabManager: MockTabManager!
    private var mockWindowManager: MockWindowManager!
    private var mockStore: MockStoreForMiddleware<AppState>!
    private var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        mockTabManager.tabRestoreHasFinished = true
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: mockWindowManager)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        setupStore()
        appState = setupAppState()
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockWindowManager = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    @MainActor
    func test_didBrowserBecomeActiveAction_alwaysReturnsFalse_withAfterFourHoursSetting() throws {
        mockProfile.prefs.setString(StartAtHome.afterFourHours.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
        let subject = createSubject(with: mockProfile)
        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeActionType.didBrowserBecomeActive
        )

        let expectation = XCTestExpectation(description: "Start At Home action should be dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.startAtHomeProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? StartAtHomeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? StartAtHomeMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted)
        XCTAssertEqual(actionCalled.shouldStartAtHome, false)
    }

    @MainActor
    func test_didBrowserBecomeActiveAction_alwaysReturnsFalse_withAlwaysSetting() throws {
        mockProfile.prefs.setString(StartAtHome.always.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
        let subject = createSubject(with: mockProfile)
        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeActionType.didBrowserBecomeActive
        )

        let expectation = XCTestExpectation(description: "Start At Home action should be dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.startAtHomeProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? StartAtHomeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? StartAtHomeMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted)
        XCTAssertEqual(actionCalled.shouldStartAtHome, false)
    }

    @MainActor
    func test_didBrowserBecomeActiveAction_alwaysReturnsFalse_withDisabledSetting() throws {
        mockProfile.prefs.setString(StartAtHome.disabled.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
        let subject = createSubject(with: mockProfile)
        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeActionType.didBrowserBecomeActive
        )

        let expectation = XCTestExpectation(description: "Start At Home action should be dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.startAtHomeProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? StartAtHomeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? StartAtHomeMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted)
        XCTAssertEqual(actionCalled.shouldStartAtHome, false)
    }

    @MainActor
    func test_didBrowserBecomeActiveAction_alwaysReturnsFalse_withNoSetting() throws {
        let subject = createSubject(with: mockProfile)
        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeActionType.didBrowserBecomeActive
        )

        let expectation = XCTestExpectation(description: "Start At Home action should be dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.startAtHomeProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? StartAtHomeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? StartAtHomeMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted)
        XCTAssertEqual(actionCalled.shouldStartAtHome, false)
    }

    @MainActor
    func test_didBrowserBecomeActiveAction_alwaysReturnsFalse_withPrivateTab() throws {
        mockProfile.prefs.setString(StartAtHome.always.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
        let privateTab = mockTabManager.addTab(isPrivate: true)
        mockTabManager.selectTab(privateTab)

        let subject = createSubject(with: mockProfile)
        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeActionType.didBrowserBecomeActive
        )

        let expectation = XCTestExpectation(description: "Start At Home action should be dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.startAtHomeProvider(appState, action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? StartAtHomeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? StartAtHomeMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted)
        XCTAssertEqual(actionCalled.shouldStartAtHome, false)
    }

    // MARK: - Helpers
    private func createSubject(with mockProfile: Profile = MockProfile()) -> EcosiaStartAtHomeMiddleware {
        let testDate = Date(timeIntervalSince1970: 1_000_065_600)
        let lastSessionDate = Calendar.current.date(
            byAdding: .hour,
            value: -5,
            to: testDate
        )!
        UserDefaults.standard.setValue(lastSessionDate, forKey: "LastActiveTimestamp")
        return EcosiaStartAtHomeMiddleware(
            profile: mockProfile,
            windowManager: mockWindowManager,
            dateProvider: MockDateProvider(fixedDate: testDate))
    }

    // MARK: StoreTestUtility
    func setupAppState() -> Client.AppState {
        let appState = AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
                ]
            )
        )
        self.appState = appState
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
