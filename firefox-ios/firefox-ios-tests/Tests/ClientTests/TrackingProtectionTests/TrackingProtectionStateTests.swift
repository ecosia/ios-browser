// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Redux

@testable import Client

@MainActor
final class TrackingProtectionStateTests: XCTestCase {
    private var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        mockProfile = nil
    }

    func testDismissSurveyAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.navigateTo, .home)

        let action = getMiddlewareAction(for: .dismissTrackingProtection)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .close)
        XCTAssertNil(newState.displayView)
    }

    func testShowTrackingProtectionSettingsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertNil(initialState.displayView)

        let action = getMiddlewareAction(for: .navigateToSettings)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .settings)
        XCTAssertNil(newState.displayView)
    }

    func testShowTrackingProtectionDetailsAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertNil(initialState.displayView)

        let action = getMiddlewareAction(for: .showTrackingProtectionDetails)
        let newState = reducer(initialState, action)

        XCTAssertNil(newState.navigateTo)
        XCTAssertEqual(newState.displayView, .trackingProtectionDetails)
    }

    func testShowBlockedTrackersAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertNil(initialState.displayView)

        let action = getMiddlewareAction(for: .showBlockedTrackersDetails)
        let newState = reducer(initialState, action)

        XCTAssertNil(newState.navigateTo)
        XCTAssertEqual(newState.displayView, .blockedTrackersDetails)
    }

    func testToggleTrackingProtectionAction() {
        let initialState = createSubject()
        let reducer = trackingProtectionReducer()

        XCTAssertEqual(initialState.trackingProtectionEnabled, true)

        let action = getAction(for: .toggleTrackingProtectionStatus)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.trackingProtectionEnabled, false)
    }

    // MARK: - Private
    private func createSubject() -> TrackingProtectionState {
        return TrackingProtectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func trackingProtectionReducer() -> Reducer<TrackingProtectionState> {
        return TrackingProtectionState.reducer
    }

    private func getMiddlewareAction(
        for actionType: TrackingProtectionMiddlewareActionType
    ) -> TrackingProtectionMiddlewareAction {
        return  TrackingProtectionMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getAction(for actionType: TrackingProtectionActionType) -> TrackingProtectionAction {
        return  TrackingProtectionAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
