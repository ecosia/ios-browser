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

    /// Reset the global store back to a default production-like state.
    @MainActor
    static func resetStore() {
        store = Store(state: AppState(), reducer: AppState.reducer, middlewares: middlewares)
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
        store = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: middlewares
        )
    }
}
