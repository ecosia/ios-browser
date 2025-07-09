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
        
        // Clear state management system
        authStateManager.clearAllStates()
        windowRegistry.clearAllWindows()
        
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
        
        var receivedNotification: Notification?
        let expectation = expectation(description: "Auth state notification should be posted")
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification, "Auth state notification should be posted")
        
        // Verify notification content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? String, "userLoggedIn", "Action type should be userLoggedIn")
            XCTAssertEqual(userInfo["windowUUID"] as? WindowUUID, testWindowUUID, "Window UUID should match")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertTrue(authState.isLoggedIn, "Auth state should indicate user is logged in")
                XCTAssertEqual(authState.windowUUID, testWindowUUID, "Window UUID should match")
            } else {
                XCTFail("Auth state should be included in notification")
            }
        } else {
            XCTFail("Notification should include userInfo")
        }
        
        // Verify state manager state
        let authState = authStateManager.getAuthState(for: testWindowUUID)
        XCTAssertNotNil(authState, "Auth state should be created")
        XCTAssertTrue(authState?.isLoggedIn == true, "Auth state should indicate user is logged in")
    }

    func testLogin_withAuthFailure_doesNotDispatchUserLoggedInAction() async {
        // Arrange
        mockProvider.shouldFailAuth = true
        
        var notificationReceived = false
        let expectation = expectation(description: "No auth state notification should be posted")
        expectation.isInverted = true
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { _ in
            notificationReceived = true
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.login()
            XCTFail("Expected login to throw but it didn't")
        } catch {
            // Expected to fail
        }

        // Assert
        waitForExpectations(timeout: 0.5)
        XCTAssertFalse(notificationReceived, "No auth state notification should be posted on failed login")
        
        // Verify state manager has no state
        let authState = authStateManager.getAuthState(for: testWindowUUID)
        XCTAssertNil(authState, "Auth state should not be created on failed login")
    }

    // MARK: - Logout Integration Tests

    func testLogout_withSuccessfulLogout_dispatchesUserLoggedOutAction() async {
        // Arrange
        await setupLoggedInState()
        
        var receivedNotification: Notification?
        let expectation = expectation(description: "Auth state notification should be posted")
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification, "Auth state notification should be posted")
        
        // Verify notification content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? String, "userLoggedOut", "Action type should be userLoggedOut")
            XCTAssertEqual(userInfo["windowUUID"] as? WindowUUID, testWindowUUID, "Window UUID should match")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertFalse(authState.isLoggedIn, "Auth state should indicate user is logged out")
                XCTAssertEqual(authState.windowUUID, testWindowUUID, "Window UUID should match")
            } else {
                XCTFail("Auth state should be included in notification")
            }
        } else {
            XCTFail("Notification should include userInfo")
        }
        
        // Verify state manager state
        let authState = authStateManager.getAuthState(for: testWindowUUID)
        XCTAssertNotNil(authState, "Auth state should exist")
        XCTAssertFalse(authState?.isLoggedIn == true, "Auth state should indicate user is logged out")
    }

    func testLogout_withoutTriggerWebLogout_stillDispatchesUserLoggedOutAction() async {
        // Arrange
        await setupLoggedInState()
        
        var receivedNotification: Notification?
        let expectation = expectation(description: "Auth state notification should be posted")
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.logout(triggerWebLogout: false)
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification, "Auth state notification should be posted even without web logout")
        
        // Verify notification content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? String, "userLoggedOut", "Action type should be userLoggedOut")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertFalse(authState.isLoggedIn, "Auth state should indicate user is logged out")
            } else {
                XCTFail("Auth state should be included in notification")
            }
        } else {
            XCTFail("Notification should include userInfo")
        }
    }

    // MARK: - Credential Retrieval Integration Tests

    func testRetrieveStoredCredentials_withValidCredentials_dispatchesAuthStateLoadedAction() async {
        // Arrange
        let expectedCredentials = createTestCredentials()
        mockProvider.mockCredentials = expectedCredentials
        mockProvider.hasStoredCredentials = true
        
        var receivedNotification: Notification?
        let expectation = expectation(description: "Auth state notification should be posted")
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        await auth.retrieveStoredCredentials()

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification, "Auth state notification should be posted")
        
        // Verify notification content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? String, "authStateLoaded", "Action type should be authStateLoaded")
            XCTAssertEqual(userInfo["windowUUID"] as? WindowUUID, testWindowUUID, "Window UUID should match")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertTrue(authState.isLoggedIn, "Auth state should indicate user is logged in")
                XCTAssertTrue(authState.authStateLoaded, "Auth state should indicate state is loaded")
                XCTAssertEqual(authState.windowUUID, testWindowUUID, "Window UUID should match")
            } else {
                XCTFail("Auth state should be included in notification")
            }
        } else {
            XCTFail("Notification should include userInfo")
        }
    }

    func testRetrieveStoredCredentials_withNoCredentials_dispatchesAuthStateLoadedWithLoggedOutState() async {
        // Arrange
        mockProvider.hasStoredCredentials = false
        mockProvider.shouldFailRetrieveCredentials = true
        
        var receivedNotification: Notification?
        let expectation = expectation(description: "Auth state notification should be posted")
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        await auth.retrieveStoredCredentials()

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification, "Auth state notification should be posted")
        
        // Verify notification content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? String, "authStateLoaded", "Action type should be authStateLoaded")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertFalse(authState.isLoggedIn, "Auth state should indicate user is logged out")
                XCTAssertTrue(authState.authStateLoaded, "Auth state should indicate state is loaded")
            } else {
                XCTFail("Auth state should be included in notification")
            }
        } else {
            XCTFail("Notification should include userInfo")
        }
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
        waitForExpectations(timeout: 1.0)
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
        waitForExpectations(timeout: 1.0)
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

    // MARK: - Legacy Notification Integration Tests

    func testLogin_withSuccessfulAuth_postsLegacyNotification() async {
        // Arrange
        let expectedCredentials = createTestCredentials()
        mockProvider.mockCredentials = expectedCredentials
        
        var receivedNotification: Notification?
        let expectation = expectation(description: "Legacy auth notification should be posted")
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthDidLoginWithSessionToken, object: nil, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.login()
        } catch {
            XCTFail("Login should succeed, but failed with: \(error)")
        }

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification, "Legacy auth notification should be posted")
    }

    func testLogout_withSuccessfulLogout_postsLegacyNotification() async {
        // Arrange
        await setupLoggedInState()
        
        var receivedNotification: Notification?
        let expectation = expectation(description: "Legacy auth notification should be posted")
        
        NotificationCenter.default.addObserver(forName: .EcosiaAuthDidLogout, object: nil, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        do {
            try await auth.logout()
        } catch {
            XCTFail("Logout should succeed, but failed with: \(error)")
        }

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification, "Legacy auth notification should be posted")
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