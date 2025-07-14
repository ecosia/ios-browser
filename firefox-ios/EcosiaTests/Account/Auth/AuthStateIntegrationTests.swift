// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
import Common
@testable import Ecosia

final class AuthStateIntegrationTests: XCTestCase {

    var auth: Auth!
    var mockProvider: MockAuth0Provider!
    var authStateManager: AuthStateManager!
    var windowRegistry: EcosiaAuthWindowRegistry!
    var testWindowUUID: WindowUUID!

    override func setUp() {
        super.setUp()
        mockProvider = MockAuth0Provider()
        auth = Auth(auth0Provider: mockProvider)
        authStateManager = AuthStateManager.shared
        windowRegistry = EcosiaAuthWindowRegistry.shared
        testWindowUUID = WindowUUID.XCTestDefaultUUID

        // Reset call counts after initialization
        mockProvider.reset()
        // Ensure clean state for all tests
        mockProvider.hasStoredCredentials = false

        // Register a test window
        windowRegistry.registerWindow(testWindowUUID)
    }

    override func tearDown() {
        // Clean up state after each test
        authStateManager.clearAllStates()
        windowRegistry.clearAllWindows()
        mockProvider?.reset()
        mockProvider = nil
        auth = nil
        authStateManager = nil
        windowRegistry = nil
        testWindowUUID = nil
        super.tearDown()
    }

    // MARK: - Login Integration Tests

    func testLogin_withSuccessfulAuth_dispatchesUserLoggedInAction() async {
        // Arrange
        let expectedCredentials = createTestCredentials()
        mockProvider.mockCredentials = expectedCredentials

        var userLoggedInNotifications: [Notification] = []
        let expectation = expectation(description: "UserLoggedIn notification should be posted")
        var expectationFulfilled = false

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            if let actionType = notification.userInfo?["actionType"] as? String, actionType == "userLoggedIn" {
                userLoggedInNotifications.append(notification)
                if !expectationFulfilled {
                    expectationFulfilled = true
                    expectation.fulfill()
                }
            }
        }

        // Act
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(userLoggedInNotifications.isEmpty, "UserLoggedIn notification should be posted")

        let receivedNotification = userLoggedInNotifications.first!
        XCTAssertEqual(receivedNotification.name, .EcosiaAuthStateChanged, "Should receive auth state changed notification")

