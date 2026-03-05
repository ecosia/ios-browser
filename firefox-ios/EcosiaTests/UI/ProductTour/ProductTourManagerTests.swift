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
    var authManager: EcosiaBrowserWindowAuthManager!
    var testWindowUUID: WindowUUID!

    override func setUp() {
        super.setUp()
        suiteName = "ProductTourManagerTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        authManager = EcosiaBrowserWindowAuthManager.shared
        testWindowUUID = WindowUUID.XCTestDefaultUUID
        EcosiaAuthWindowRegistry.shared.registerWindow(testWindowUUID)
        sut = ProductTourManager(userDefaults: userDefaults, authManager: authManager)
    }

    override func tearDown() {
        if let suiteName = suiteName {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        authManager.clearAllStates()
        EcosiaAuthWindowRegistry.shared.clearAllWindows()
        userDefaults = nil
        sut = nil
        suiteName = nil
        authManager = nil
        testWindowUUID = nil
    }

    // MARK: - Helpers

    /// Simulates a login by dispatching a `userLoggedIn` action through the auth manager,
    /// which triggers the `ProductTourManager`'s notification handler.
    private func simulateLogin(accountOrigin: AccountOrigin?) {
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true,
            accountOrigin: accountOrigin
        )
        authManager.dispatch(action: action, for: testWindowUUID)
    }

    // MARK: - Initialization Tests

    func testInitialState_WhenExperimentDisabled_IsCompleted() {
        // Given/When: Experiment is disabled (default behavior)
        let manager = ProductTourManager(userDefaults: userDefaults, authManager: authManager)

        // Then: All milestones should be marked complete
        XCTAssertEqual(manager.completedMilestones, .all)
        XCTAssertFalse(manager.isInProductTour)
        XCTAssertFalse(manager.shouldShowProductTourHomepage)
    }

    func testInitialState_WhenNoSavedMilestones_DefaultsToCompleted() {
        // Given: No saved milestones in UserDefaults
        userDefaults.removeObject(forKey: "ProductTourMilestones")

        // When: Manager initializes
        let manager = ProductTourManager(userDefaults: userDefaults, authManager: authManager)

        // Then: Should default to completed (experiment disabled)
        XCTAssertEqual(manager.completedMilestones, .all)
    }

    // MARK: - shouldShowProductTourHomepage Tests

    func testShouldShowProductTourHomepage_WhenFreshTour_ReturnsTrue() {
        // Given: Fresh tour
        sut.resetTour()

        // Then: Should show product tour homepage
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
    }

    func testShouldShowProductTourHomepage_AfterFirstSearch_ReturnsFalse() {
        // Given: Tour where first search is completed
        sut.resetTour()
        sut.completeFirstSearchIfNeeded()

        // Then: Should not show product tour homepage
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
    }

    func testShouldShowProductTourHomepage_AfterExternalWebsiteVisit_StillReturnsTrue() {
        // Given: Tour where external website was visited but search not yet done
        sut.resetTour()
        sut.completeExternalWebsiteVisitIfNeeded()

        // Then: Should still show product tour homepage (search not done yet)
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
    }

    func testShouldShowProductTourHomepage_WhenTourCompleted_ReturnsFalse() {
        // Given: Completed tour
        sut.resetTour()
        sut.completeTour()

        // Then: Should not show product tour homepage
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
    }

    // MARK: - First Search Tests

    func testCompleteFirstSearchIfNeeded_MarksFirstSearchMilestone() {
        // Given: Fresh tour
        sut.resetTour()
        XCTAssertFalse(sut.completedMilestones.contains(.firstSearchDone))

        // When: Completing first search
        sut.completeFirstSearchIfNeeded()

        // Then: First search milestone should be set
        XCTAssertTrue(sut.completedMilestones.contains(.firstSearchDone))
    }

    func testCompleteFirstSearchIfNeeded_WhenAlreadyDone_DoesNothing() {
        // Given: First search already completed
        sut.resetTour()
        sut.completeFirstSearchIfNeeded()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Calling again
        sut.completeFirstSearchIfNeeded()

        // Then: No new event should be emitted
        XCTAssertTrue(observer.receivedEvents.isEmpty)
    }

    func testCompleteFirstSearchIfNeeded_WhenTourCompleted_DoesNothing() {
        // Given: Tour is completed
        sut.completeTour()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Attempting to complete first search
        sut.completeFirstSearchIfNeeded()

        // Then: No event should be emitted
        XCTAssertTrue(observer.receivedEvents.isEmpty)
    }

    // MARK: - External Website Visit Tests

    func testCompleteExternalWebsiteVisitIfNeeded_MarksVisitMilestone() {
        // Given: Fresh tour
        sut.resetTour()
        XCTAssertFalse(sut.completedMilestones.contains(.externalWebsiteVisitDone))

        // When: Visiting external website
        sut.completeExternalWebsiteVisitIfNeeded()

        // Then: External website visit milestone should be set
        XCTAssertTrue(sut.completedMilestones.contains(.externalWebsiteVisitDone))
    }

    func testCompleteExternalWebsiteVisitIfNeeded_WhenAlreadyDone_DoesNothing() {
        // Given: External website already visited
        sut.resetTour()
        sut.completeExternalWebsiteVisitIfNeeded()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Calling again
        sut.completeExternalWebsiteVisitIfNeeded()

        // Then: No new event should be emitted
        XCTAssertTrue(observer.receivedEvents.isEmpty)
    }

    func testCompleteExternalWebsiteVisitIfNeeded_WhenTourCompleted_DoesNothing() {
        // Given: Tour is completed
        sut.completeTour()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Attempting to complete external website visit
        sut.completeExternalWebsiteVisitIfNeeded()

        // Then: No event should be emitted
        XCTAssertTrue(observer.receivedEvents.isEmpty)
    }

    // MARK: - Spotlight Completion Tests

    func testCompleteSearchSpotlight_MarksMilestone() {
        // Given: Fresh tour
        sut.resetTour()

        // When: Completing search spotlight
        sut.completeSearchSpotlight()

        // Then: Search spotlight milestone should be marked
        XCTAssertTrue(sut.completedMilestones.contains(.searchSpotlightDone))
    }

    func testCompleteExternalWebsiteSpotlight_MarksMilestone() {
        // Given: Fresh tour
        sut.resetTour()

        // When: Completing external website spotlight
        sut.completeExternalWebsiteSpotlight()

        // Then: External website spotlight milestone should be marked
        XCTAssertTrue(sut.completedMilestones.contains(.externalWebsiteSpotlightDone))
    }

    // MARK: - shouldShow Spotlight Tests

    func testShouldShowSearchSpotlight_WhenSearchDoneButSpotlightNot_ReturnsTrue() {
        // Given: First search completed, spotlight not shown
        sut.resetTour()
        sut.completeFirstSearchIfNeeded()

        // Then
        XCTAssertTrue(sut.shouldShowSearchSpotlight)
    }

    func testShouldShowSearchSpotlight_WhenSpotlightDone_ReturnsFalse() {
        // Given: Search spotlight already completed
        sut.resetTour()
        sut.completeFirstSearchIfNeeded()
        sut.completeSearchSpotlight()

        // Then
        XCTAssertFalse(sut.shouldShowSearchSpotlight)
    }

    func testShouldShowSearchSpotlight_WhenSearchNotDone_ReturnsFalse() {
        // Given: Fresh tour, no search yet
        sut.resetTour()

        // Then
        XCTAssertFalse(sut.shouldShowSearchSpotlight)
    }

    func testShouldShowExternalWebsiteSpotlight_WhenVisitDoneButSpotlightNot_ReturnsTrue() {
        // Given: External website visited, spotlight not shown
        sut.resetTour()
        sut.completeExternalWebsiteVisitIfNeeded()

        // Then
        XCTAssertTrue(sut.shouldShowExternalWebsiteSpotlight)
    }

    func testShouldShowExternalWebsiteSpotlight_WhenSpotlightDone_ReturnsFalse() {
        // Given: External website spotlight already completed
        sut.resetTour()
        sut.completeExternalWebsiteVisitIfNeeded()
        sut.completeExternalWebsiteSpotlight()

        // Then
        XCTAssertFalse(sut.shouldShowExternalWebsiteSpotlight)
    }

    // MARK: - Tour Completion Tests

    func testTourCompletes_WhenAllMilestonesCompleted_SearchTrackFirst() {
        // Given: Fresh tour
        sut.resetTour()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Completing search track first, then external website track
        sut.completeFirstSearchIfNeeded()
        sut.completeSearchSpotlight()
        XCTAssertTrue(sut.isInProductTour, "Tour should still be in progress")

        sut.completeExternalWebsiteVisitIfNeeded()
        sut.completeExternalWebsiteSpotlight()

        // Then: Tour should be completed
        XCTAssertFalse(sut.isInProductTour)
        XCTAssertEqual(observer.receivedEvents.last, .tourCompleted)
    }

    func testTourCompletes_WhenAllMilestonesCompleted_ExternalTrackFirst() {
        // Given: Fresh tour
        sut.resetTour()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Completing external website track first, then search track
        sut.completeExternalWebsiteVisitIfNeeded()
        sut.completeExternalWebsiteSpotlight()
        XCTAssertTrue(sut.isInProductTour, "Tour should still be in progress")

        sut.completeFirstSearchIfNeeded()
        sut.completeSearchSpotlight()

        // Then: Tour should be completed
        XCTAssertFalse(sut.isInProductTour)
        XCTAssertEqual(observer.receivedEvents.last, .tourCompleted)
    }

    func testTourDoesNotComplete_WithOnlyOneTrackDone() {
        // Given: Fresh tour
        sut.resetTour()

        // When: Only completing search track
        sut.completeFirstSearchIfNeeded()
        sut.completeSearchSpotlight()

        // Then: Tour should not be completed
        XCTAssertTrue(sut.isInProductTour)
    }

    func testCompleteTour_ForcesAllMilestones() {
        // Given: Fresh tour
        sut.resetTour()
        XCTAssertTrue(sut.isInProductTour)

        // When: Force-completing tour
        sut.completeTour()

        // Then: All milestones marked and tour done
        XCTAssertEqual(sut.completedMilestones, .all)
        XCTAssertFalse(sut.isInProductTour)
    }

    func testCompleteTour_WhenAlreadyCompleted_DoesNotNotify() {
        // Given: Already completed tour
        sut.completeTour()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Calling completeTour again
        sut.completeTour()

        // Then: No event should be emitted
        XCTAssertTrue(observer.receivedEvents.isEmpty)
    }

    // MARK: - Reset Tests

    func testResetTour_ClearsAllMilestones() {
        // Given: Tour with completed milestones
        sut.resetTour()
        sut.completeFirstSearchIfNeeded()
        sut.completeSearchSpotlight()
        sut.completeExternalWebsiteVisitIfNeeded()
        sut.completeExternalWebsiteSpotlight()

        // When: Resetting tour
        sut.resetTour()

        // Then: Milestones should be cleared
        XCTAssertEqual(sut.completedMilestones, [])
        XCTAssertTrue(sut.isInProductTour)
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
    }

    // MARK: - isInProductTour Tests

    func testIsInProductTour_WhenFreshTour_ReturnsTrue() {
        sut.resetTour()
        XCTAssertTrue(sut.isInProductTour)
    }

    func testIsInProductTour_WhenPartiallyComplete_ReturnsTrue() {
        sut.resetTour()
        sut.completeFirstSearchIfNeeded()
        sut.completeSearchSpotlight()
        XCTAssertTrue(sut.isInProductTour)
    }

    func testIsInProductTour_WhenFullyComplete_ReturnsFalse() {
        sut.completeTour()
        XCTAssertFalse(sut.isInProductTour)
    }

    // MARK: - Independence Tests

    func testSearchAndExternalTracks_AreIndependent() {
        // Given: Fresh tour
        sut.resetTour()

        // When: Completing external website visit
        sut.completeExternalWebsiteVisitIfNeeded()

        // Then: Search-related state should be unaffected
        XCTAssertTrue(sut.shouldShowProductTourHomepage, "Homepage should still show since search not done")
        XCTAssertFalse(sut.shouldShowSearchSpotlight, "Search spotlight should not show yet")

        // When: Now completing first search
        sut.completeFirstSearchIfNeeded()

        // Then: Both tracks should be independently queryable
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
        XCTAssertTrue(sut.shouldShowSearchSpotlight)
        XCTAssertTrue(sut.shouldShowExternalWebsiteSpotlight)
    }

    // MARK: - Persistence Tests

    func testMilestonesAreNotPersisted_WhenExperimentDisabled() {
        // Given: Experiment is disabled and tour is reset
        sut.resetTour()

        // When: Milestones change
        sut.completeFirstSearchIfNeeded()

        // Then: Milestones should NOT be persisted
        let savedValue = userDefaults.integer(forKey: "ProductTourMilestones")
        XCTAssertEqual(savedValue, 0, "Milestones should not be saved when experiment is disabled")
    }

    func testPersistedMilestones_AreIgnoredWhenExperimentDisabled() {
        // Given: Milestones are manually saved in UserDefaults
        userDefaults.set(ProductTourMilestones.firstSearchDone.rawValue, forKey: "ProductTourMilestones")

        // When: Creating a new manager instance with experiment disabled
        let newManager = ProductTourManager(userDefaults: userDefaults, authManager: authManager)

        // Then: Should default to all milestones complete (experiment disabled)
        XCTAssertEqual(newManager.completedMilestones, .all)
    }

    // MARK: - Observer Tests

    func testObserver_ReceivesSearchCompletedEvent() {
        let observer = MockProductTourObserver()
        sut.resetTour()
        sut.addObserver(observer)

        sut.completeFirstSearchIfNeeded()

        XCTAssertEqual(observer.receivedEvents, [.searchCompleted])
    }

    func testObserver_ReceivesExternalWebsiteVisitedEvent() {
        let observer = MockProductTourObserver()
        sut.resetTour()
        sut.addObserver(observer)

        sut.completeExternalWebsiteVisitIfNeeded()

        XCTAssertEqual(observer.receivedEvents, [.externalWebsiteVisited])
    }

    func testObserver_ReceivesTourCompletedEvent() {
        let observer = MockProductTourObserver()
        sut.resetTour()
        sut.addObserver(observer)

        sut.completeTour()

        XCTAssertEqual(observer.receivedEvents, [.tourCompleted])
    }

    func testObserver_ReceivesTourStartedOnReset() {
        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        sut.resetTour()

        XCTAssertEqual(observer.receivedEvents, [.tourStarted])
    }

    func testAddObserver_DoesNotAddDuplicates() {
        let observer = MockProductTourObserver()
        sut.addObserver(observer)
        sut.addObserver(observer)
        sut.addObserver(observer)

        sut.resetTour()
        XCTAssertEqual(observer.receivedEvents.count, 1)
    }

    func testRemoveObserver_StopsNotifyingObserver() {
        let observer = MockProductTourObserver()
        sut.addObserver(observer)
        sut.removeObserver(observer)

        sut.resetTour()
        XCTAssertTrue(observer.receivedEvents.isEmpty)
    }

    func testWeakObservers_AreDeallocatedCorrectly() {
        var observer: MockProductTourObserver? = MockProductTourObserver()
        sut.addObserver(observer!)
        observer = nil

        XCTAssertNoThrow(sut.resetTour())
    }

    // MARK: - Account Origin Tests

    func testExistingAccountLogin_SkipsSearchTrack() {
        // Given: Fresh tour
        sut.resetTour()
        XCTAssertTrue(sut.shouldShowProductTourHomepage)

        // When: Existing account logs in
        simulateLogin(accountOrigin: .existingAccount)

        // Then: Search track is skipped, only external website track remains
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
        XCTAssertFalse(sut.shouldShowSearchSpotlight)
        XCTAssertTrue(sut.isInProductTour)
    }

    func testExistingAccountLogin_ExternalWebsiteTrackStillWorks() {
        // Given: Fresh tour with existing account login
        sut.resetTour()
        simulateLogin(accountOrigin: .existingAccount)

        // When: External website visit happens
        sut.completeExternalWebsiteVisitIfNeeded()

        // Then: External website spotlight should show
        XCTAssertTrue(sut.shouldShowExternalWebsiteSpotlight)

        // When: Spotlight is dismissed
        sut.completeExternalWebsiteSpotlight()

        // Then: Tour completes
        XCTAssertFalse(sut.isInProductTour)
    }

    func testNewAccountLogin_FullTourRemains() {
        // Given: Fresh tour
        sut.resetTour()

        // When: New account logs in
        simulateLogin(accountOrigin: .newAccount)

        // Then: Full tour still active — search track not skipped
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
        XCTAssertTrue(sut.isInProductTour)
    }

    func testNilAccountOrigin_FullTourRemains() {
        // Given: Fresh tour
        sut.resetTour()

        // When: Login without account origin (claim not configured)
        simulateLogin(accountOrigin: nil)

        // Then: Full tour still active — treated same as new account
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
        XCTAssertTrue(sut.isInProductTour)
    }

    func testExistingAccountLogin_WhenTourAlreadyCompleted_DoesNothing() {
        // Given: Tour already completed
        sut.completeTour()
        XCTAssertFalse(sut.isInProductTour)

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Existing account logs in
        simulateLogin(accountOrigin: .existingAccount)

        // Then: No events emitted, tour stays completed
        XCTAssertTrue(observer.receivedEvents.isEmpty)
        XCTAssertFalse(sut.isInProductTour)
    }

    func testExistingAccountLogin_NotifiesSearchCompleted() {
        // Given: Fresh tour
        sut.resetTour()

        let observer = MockProductTourObserver()
        sut.addObserver(observer)

        // When: Existing account logs in
        simulateLogin(accountOrigin: .existingAccount)

        // Then: Observers receive searchCompleted so they can skip to external website track
        XCTAssertTrue(observer.receivedEvents.contains(.searchCompleted))
    }

    func testCompleteWorkflow_ExistingAccount() {
        // Given: Fresh tour
        let observer = MockProductTourObserver()
        sut.addObserver(observer)
        sut.resetTour()

        // Step 1: Existing account logs in → search track auto-completed
        simulateLogin(accountOrigin: .existingAccount)
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
        XCTAssertFalse(sut.shouldShowSearchSpotlight)

        // Step 2: External website visit
        sut.completeExternalWebsiteVisitIfNeeded()
        XCTAssertTrue(sut.shouldShowExternalWebsiteSpotlight)

        // Step 3: External website spotlight done → tour completes
        sut.completeExternalWebsiteSpotlight()
        XCTAssertFalse(sut.isInProductTour)

        XCTAssertEqual(observer.receivedEvents, [
            .tourStarted,
            .searchCompleted,
            .externalWebsiteVisited,
            .tourCompleted
        ])
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow_SearchFirstThenExternalWebsite() {
        let observer = MockProductTourObserver()
        sut.addObserver(observer)
        sut.resetTour()

        // Step 1: First search
        XCTAssertTrue(sut.shouldShowProductTourHomepage)
        sut.completeFirstSearchIfNeeded()
        XCTAssertFalse(sut.shouldShowProductTourHomepage)
        XCTAssertTrue(sut.shouldShowSearchSpotlight)

        // Step 2: Search spotlight done
        sut.completeSearchSpotlight()
        XCTAssertFalse(sut.shouldShowSearchSpotlight)
        XCTAssertTrue(sut.isInProductTour)

        // Step 3: External website visit
        sut.completeExternalWebsiteVisitIfNeeded()
        XCTAssertTrue(sut.shouldShowExternalWebsiteSpotlight)

        // Step 4: External website spotlight done → tour completes
        sut.completeExternalWebsiteSpotlight()
        XCTAssertFalse(sut.shouldShowExternalWebsiteSpotlight)
        XCTAssertFalse(sut.isInProductTour)

        XCTAssertEqual(observer.receivedEvents, [
            .tourStarted,
            .searchCompleted,
            .externalWebsiteVisited,
            .tourCompleted
        ])
    }

    func testCompleteWorkflow_ExternalWebsiteFirstThenSearch() {
        let observer = MockProductTourObserver()
        sut.addObserver(observer)
        sut.resetTour()

        // Step 1: External website visit before search
        sut.completeExternalWebsiteVisitIfNeeded()
        XCTAssertTrue(sut.shouldShowProductTourHomepage, "Homepage still needed — search not done")
        XCTAssertTrue(sut.shouldShowExternalWebsiteSpotlight)

        // Step 2: External website spotlight done
        sut.completeExternalWebsiteSpotlight()
        XCTAssertTrue(sut.isInProductTour)

        // Step 3: First search
        sut.completeFirstSearchIfNeeded()
        XCTAssertTrue(sut.shouldShowSearchSpotlight)

        // Step 4: Search spotlight done → tour completes
        sut.completeSearchSpotlight()
        XCTAssertFalse(sut.isInProductTour)

        XCTAssertEqual(observer.receivedEvents, [
            .tourStarted,
            .externalWebsiteVisited,
            .searchCompleted,
            .tourCompleted
        ])
    }

    func testCompleteWorkflow_InterleavedMilestones() {
        // Given: Fresh tour
        sut.resetTour()

        // When: Both triggers happen before either spotlight is dismissed
        sut.completeFirstSearchIfNeeded()
        sut.completeExternalWebsiteVisitIfNeeded()

        XCTAssertTrue(sut.shouldShowSearchSpotlight)
        XCTAssertTrue(sut.shouldShowExternalWebsiteSpotlight)
        XCTAssertTrue(sut.isInProductTour)

        // Complete both spotlights
        sut.completeSearchSpotlight()
        XCTAssertTrue(sut.isInProductTour)

        sut.completeExternalWebsiteSpotlight()
        XCTAssertFalse(sut.isInProductTour)
    }
}

// MARK: - Mock Classes

final class MockProductTourObserver: ProductTourObserver {
    var receivedEvents: [ProductTourEvent] = []

    func productTour(didReceiveEvent event: ProductTourEvent) {
        receivedEvents.append(event)
    }
}
