// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client
@testable import Ecosia

final class ProductTourSpotlightCoordinatorTests: XCTestCase {

    // MARK: - Properties

    private var sut: ProductTourSpotlightCoordinator!
    private var viewController: UIViewController!
    private var bottomContentView: UIView!
    private var tourManager: ProductTourManager!
    private var userDefaults: UserDefaults!
    private var suiteName: String!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        suiteName = "ProductTourSpotlightCoordinatorTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        tourManager = ProductTourManager(userDefaults: userDefaults)

        viewController = UIViewController()
        bottomContentView = UIView()

        // Load the view so layout is available
        viewController.loadViewIfNeeded()
        viewController.view.addSubview(bottomContentView)

        sut = ProductTourSpotlightCoordinator(
            viewController: viewController,
            bottomContentView: bottomContentView,
            theme: LightTheme(),
            tourManager: tourManager
        )

        // Put the tour into an active state for all tests
        tourManager.resetTour()
    }

    override func tearDown() {
        sut = nil
        viewController = nil
        bottomContentView = nil
        tourManager = nil

        if let suiteName {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        userDefaults = nil
        suiteName = nil

        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsNotShowingSpotlight() {
        XCTAssertFalse(sut.isShowingSpotlight)
    }

    // MARK: - productTour(didReceiveEvent:) Tests

    func testDidReceiveEvent_searchCompleted_showsSpotlight() {
        sut.productTour(didReceiveEvent: .searchCompleted)

        XCTAssertTrue(sut.isShowingSpotlight)
    }

    func testDidReceiveEvent_externalWebsiteVisited_showsSpotlight() {
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)

        XCTAssertTrue(sut.isShowingSpotlight)
    }

    func testDidReceiveEvent_tourCompleted_dismissesSpotlight() {
        // Given: A spotlight is already showing
        sut.productTour(didReceiveEvent: .searchCompleted)
        XCTAssertTrue(sut.isShowingSpotlight)

        // When: Tour is completed
        sut.productTour(didReceiveEvent: .tourCompleted)

        XCTAssertFalse(sut.isShowingSpotlight)
    }

    func testDidReceiveEvent_tourStarted_dismissesSpotlight() {
        // Given: A spotlight is already showing
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)
        XCTAssertTrue(sut.isShowingSpotlight)

        // When: Tour is reset/started
        sut.productTour(didReceiveEvent: .tourStarted)

        XCTAssertFalse(sut.isShowingSpotlight)
    }

    func testDidReceiveEvent_searchCompleted_replacesExistingSpotlight() {
        // Given: External website spotlight is already showing
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)
        XCTAssertTrue(sut.isShowingSpotlight)

        // When: A new spotlight event arrives
        sut.productTour(didReceiveEvent: .searchCompleted)

        // Then: Coordinator should still be showing a spotlight (the new one)
        XCTAssertTrue(sut.isShowingSpotlight)
    }

    // MARK: - showSpotlightIfNeeded Tests

    func testShowSpotlightIfNeeded_whenSearchSpotlightDue_showsSpotlight() {
        // Given: First search is done but spotlight not yet shown
        tourManager.completeFirstSearchIfNeeded()

        sut.showSpotlightIfNeeded()

        XCTAssertTrue(sut.isShowingSpotlight)
    }

    func testShowSpotlightIfNeeded_whenExternalWebsiteSpotlightDue_showsSpotlight() {
        // Given: External website visited but spotlight not yet shown
        tourManager.completeExternalWebsiteVisitIfNeeded()

        sut.showSpotlightIfNeeded()

        XCTAssertTrue(sut.isShowingSpotlight)
    }

    func testShowSpotlightIfNeeded_whenNothingDue_doesNotShowSpotlight() {
        // Given: Fresh tour with no milestones completed
        sut.showSpotlightIfNeeded()

        XCTAssertFalse(sut.isShowingSpotlight)
    }

    func testShowSpotlightIfNeeded_whenTourAlreadyComplete_doesNotShowSpotlight() {
        tourManager.completeTour()

        sut.showSpotlightIfNeeded()

        XCTAssertFalse(sut.isShowingSpotlight)
    }

    // MARK: - updateTheme Tests

    func testUpdateTheme_doesNotCrashWhenNoSpotlightShowing() {
        XCTAssertNoThrow(sut.updateTheme(DarkTheme()))
    }

    func testUpdateTheme_doesNotCrashWhenSpotlightIsShowing() {
        sut.productTour(didReceiveEvent: .searchCompleted)

        XCTAssertNoThrow(sut.updateTheme(DarkTheme()))
    }

    // MARK: - openURL Callback Tests

    func testOpenURLCallback_isNilByDefault() {
        XCTAssertNil(sut.openURL)
    }

    func testOpenURLCallback_canBeAssigned() {
        var capturedURL: URL?
        sut.openURL = { capturedURL = $0 }

        sut.openURL?(URL(string: "https://example.com")!)

        XCTAssertEqual(capturedURL, URL(string: "https://example.com"))
    }

    // MARK: - Search Spotlight: Primary Action (step advancement)

    func testSearchSpotlight_primaryAction_onStep1_doesNotDismiss() {
        // Given: Search spotlight is on step 1 of 2
        sut.productTour(didReceiveEvent: .searchCompleted)
        XCTAssertTrue(sut.isShowingSpotlight)

        // When: Primary button tapped
        sut.handlePrimaryAction()

        // Then: Spotlight stays visible (moved to step 2, not finished)
        XCTAssertTrue(sut.isShowingSpotlight)
    }

    func testSearchSpotlight_primaryAction_onStep1_doesNotCompleteSearchMilestone() {
        // Given: Search spotlight on step 1
        sut.productTour(didReceiveEvent: .searchCompleted)

        // When: Primary tapped (moves to step 2, not yet done)
        sut.handlePrimaryAction()

        // Then: Search spotlight milestone still incomplete
        XCTAssertFalse(tourManager.completedMilestones.contains(.searchSpotlightDone))
    }

    func testSearchSpotlight_primaryAction_onStep2_dismissesSpotlight() {
        // Given: Search spotlight advanced to final step
        sut.productTour(didReceiveEvent: .searchCompleted)
        sut.handlePrimaryAction() // step 1 → step 2

        // When: Primary tapped on final step
        sut.handlePrimaryAction()

        // Then: Spotlight is dismissed
        XCTAssertFalse(sut.isShowingSpotlight)
    }

    func testSearchSpotlight_primaryAction_onStep2_completesSearchMilestone() {
        // Given: Search spotlight on final step
        sut.productTour(didReceiveEvent: .searchCompleted)
        sut.handlePrimaryAction() // step 1 → step 2

        // When: Final primary tapped
        sut.handlePrimaryAction()

        // Then: Search spotlight milestone is marked complete
        XCTAssertTrue(tourManager.completedMilestones.contains(.searchSpotlightDone))
    }

    // MARK: - Search Spotlight: Secondary Action (skip / back)

    func testSearchSpotlight_secondaryAction_onStep1_skips() {
        // Given: Search spotlight on step 1 (secondary = skip)
        sut.productTour(didReceiveEvent: .searchCompleted)

        // When: Secondary tapped
        sut.handleSecondaryAction()

        // Then: Spotlight dismissed and milestone complete
        XCTAssertFalse(sut.isShowingSpotlight)
        XCTAssertTrue(tourManager.completedMilestones.contains(.searchSpotlightDone))
    }

    func testSearchSpotlight_secondaryAction_onStep2_goesBack() {
        // Given: Search spotlight advanced to step 2 (secondary = back)
        sut.productTour(didReceiveEvent: .searchCompleted)
        sut.handlePrimaryAction() // step 1 → step 2

        // When: Secondary tapped (go back)
        sut.handleSecondaryAction()

        // Then: Spotlight stays visible, milestone not yet complete
        XCTAssertTrue(sut.isShowingSpotlight)
        XCTAssertFalse(tourManager.completedMilestones.contains(.searchSpotlightDone))
    }

    func testSearchSpotlight_secondaryAction_backThenPrimaryTwice_completesTour() {
        // Given: Navigate forward, back, then complete normally
        sut.productTour(didReceiveEvent: .searchCompleted)
        sut.handlePrimaryAction()    // step 1 → step 2
        sut.handleSecondaryAction()  // step 2 → step 1 (back)
        sut.handlePrimaryAction()    // step 1 → step 2
        sut.handlePrimaryAction()    // step 2 → complete

        XCTAssertFalse(sut.isShowingSpotlight)
        XCTAssertTrue(tourManager.completedMilestones.contains(.searchSpotlightDone))
    }

    // MARK: - External Website Spotlight: Primary Action

    func testExternalWebsiteSpotlight_primaryAction_dismissesSpotlight() {
        // Given: External website spotlight (single step)
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)

        // When: Primary tapped
        sut.handlePrimaryAction()

        // Then: Dismissed
        XCTAssertFalse(sut.isShowingSpotlight)
    }

    func testExternalWebsiteSpotlight_primaryAction_completesMilestone() {
        // Given: External website spotlight
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)

        // When: Primary tapped
        sut.handlePrimaryAction()

        // Then: Milestone marked complete
        XCTAssertTrue(tourManager.completedMilestones.contains(.externalWebsiteSpotlightDone))
    }

    // MARK: - External Website Spotlight: Secondary Action (Read More / openURL)

    func testExternalWebsiteSpotlight_secondaryAction_callsOpenURL() {
        // Given: External website spotlight with openURL handler assigned
        var capturedURL: URL?
        sut.openURL = { capturedURL = $0 }
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)

        // When: Secondary tapped (Read More)
        sut.handleSecondaryAction()

        // Then: openURL was called with a non-nil URL
        XCTAssertNotNil(capturedURL)
    }

    func testExternalWebsiteSpotlight_secondaryAction_dismissesSpotlight() {
        // Given: External website spotlight
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)

        // When: Secondary tapped
        sut.handleSecondaryAction()

        // Then: Spotlight dismissed
        XCTAssertFalse(sut.isShowingSpotlight)
    }

    func testExternalWebsiteSpotlight_secondaryAction_completesMilestone() {
        // Given: External website spotlight
        sut.productTour(didReceiveEvent: .externalWebsiteVisited)

        // When: Secondary tapped
        sut.handleSecondaryAction()

        // Then: Milestone marked complete even when navigating via Read More
        XCTAssertTrue(tourManager.completedMilestones.contains(.externalWebsiteSpotlightDone))
    }

    // MARK: - Observer Registration Tests

    func testCoordinator_isRegisteredAsObserver_onInit() {
        // We verify indirect registration by checking the coordinator reacts
        // to events broadcast from the tour manager it was given
        tourManager.completeFirstSearchIfNeeded() // fires .searchCompleted

        XCTAssertTrue(sut.isShowingSpotlight)
    }

    func testCoordinator_deregistersOnDeinit() {
        // Given: A coordinator that reacts to tour events
        var coordinator: ProductTourSpotlightCoordinator? = ProductTourSpotlightCoordinator(
            viewController: viewController,
            bottomContentView: bottomContentView,
            theme: LightTheme(),
            tourManager: tourManager
        )
        _ = coordinator // silence warning

        // When: The coordinator is deallocated
        coordinator = nil

        // Then: Further tour events should not crash
        XCTAssertNoThrow(tourManager.completeFirstSearchIfNeeded())
    }
}
