// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
@testable import Client

@MainActor
protocol StoreTestUtility {
    func setupAppState() -> AppState
    func setupTestingStore()
    func resetTestingStore()
}

extension StoreTestUtility {
    func setupTestingStore() {}
    func resetTestingStore() {}
}

/// Utility class used when replacing the global store for testing purposes
class StoreTestUtilityHelper {
    /// Replace the global store with a mock store (e.g. MockStoreForMiddleware) for isolated middleware testing.
    @MainActor
    static func setupStore(with mockStore: any DefaultDispatchStore<AppState>) {
        store = mockStore
    }

    // Replace the global store with a real store over `appState` and the given middlewares.
    // Ecosia: 155.1 turned this into a `static` again (it was an instance method in the revision this
    // fork carried) and wrapped every body in this file in `#if TESTING`. Ecosia's Tuist targets do
    // not define a `TESTING` compilation condition, so those guards would compile the bodies away and
    // silently leave the production store in place — the overload is restored here unguarded.
    @MainActor
    static func setupStore(with appState: AppState, middlewares: [Middleware<AppState>]) {
        store = Store(
            state: appState,
            reducer: AppState.reducer,
            middlewares: middlewares
        )
    }

    /// Reset the global store back to a default production-like state.
    @MainActor
    static func resetStore() {
        // Ecosia: Mirror the same guard used in AppState.swift — evaluating the global `middlewares`
        // array in unit tests would initialise all middleware objects (including those that resolve
        // Profile / SearchEnginesManager from AppContainer), which can crash when the container is
        // in the brief empty window after AppContainer.shared.reset() in a test setUp.
        // Use the same inline check as AppConstants.isRunningUnitTest to avoid importing Common here.
        let isUnitTest = NSClassFromString("XCTestCase") != nil
        let activeMiddlewares: [Middleware<AppState>] = isUnitTest ? [] : middlewares
        store = Store(state: AppState(), reducer: AppState.reducer, middlewares: activeMiddlewares)
    }

    @MainActor
    func setupTestingStore(with appState: AppState, middlewares: [Middleware<AppState>]) {
        store = Store(
            state: appState,
            reducer: AppState.reducer,
            middlewares: middlewares
        )
    }

    /// In order to avoid flaky tests, we should reset the store
    /// similar to production
    @MainActor
    func resetTestingStore() {
        // Ecosia: See note in resetStore() above — avoid evaluating the global middlewares in unit tests.
        let isUnitTest = NSClassFromString("XCTestCase") != nil
        let activeMiddlewares: [Middleware<AppState>] = isUnitTest ? [] : middlewares
        store = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: activeMiddlewares
        )
    }
}
