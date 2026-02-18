// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
import Common

final class ProductTourManagerTests: XCTestCase {
    var userDefaults: UserDefaults!
    var sut: ProductTourManager!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "ProductTourManagerTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        sut = ProductTourManager(userDefaults: userDefaults)
    }
    override func tearDown() {
        if let suiteName = suiteName {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        userDefaults = nil
        sut = nil
        suiteName = nil
    }

    // MARK: - Initialization Tests

    func testInitialState_WhenExperimentDisabled_ReturnsCompleted() {
        // Given: Experiment is disabled (default behavior)
        // When: Manager initializes
        let manager = ProductTourManager(userDefaults: userDefaults)

        // Then: State should be tourCompleted
        XCTAssertEqual(manager.currentState, .tourCompleted)
        XCTAssertFalse(manager.isInProductTour)
    }

    func testInitialState_WhenNoSavedState_ReturnsDefault() {
        // Given: No saved state in UserDefaults
        userDefaults.removeObject(forKey: "ProductTourState")

        // When: Manager initializes
        let manager = ProductTourManager(userDefaults: userDefaults)

        // Then: State should be default (tourCompleted)
        XCTAssertEqual(manager.currentState, .tourCompleted)
    }

    // MARK: - State Management Tests

    func testAdvanceToNextState_FromFirstSearch_MovesToSearchCompleted() {
        // Given: Tour is at firstSearch state
        sut.resetTour()
        XCTAssertEqual(sut.currentState, .firstSearch)

        // When: Advancing to next state
        sut.advanceToNextState()

        // Then: State should be searchCompleted
        XCTAssertEqual(sut.currentState, .searchCompleted)
    }

    func testAdvanceToNextState_FromSearchCompleted_MovesToTourCompleted() {
        // Given: Tour is at searchCompleted state
        sut.resetTour()
        sut.advanceToNextState()
        XCTAssertEqual(sut.currentState, .searchCompleted)

        // When: Advancing to next state
        sut.advanceToNextState()

        // Then: State should be tourCompleted
        XCTAssertEqual(sut.currentState, .tourCompleted)
    }

    func testAdvanceToNextState_FromTourCompleted_StaysAtTourCompleted() {
        // Given: Tour is at tourCompleted state
        sut.completeTour()
        XCTAssertEqual(sut.currentState, .tourCompleted)

        // When: Advancing to next state
        sut.advanceToNextState()

        // Then: State should remain tourCompleted
        XCTAssertEqual(sut.currentState, .tourCompleted)
    }

    func testCompleteFirstSearchIfNeeded_WhenFirstSearch_AdvancesState() {
        // Given: Tour is at firstSearch state
        sut.resetTour()
        XCTAssertEqual(sut.currentState, .firstSearch)

        // When: Completing first search
        sut.completeFirstSearchIfNeeded()

        // Then: State should be searchCompleted
        XCTAssertEqual(sut.currentState, .searchCompleted)
    }

    func testCompleteFirstSearchIfNeeded_WhenNotFirstSearch_DoesNothing() {
        // Given: Tour is at searchCompleted state
        sut.resetTour()
        sut.advanceToNextState()
        XCTAssertEqual(sut.currentState, .searchCompleted)

        // When: Calling completeFirstSearchIfNeeded
        sut.completeFirstSearchIfNeeded()

        // Then: State should remain searchCompleted
        XCTAssertEqual(sut.currentState, .searchCompleted)
    }

    func testCompleteTour_FromAnyState_MovesToTourCompleted() {
        // Given: Tour is at firstSearch state
        sut.resetTour()
        XCTAssertEqual(sut.currentState, .firstSearch)

        // When: Completing tour
        sut.completeTour()

        // Then: State should be tourCompleted
        XCTAssertEqual(sut.currentState, .tourCompleted)
        XCTAssertFalse(sut.isInProductTour)
    }

    func testResetTour_FromAnyState_MovesToFirstSearch() {
        // Given: Tour is completed
        sut.completeTour()
        XCTAssertEqual(sut.currentState, .tourCompleted)

        // When: Resetting tour
        sut.resetTour()

        // Then: State should be firstSearch
        XCTAssertEqual(sut.currentState, .firstSearch)
        XCTAssertTrue(sut.isInProductTour)
    }

    // MARK: - Property Tests

    func testShouldShowProductTourHomepage_WhenFirstSearch_ReturnsTrue() {
        // Given: Tour is at firstSearch state
        sut.resetTour()

        // Then: Should show product tour homepage
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
    }

    func testShouldShowProductTourHomepage_WhenNotFirstSearch_ReturnsFalse() {
        // Given: Tour is at searchCompleted state
        sut.resetTour()
        sut.advanceToNextState()

        // Then: Should not show product tour homepage
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
    }

    func testIsInProductTour_WhenFirstSearch_ReturnsTrue() {
        // Given: Tour is at firstSearch state
        sut.resetTour()

        // Then: Should be in product tour
        XCTAssertTrue(sut.isInProductTour)
    }

    func testIsInProductTour_WhenSearchCompleted_ReturnsTrue() {
        // Given: Tour is at searchCompleted state
        sut.resetTour()
        sut.advanceToNextState()

        // Then: Should be in product tour
        XCTAssertTrue(sut.isInProductTour)
    }

    func testIsInProductTour_WhenTourCompleted_ReturnsFalse() {
        // Given: Tour is completed
        sut.completeTour()

        // Then: Should not be in product tour
        XCTAssertFalse(sut.isInProductTour)
    }

    // MARK: - Persistence Tests

    func testStateIsNotPersisted_WhenExperimentDisabled() {
        // Given: Experiment is disabled and tour is reset to firstSearch
        sut.resetTour()

        // When: State changes
        sut.advanceToNextState()

        // Then: State should NOT be persisted (experiment disabled)
        let savedState = userDefaults.string(forKey: "ProductTourState")
        XCTAssertNil(savedState, "State should not be saved when experiment is disabled")
    }

    func testPersistedState_IsIgnoredWhenExperimentDisabled() {
        // Given: A state is manually saved in UserDefaults
        userDefaults.set(ProductTourState.searchCompleted.rawValue, forKey: "ProductTourState")

        // When: Creating a new manager instance with experiment disabled
        let newManager = ProductTourManager(userDefaults: userDefaults)

        // Then: State should NOT be loaded (experiment disabled), defaults to tourCompleted
        XCTAssertEqual(newManager.currentState,
                       .tourCompleted,
                       "Should return default state when experiment is disabled")
    }

    // MARK: - Observer Tests

    func testAddObserver_AddsObserverSuccessfully() {
        // Given: A mock observer
        let observer = MockProductTourObserver()

        // When: Adding observer
        sut.addObserver(observer)

        // Then: Observer should receive state change notifications
        sut.resetTour()
        XCTAssertEqual(observer.receivedStates.count, 1)
        XCTAssertEqual(observer.receivedStates.last, .firstSearch)
    }

    func testAddObserver_DoesNotAddDuplicates() {
        // Given: A mock observer
        let observer = MockProductTourObserver()

        // When: Adding same observer multiple times
        sut.addObserver(observer)
        sut.addObserver(observer)
        sut.addObserver(observer)

        // Then: Observer should only be added once
        sut.resetTour()
        XCTAssertEqual(observer.receivedStates.count, 1)
    }

    func testRemoveObserver_StopsNotifyingObserver() {
        // Given: An observer that's been added
        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Removing observer
        sut.removeObserver(observer)

        // Then: Observer should not receive further notifications
        observer.receivedStates.removeAll()
        sut.resetTour()
        XCTAssertEqual(observer.receivedStates.count, 0)
    }

    func testObservers_AreNotifiedOnStateChange() {
        // Given: Multiple observers
        let observer1 = MockProductTourObserver()
        let observer2 = MockProductTourObserver()
        sut.addObserver(observer1)
        sut.addObserver(observer2)

        // When: State changes
        sut.resetTour()

        // Then: All observers should be notified
        XCTAssertEqual(observer1.receivedStates.last, .firstSearch)
        XCTAssertEqual(observer2.receivedStates.last, .firstSearch)
    }

    func testObservers_AreNotNotifiedWhenStateDoesNotChange() {
        // Given: An observer and tour at firstSearch state
        sut.resetTour()
        let observer = MockProductTourObserver()
        sut.addObserver(observer)
        observer.receivedStates.removeAll()

        // When: Attempting to set same state (via property that doesn't change)
        sut.resetTour()

        // Then: Observer should not be notified again
        XCTAssertEqual(observer.receivedStates.count, 0)
    }

    func testWeakObservers_AreDeallocatedCorrectly() {
        // Given: An observer that will be deallocated
        var observer: MockProductTourObserver? = MockProductTourObserver()
        sut.addObserver(observer!)

        // When: Observer is deallocated
        observer = nil

        // Then: State change should not crash (weak reference is handled)
        XCTAssertNoThrow(sut.resetTour())
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow_FirstSearchToCompletion() {
        // Given: Starting a new tour with observer added first
        let observer = MockProductTourObserver()
        sut.addObserver(observer)
        sut.resetTour()

        // When: Going through complete workflow
        XCTAssertEqual(sut.currentState, .firstSearch)
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
        XCTAssertTrue(sut.isInProductTour)

        sut.completeFirstSearchIfNeeded()
        XCTAssertEqual(sut.currentState, .searchCompleted)
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
        XCTAssertTrue(sut.isInProductTour)

        sut.advanceToNextState()
        XCTAssertEqual(sut.currentState, .tourCompleted)
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
        XCTAssertFalse(sut.isInProductTour)

        // Then: Observer should have received all state changes
        XCTAssertEqual(observer.receivedStates.count, 3)
        XCTAssertEqual(observer.receivedStates[0], .firstSearch)
        XCTAssertEqual(observer.receivedStates[1], .searchCompleted)
        XCTAssertEqual(observer.receivedStates[2], .tourCompleted)
    }
}

// MARK: - Mock Classes

final class MockProductTourObserver: ProductTourObserver {
    var receivedStates: [ProductTourState] = []

    func productTourStateDidChange(_ state: ProductTourState) {
        receivedStates.append(state)
    }
}
