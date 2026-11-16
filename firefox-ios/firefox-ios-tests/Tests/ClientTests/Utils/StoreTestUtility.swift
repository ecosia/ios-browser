// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import XCTest

@testable import Client

@MainActor
protocol StoreTestUtility: AnyObject {
    var mockStore: MockStoreForMiddleware<AppState>! { get set }
    func setupAppState() -> AppState
    func setupStore()
    func resetStore()
}

extension StoreTestUtility {
    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        // XCTest keeps test case instances for the whole run; without this the recorded actions outlive the test.
        mockStore = nil
        StoreTestUtilityHelper.resetStore()
    }
}

/// Utility class used when replacing the global store for testing purposes
class StoreTestUtilityHelper {
    // Ecosia: Firefox wraps every body in this file in `#if MOCKABLE_STORE`. That condition is evaluated
    // for the test target, which Ecosia's Tuist settings don't define it for, so the guards would compile
    // the bodies away and silently leave the production store in place — the bodies here are unguarded.
    @MainActor
    static func setupStore(with appState: AppState, middlewares: [Middleware<AppState>]) {
        replaceStore(Store(
            state: appState,
            reducer: AppState.reducer,
            middlewares: middlewares
        ))
    }

    /// Replace the global store with a mock store (e.g. MockStoreForMiddleware) for isolated middleware testing.
    @MainActor
    static func setupStore(with mockStore: any DefaultDispatchStore<AppState>) {
        replaceStore(mockStore)
    }

    /// In order to avoid flaky tests, we should reset the store similar to production
    @MainActor
    static func resetStore() {
        // Ecosia: Mirror the same guard used in AppState.swift — evaluating the global `middlewares`
        // array in unit tests would initialise all middleware objects (including those that resolve
        // Profile / SearchEnginesManager from AppContainer), which can crash when the container is
        // in the brief empty window after AppContainer.shared.reset() in a test setUp.
        // Use the same inline check as AppConstants.isRunningUnitTest to avoid importing Common here.
        let isUnitTest = NSClassFromString("XCTestCase") != nil
        let activeMiddlewares: [Middleware<AppState>] = isUnitTest ? [] : middlewares
        replaceStore(Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: activeMiddlewares
        ))
    }
}
