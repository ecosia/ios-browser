// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

@MainActor
final class SearchEngineSelectionStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testInitialization() {
        let initialState = createSubject()

        XCTAssertFalse(initialState.shouldDismiss)
        XCTAssertEqual(initialState.searchEngines, [])
    }

    func testDidLoadSearchEngines() {
        let initialState = createSubject()
        let reducer = searchEngineSelectionReducer()

        let engines: [OpenSearchEngine] = [
            OpenSearchEngineTests.generateOpenSearchEngine(type: .wikipedia, withImage: UIImage()),
            OpenSearchEngineTests.generateOpenSearchEngine(type: .youtube, withImage: UIImage())
        ]
        // Ecosia: v147 uses SearchEngineModel instead of OpenSearchEngine
        let expectedResult: [SearchEngineModel] = engines.map { $0.generateModel() }

        XCTAssertEqual(initialState.searchEngines, [])

        let newState = reducer(
            initialState,
            SearchEngineSelectionAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: SearchEngineSelectionActionType.didLoadSearchEngines,
                searchEngines: expectedResult
            )
        )

        XCTAssertEqual(newState.searchEngines, expectedResult)
    }

    // MARK: - Private
    private func createSubject() -> SearchEngineSelectionState {
        return SearchEngineSelectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func searchEngineSelectionReducer() -> Reducer<SearchEngineSelectionState> {
        return SearchEngineSelectionState.reducer
    }
}
