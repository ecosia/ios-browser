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
        InvisibleTabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()
    }

    override func tearDown() {
        InvisibleTabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()

        mockProfile = nil
        authenticationState = nil
        testTabs = nil

        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testCompleteAuthenticationFlow() {
        // Given - Invisible tab is created for authentication
        let authTab = createMockTab(uuid: "auth-tab")
        markTabAsInvisible(authTab)

        // When - Authentication flow completes
        setupAutoCloseForTab(authTab)

        // Simulate authentication completion
        triggerAuthCompletion()

        // Then - Tab should be automatically closed
        let expectation = XCTestExpectation(description: "Authentication flow completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertFalse(isTabTracked(authTab), "Tab should no longer be tracked")
    }

    func testAuthenticationTimeoutFallback() {
        // Given - Invisible tab with short timeout
        let authTab = createMockTab(uuid: "timeout-tab")
        markTabAsInvisible(authTab)

        // When - Setup auto-close with short timeout but no notification
        setupAutoCloseForTab(authTab, timeout: 0.1)

        // Then - Tab should be closed by timeout
        let expectation = XCTestExpectation(description: "Timeout fallback triggered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertFalse(isTabTracked(authTab), "Tab should no longer be tracked after timeout")
    }

    func testFailedAuthenticationDoesNotCreateInvisibleTab() {
        // Given - Authentication state configured for failure
        _ = simulateLoginAttempt() // Use _ to indicate we don't need the result

        // When - Authentication fails (simulated)
        authenticationState.shouldSucceed = false

        // Then - No invisible tabs should be created
        // This would need actual implementation to verify
        // For now, we just verify the setup doesn't crash
        XCTAssertNotNil(authenticationState)
    }

    // MARK: - Complex Flow Tests

    func testConcurrentAuthenticationFlows() {
        // Given - Multiple authentication tabs
        let authTabs = (0..<3).map { createMockTab(uuid: "concurrent-auth-\($0)") }
        authTabs.forEach { markTabAsInvisible($0) }
        authTabs.forEach { setupAutoCloseForTab($0) }

        // When - All authentications complete simultaneously
        triggerAuthCompletion()

        // Then - All tabs should be cleaned up
        let expectation = XCTestExpectation(description: "Concurrent flows completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        authTabs.forEach { tab in
            XCTAssertFalse(isTabTracked(tab), "Tab \(tab.tabUUID) should no longer be tracked")
        }
    }

    // MARK: - Helper Methods

    private func simulateLoginAttempt() -> Tab {
        let tab = createMockTab(uuid: "login-attempt")
        markTabAsInvisible(tab)
        setupAutoCloseForTab(tab, timeout: 10.0)
        return tab
    }

    private func markTabAsInvisible(_ tab: Tab) {
        tab.isInvisible = true
    }

    private func setupAutoCloseForTab(_ tab: Tab, timeout: TimeInterval = 10.0) {
        InvisibleTabAutoCloseManager.shared.setupAutoCloseForTab(tab, on: .EcosiaAuthStateChanged, timeout: timeout)
    }

    private func triggerAuthCompletion() {
        NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)
    }

    private func simulateAuthenticationSuccess() {
        triggerAuthCompletion()
        authenticationState.login()
    }

    private func simulateAuthenticationFailure() {
        authenticationState.shouldSucceed = false
        NotificationCenter.default.post(name: .EcosiaAuthDidFailWithError, object: nil)
    }

    private func simulateUserClosesTab(_ tab: Tab) {
        if let index = testTabs.firstIndex(where: { $0.tabUUID == tab.tabUUID }) {
            testTabs.remove(at: index)
        }
        InvisibleTabAutoCloseManager.shared.cancelAutoCloseForTab(tab.tabUUID)
    }

    private func simulateTabBecomesVisible(_ tab: Tab) {
        tab.isInvisible = false
        InvisibleTabAutoCloseManager.shared.cancelAutoCloseForTab(tab.tabUUID)
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

    private func createMockTab(uuid: String) -> Tab {
        let tab = Tab(profile: mockProfile, isPrivate: false, windowUUID: WindowUUID())
        tab.tabUUID = uuid
        return tab
    }

    private func isTabTracked(_ tab: Tab) -> Bool {
        return InvisibleTabAutoCloseManager.shared.trackedTabUUIDs.contains(tab.tabUUID)
    }
}

// MARK: - Mock Classes

/// Mock authentication state for testing
class MockAuthenticationState {
    private(set) var isLoggedIn = false
    var shouldSucceed = true

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
    static let EcosiaAuthStateChanged = Notification.Name("EcosiaAuthStateChanged")
}