        let authState = receivedNotification.userInfo?["authState"] as? AuthWindowState
        XCTAssertNotNil(authState, "Notification should contain auth state")
        XCTAssertTrue(authState?.isLoggedIn == true, "Auth state should be logged in")
        XCTAssertEqual(authState?.windowUUID, testWindowUUID, "Auth state should be for correct window")
    }

    func testLogin_withAuthFailure_doesNotDispatchUserLoggedInAction() async {
        // Arrange
        let authError = NSError(domain: "MockAuth0Provider", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
        mockProvider.mockError = authError

        var userLoggedInNotifications: [Notification] = []
        var authStateLoadedNotifications: [Notification] = []
        let expectation = expectation(description: "AuthStateLoaded notification should be posted")
        var expectationFulfilled = false

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            if let actionType = notification.userInfo?["actionType"] as? String {
                if actionType == "userLoggedIn" {
                    userLoggedInNotifications.append(notification)
                } else if actionType == "authStateLoaded" {
                    authStateLoadedNotifications.append(notification)
                    if !expectationFulfilled {
                        expectationFulfilled = true
                        expectation.fulfill()
                    }
                }
            }
        }

        // Act
        do {
            try await auth.login()
            XCTFail("Login should fail, but succeeded")
        } catch {
            // Expected to fail
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(userLoggedInNotifications.isEmpty, "UserLoggedIn notification should not be posted on failure")
        XCTAssertFalse(authStateLoadedNotifications.isEmpty, "AuthStateLoaded notification should be posted")

        let receivedNotification = authStateLoadedNotifications.first!
        let authState = receivedNotification.userInfo?["authState"] as? AuthWindowState
        XCTAssertNotNil(authState, "Notification should contain auth state")
        XCTAssertFalse(authState?.isLoggedIn == true, "Auth state should not be logged in")
        XCTAssertEqual(authState?.windowUUID, testWindowUUID, "Auth state should be for correct window")
    }

    // MARK: - Logout Integration Tests

    func testLogout_withSuccessfulLogout_dispatchesUserLoggedOutAction() async {
        // Arrange
        await setupLoggedInState()

        var userLoggedOutNotifications: [Notification] = []
        let expectation = expectation(description: "UserLoggedOut notification should be posted")
        var expectationFulfilled = false

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            if let actionType = notification.userInfo?["actionType"] as? String, actionType == "userLoggedOut" {
                userLoggedOutNotifications.append(notification)
                if !expectationFulfilled {
                    expectationFulfilled = true
                    expectation.fulfill()
                }
            }
        }

        // Act
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(userLoggedOutNotifications.isEmpty, "UserLoggedOut notification should be posted")

        let receivedNotification = userLoggedOutNotifications.first!
        XCTAssertEqual(receivedNotification.name, .EcosiaAuthStateChanged, "Should receive auth state changed notification")

        let authState = receivedNotification.userInfo?["authState"] as? AuthWindowState
        XCTAssertNotNil(authState, "Notification should contain auth state")
        XCTAssertFalse(authState?.isLoggedIn == true, "Auth state should not be logged in")
        XCTAssertEqual(authState?.windowUUID, testWindowUUID, "Auth state should be for correct window")
    }

    func testLogout_withoutTriggerWebLogout_stillDispatchesUserLoggedOutAction() async {
        // Arrange
        await setupLoggedInState()

        var userLoggedOutNotifications: [Notification] = []
        let expectation = expectation(description: "UserLoggedOut notification should be posted")
        var expectationFulfilled = false

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            if let actionType = notification.userInfo?["actionType"] as? String, actionType == "userLoggedOut" {
                userLoggedOutNotifications.append(notification)
                if !expectationFulfilled {
                    expectationFulfilled = true
                    expectation.fulfill()
                }
            }
        }

        // Act
        do {
            try await auth.logout(triggerWebLogout: false)
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(userLoggedOutNotifications.isEmpty, "UserLoggedOut notification should be posted")

        let receivedNotification = userLoggedOutNotifications.first!
        XCTAssertEqual(receivedNotification.name, .EcosiaAuthStateChanged, "Should receive auth state changed notification")

        let authState = receivedNotification.userInfo?["authState"] as? AuthWindowState
        XCTAssertNotNil(authState, "Notification should contain auth state")
        XCTAssertFalse(authState?.isLoggedIn == true, "Auth state should not be logged in")
        XCTAssertEqual(authState?.windowUUID, testWindowUUID, "Auth state should be for correct window")
    }

    // MARK: - Credential Retrieval Integration Tests

    func testRetrieveStoredCredentials_withValidCredentials_dispatchesAuthStateLoadedAction() async {
        // Arrange
        let expectedCredentials = createTestCredentials()
        mockProvider.mockCredentials = expectedCredentials
        mockProvider.hasStoredCredentials = true

        var authStateLoadedNotifications: [Notification] = []
        let expectation = expectation(description: "AuthStateLoaded notification should be posted")
        var expectationFulfilled = false

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            if let actionType = notification.userInfo?["actionType"] as? String, actionType == "authStateLoaded" {
                authStateLoadedNotifications.append(notification)
                if !expectationFulfilled {
                    expectationFulfilled = true
                    expectation.fulfill()
                }
            }
        }

        // Act
        await auth.retrieveStoredCredentials()

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(authStateLoadedNotifications.isEmpty, "AuthStateLoaded notification should be posted")

        let receivedNotification = authStateLoadedNotifications.first!
        XCTAssertEqual(receivedNotification.name, .EcosiaAuthStateChanged, "Should receive auth state changed notification")

        let authState = receivedNotification.userInfo?["authState"] as? AuthWindowState
        XCTAssertNotNil(authState, "Notification should contain auth state")
        XCTAssertTrue(authState?.isLoggedIn == true, "Auth state should be logged in")
        XCTAssertEqual(authState?.windowUUID, testWindowUUID, "Auth state should be for correct window")
    }

    func testRetrieveStoredCredentials_withNoCredentials_dispatchesAuthStateLoadedWithLoggedOutState() async {
        // Arrange
        mockProvider.hasStoredCredentials = false

        var authStateLoadedNotifications: [Notification] = []
        let expectation = expectation(description: "AuthStateLoaded notification should be posted")
        var expectationFulfilled = false

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            if let actionType = notification.userInfo?["actionType"] as? String, actionType == "authStateLoaded" {
                authStateLoadedNotifications.append(notification)
                if !expectationFulfilled {
                    expectationFulfilled = true
                    expectation.fulfill()
                }
            }
        }

        // Act
        await auth.retrieveStoredCredentials()

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(authStateLoadedNotifications.isEmpty, "AuthStateLoaded notification should be posted")

        let receivedNotification = authStateLoadedNotifications.first!
        XCTAssertEqual(receivedNotification.name, .EcosiaAuthStateChanged, "Should receive auth state changed notification")

        let authState = receivedNotification.userInfo?["authState"] as? AuthWindowState
        XCTAssertNotNil(authState, "Notification should contain auth state")
        XCTAssertFalse(authState?.isLoggedIn == true, "Auth state should not be logged in")
        XCTAssertEqual(authState?.windowUUID, testWindowUUID, "Auth state should be for correct window")
    }

    // MARK: - Multi-Window Integration Tests

    func testLogin_withMultipleWindows_dispatchesToAllWindows() async {
        // Arrange
        let windowUUID2 = WindowUUID()
        let windowUUID3 = WindowUUID()

        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)

        let expectedCredentials = createTestCredentials()
        mockProvider.mockCredentials = expectedCredentials

        var notificationCount = 0
        let expectation = expectation(description: "Auth state notifications should be posted for all windows")
        expectation.expectedFulfillmentCount = 3 // 3 windows

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            notificationCount += 1
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(notificationCount, 3, "Should receive notifications for all registered windows")

        // Verify all windows have auth state
        let authState1 = authStateManager.getAuthState(for: testWindowUUID)
        let authState2 = authStateManager.getAuthState(for: windowUUID2)
        let authState3 = authStateManager.getAuthState(for: windowUUID3)

        XCTAssertNotNil(authState1, "Window 1 should have auth state")
        XCTAssertNotNil(authState2, "Window 2 should have auth state")
        XCTAssertNotNil(authState3, "Window 3 should have auth state")

        XCTAssertTrue(authState1?.isLoggedIn == true, "Window 1 should be logged in")
        XCTAssertTrue(authState2?.isLoggedIn == true, "Window 2 should be logged in")
        XCTAssertTrue(authState3?.isLoggedIn == true, "Window 3 should be logged in")
    }

    func testLogout_withMultipleWindows_dispatchesToAllWindows() async {
        // Arrange
        let windowUUID2 = WindowUUID()
        let windowUUID3 = WindowUUID()

        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)

        await setupLoggedInState()

        var notificationCount = 0
        let expectation = expectation(description: "Auth state notifications should be posted for all windows")
        expectation.expectedFulfillmentCount = 3 // 3 windows

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            notificationCount += 1
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(notificationCount, 3, "Should receive notifications for all registered windows")

        // Verify all windows have logged out state
        let authState1 = authStateManager.getAuthState(for: testWindowUUID)
        let authState2 = authStateManager.getAuthState(for: windowUUID2)
        let authState3 = authStateManager.getAuthState(for: windowUUID3)

        XCTAssertNotNil(authState1, "Window 1 should have auth state")
        XCTAssertNotNil(authState2, "Window 2 should have auth state")
        XCTAssertNotNil(authState3, "Window 3 should have auth state")

        XCTAssertFalse(authState1?.isLoggedIn == true, "Window 1 should be logged out")
        XCTAssertFalse(authState2?.isLoggedIn == true, "Window 2 should be logged out")
        XCTAssertFalse(authState3?.isLoggedIn == true, "Window 3 should be logged out")
    }

    // MARK: - Error Handling Integration Tests

    func testLogin_withStateManagerError_stillUpdatesAuthState() async {
        // Arrange
        let expectedCredentials = createTestCredentials()
        mockProvider.mockCredentials = expectedCredentials

        // Remove window from registry to simulate error scenario
        windowRegistry.clearAllWindows()

        // Act
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert
        XCTAssertTrue(auth.isLoggedIn, "Auth should still be logged in despite state manager issues")
        XCTAssertNotNil(auth.idToken, "Should have ID token")
        XCTAssertNotNil(auth.accessToken, "Should have access token")
        XCTAssertNotNil(auth.refreshToken, "Should have refresh token")
    }

    // MARK: - Helper Methods

    private func setupLoggedInState() async {
        let credentials = createTestCredentials()
        mockProvider.mockCredentials = credentials
        mockProvider.hasStoredCredentials = true

        do {
            try await auth.login()
        } catch {
            XCTFail("Setup failed: \(error)")
        }
    }

    private func createTestCredentials() -> Credentials {
        return Credentials(
            accessToken: "test-access-token",
            tokenType: "Bearer",
            idToken: "test-id-token",
            refreshToken: "test-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }
}
