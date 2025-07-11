// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

/// Comprehensive end-to-end integration tests for the authentication flow with invisible tabs.
/// Tests the complete flow from login initiation to successful completion with auto-close.
final class AuthenticationFlowIntegrationTests: XCTestCase {

    // MARK: - Properties

    private var mockProfile: MockProfile!
    private var authenticationState: MockAuthenticationState!
    private var testTabs: [Tab]!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        mockProfile = MockProfile()
        authenticationState = MockAuthenticationState()
        testTabs = []

        // Clean up any existing state
        TabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()
    }

    override func tearDown() {
        TabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()

        mockProfile = nil
        authenticationState = nil
        testTabs = nil

        super.tearDown()
    }

    // MARK: - Happy Path Tests

    /// Tests the complete happy path: login attempt → invisible tab creation → authentication success → auto-close
    func testCompleteAuthenticationFlowHappyPath() {
        // Given: Initial state with no authentication
        XCTAssertFalse(authenticationState.isLoggedIn, "Should start not logged in")
        XCTAssertEqual(testTabs.count, 0, "Should start with no tabs")

        // When: User initiates login
        let authTab = simulateLoginAttempt()

        // Then: Invisible tab should be created and tracked for auto-close
        XCTAssertTrue(authTab.isInvisible, "Auth tab should be invisible")
        XCTAssertEqual(testTabs.count, 1, "Should have one tab")
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 1, "Should track one tab for auto-close")

        // When: Authentication completes successfully
        simulateAuthenticationSuccess()

        // Then: Tab should be auto-closed and user should be logged in
        waitForAsyncOperations()
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 0, "Should not track any tabs")
        XCTAssertTrue(authenticationState.isLoggedIn, "User should be logged in")
    }

    /// Tests authentication flow with private browsing mode
    func testAuthenticationFlowWithPrivateBrowsing() {
        // Given: Private browsing mode
        let authTab = simulateLoginAttempt(isPrivate: true)

        // Then: Private invisible tab should be created
        XCTAssertTrue(authTab.isInvisible, "Auth tab should be invisible")
        XCTAssertTrue(authTab.isPrivate, "Auth tab should be private")
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 1, "Should track private tab")

        // When: Authentication completes
        simulateAuthenticationSuccess()

        // Then: Private tab should be auto-closed
        waitForAsyncOperations()
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 0, "Should not track any tabs")
        XCTAssertTrue(authenticationState.isLoggedIn, "User should be logged in")
    }

    /// Tests authentication timeout scenario
    func testAuthenticationTimeout() {
        // Given: Authentication attempt with short timeout
        let authTab = simulateLoginAttempt(timeout: 1.0)

        XCTAssertTrue(authTab.isInvisible, "Auth tab should be invisible")
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 1, "Should track tab")

        // When: Timeout occurs (no authentication success)
        let timeoutExpectation = expectation(description: "Authentication timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            timeoutExpectation.fulfill()
        }
        wait(for: [timeoutExpectation], timeout: 2.0)

        // Then: Tab should be auto-closed due to timeout, user not logged in
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 0, "Should not track any tabs")
        XCTAssertFalse(authenticationState.isLoggedIn, "User should not be logged in after timeout")
    }

    /// Tests tab becoming visible before authentication completes
    func testTabBecomesVisibleDuringAuthentication() {
        // Given: Authentication in progress
        let authTab = simulateLoginAttempt()

        XCTAssertTrue(authTab.isInvisible, "Auth tab should start invisible")
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 1, "Should track tab")

        // When: Tab becomes visible (user switches to it)
        simulateTabBecomesVisible(authTab)

        // Then: Auto-close tracking should be cancelled
        XCTAssertFalse(authTab.isInvisible, "Tab should now be visible")
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 0, "Should not track visible tab")

        // When: Authentication completes
        simulateAuthenticationSuccess()

        // Then: Tab should NOT be auto-closed (it's visible), but user should be logged in
        waitForAsyncOperations()
        XCTAssertTrue(authenticationState.isLoggedIn, "User should be logged in")
    }

    /// Tests authentication failure scenario
    func testAuthenticationFailure() {
        // Given: Authentication attempt
        let authTab = simulateLoginAttempt()

        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 1, "Should track tab")

        // When: Authentication fails
        simulateAuthenticationFailure()

        // Then: Tab should remain tracked for retry, user not logged in
        waitForAsyncOperations()
        XCTAssertEqual(TabAutoCloseManager.shared.trackedTabCount, 1, "Should still track tab")
        XCTAssertFalse(authenticationState.isLoggedIn, "User should not be logged in after failure")
    }

    // MARK: - Helper Methods

    private func simulateLoginAttempt(isPrivate: Bool = false, timeout: TimeInterval = 10.0) -> Tab {
        let tab = createMockTab(isPrivate: isPrivate)
        tab.isInvisible = true
        testTabs.append(tab)

        // Setup auto-close tracking
        TabAutoCloseManager.shared.setupAutoCloseForTab(
            tab,
            on: .EcosiaAuthDidLoginWithSessionToken,
            timeout: timeout
        )

        return tab
    }

    private func simulateAuthenticationSuccess() {
        authenticationState.login()
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)
    }

    private func simulateAuthenticationFailure() {
        authenticationState.logout()
        NotificationCenter.default.post(name: .EcosiaAuthDidFailWithError, object: nil)
    }

    private func simulateUserClosesTab(_ tab: Tab) {
        if let index = testTabs.firstIndex(where: { $0.tabUUID == tab.tabUUID }) {
            testTabs.remove(at: index)
        }
        TabAutoCloseManager.shared.cancelAutoCloseForTab(tab.tabUUID)
    }

    private func simulateTabBecomesVisible(_ tab: Tab) {
        tab.isInvisible = false
        TabAutoCloseManager.shared.cancelAutoCloseForTab(tab.tabUUID)
    }

    private func waitForAsyncOperations() {
        let expectation = expectation(description: "Async operations completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    private func createMockTab(isPrivate: Bool = false) -> Tab {
        return Tab(profile: mockProfile, isPrivate: isPrivate, windowUUID: WindowUUID())
    }
}

// MARK: - Mock Classes

/// Mock authentication state for testing
class MockAuthenticationState {
    private(set) var isLoggedIn = false

    func login() {
        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let EcosiaAuthDidFailWithError = Notification.Name("EcosiaAuthDidFailWithError")
}
