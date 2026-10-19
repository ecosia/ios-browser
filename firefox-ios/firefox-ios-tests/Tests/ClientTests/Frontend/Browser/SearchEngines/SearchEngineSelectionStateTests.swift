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

        let newState = reducer.legacyReducer(
            initialState,
            SearchEngineSelectionAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: SearchEngineSelectionActionType.didLoadSearchEngines,
                searchEngines: expectedResult
            )
        )

        XCTAssertEqual(newState.searchEngines, expectedResult)
        /* Ecosia: selected-search-engine coverage stays removed (removal predates this upgrade and
           carries no recorded reason — do not restore without confirming Ecosia's own selection
           behaviour satisfies it). Upstream's 155.1 version is kept verbatim below so the next
           upgrade can diff it; note that as of 155.1 upstream's state also models engines as
           `SearchEngineModel`, so the original divergence may no longer apply.
        XCTAssertNil(newState.selectedSearchEngine)
    }

    @MainActor
    func testDidTapSearchEngine() {
        let initialState = createSubject()
        let reducer = searchEngineSelectionReducer()

        let selectedSearchEngine = OpenSearchEngineTests.generateOpenSearchEngine(type: .wikipedia, withImage: UIImage())
                                   .generateModel()

        XCTAssertEqual(initialState.searchEngines, [])
        XCTAssertNil(initialState.selectedSearchEngine)

        let newState = reducer.legacyReducer(
            initialState,
            SearchEngineSelectionAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: SearchEngineSelectionActionType.didTapSearchEngine,
                selectedSearchEngine: selectedSearchEngine
            )
        )

        XCTAssertTrue(newState.searchEngines.isEmpty)
        XCTAssertEqual(newState.selectedSearchEngine, selectedSearchEngine)
         */
    }

    // MARK: - Private
    private func createSubject() -> SearchEngineSelectionState {
        return SearchEngineSelectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func searchEngineSelectionReducer() -> Reducer<SearchEngineSelectionState> {
        return SearchEngineSelectionState.reducer
    }
}
