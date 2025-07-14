// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia

final class AuthStateManagerTests: XCTestCase {

    var authStateManager: AuthStateManager!
    var windowRegistry: EcosiaAuthWindowRegistry!
    var testWindowUUID1: WindowUUID!
    var testWindowUUID2: WindowUUID!

    override func setUp() {
        super.setUp()
        authStateManager = AuthStateManager.shared
        windowRegistry = EcosiaAuthWindowRegistry.shared
        testWindowUUID1 = WindowUUID.XCTestDefaultUUID
        testWindowUUID2 = WindowUUID()

        // Clear all existing state for clean tests
        authStateManager.clearAllStates()
        windowRegistry.clearAllWindows()
    }

    override func tearDown() {
        // Clean up state after each test
        authStateManager.clearAllStates()
        windowRegistry.clearAllWindows()
        authStateManager = nil
        windowRegistry = nil
        testWindowUUID1 = nil
        testWindowUUID2 = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSharedInstance_returnsSameInstance() {
        // Arrange & Act
        let instance1 = AuthStateManager.shared
        let instance2 = AuthStateManager.shared

        // Assert
        XCTAssertTrue(instance1 === instance2, "Shared instance should return the same object")
    }

    // MARK: - State Management Tests

    func testGetAuthState_withNoState_returnsNil() {
        // Arrange
        let windowUUID = testWindowUUID1!

        // Act
        let authState = authStateManager.getAuthState(for: windowUUID)

        // Assert
        XCTAssertNil(authState, "Should return nil for non-existent window state")
    }

    func testDispatch_withAuthStateLoaded_createsNewState() {
        // Arrange
        let windowUUID = testWindowUUID1!
        let action = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: windowUUID,
            isLoggedIn: true
        )

        // Act
        authStateManager.dispatch(action: action, for: windowUUID)

        // Assert
        let authState = authStateManager.getAuthState(for: windowUUID)
        XCTAssertNotNil(authState, "State should be created after dispatch")
        XCTAssertEqual(authState?.windowUUID, windowUUID)
        XCTAssertTrue(authState?.isLoggedIn == true)
        XCTAssertTrue(authState?.authStateLoaded == true)
    }

    func testDispatch_withUserLoggedIn_updatesExistingState() {
        // Arrange
        let windowUUID = testWindowUUID1!

        // Create initial state
        let initialAction = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: windowUUID,
            isLoggedIn: false
        )
        authStateManager.dispatch(action: initialAction, for: windowUUID)

        // Act - Update with login
        let loginAction = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: windowUUID
        )
        authStateManager.dispatch(action: loginAction, for: windowUUID)

        // Assert
        let authState = authStateManager.getAuthState(for: windowUUID)
        XCTAssertNotNil(authState)
        XCTAssertTrue(authState?.isLoggedIn == true)
        XCTAssertTrue(authState?.authStateLoaded == true) // Should preserve existing state
    }

    func testDispatch_withUserLoggedOut_updatesExistingState() {
        // Arrange
        let windowUUID = testWindowUUID1!

        // Create initial logged in state
        let initialAction = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: windowUUID,
            isLoggedIn: true
        )
        authStateManager.dispatch(action: initialAction, for: windowUUID)

        // Act - Log out
        let logoutAction = AuthStateAction(
            type: .userLoggedOut,
            windowUUID: windowUUID
        )
        authStateManager.dispatch(action: logoutAction, for: windowUUID)

        // Assert
        let authState = authStateManager.getAuthState(for: windowUUID)
        XCTAssertNotNil(authState)
        XCTAssertFalse(authState?.isLoggedIn == true)
        XCTAssertFalse(authState?.authStateLoaded == true) // Should be false since initial state didn't set it
    }

    func testGetAllAuthStates_withMultipleWindows_returnsAllStates() {
        // Arrange
        let action1 = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID1,
            isLoggedIn: true
        )
        let action2 = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID2,
            isLoggedIn: false
        )

        // Act
        authStateManager.dispatch(action: action1, for: testWindowUUID1)
        authStateManager.dispatch(action: action2, for: testWindowUUID2)

        // Assert
        let allStates = authStateManager.getAllAuthStates()
        XCTAssertEqual(allStates.count, 2)
        XCTAssertNotNil(allStates[testWindowUUID1])
        XCTAssertNotNil(allStates[testWindowUUID2])
        XCTAssertTrue(allStates[testWindowUUID1]?.isLoggedIn == true)
        XCTAssertFalse(allStates[testWindowUUID2]?.isLoggedIn == true)
    }

    // MARK: - Multi-Window Dispatching Tests

    func testDispatchAuthState_withRegisteredWindows_dispatchesToAllWindows() {
        // Arrange
        windowRegistry.registerWindow(testWindowUUID1)
        windowRegistry.registerWindow(testWindowUUID2)

        // Act
        authStateManager.dispatchAuthState(isLoggedIn: true, actionType: .userLoggedIn)

        // Assert
        let state1 = authStateManager.getAuthState(for: testWindowUUID1)
        let state2 = authStateManager.getAuthState(for: testWindowUUID2)

        XCTAssertNotNil(state1, "State should be created for registered window 1")
        XCTAssertNotNil(state2, "State should be created for registered window 2")
        XCTAssertTrue(state1?.isLoggedIn == true)
        XCTAssertTrue(state2?.isLoggedIn == true)
    }

    func testDispatchAuthState_withNoRegisteredWindows_doesNotCreateStates() {
        // Arrange - No windows registered

        // Act
        authStateManager.dispatchAuthState(isLoggedIn: true, actionType: .userLoggedIn)

        // Assert
        let allStates = authStateManager.getAllAuthStates()
        XCTAssertTrue(allStates.isEmpty, "No states should be created when no windows are registered")
    }

    // MARK: - Notification Tests

    func testDispatch_postsNotificationWithCorrectUserInfo() {
        // Arrange
        let windowUUID = testWindowUUID1!
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: windowUUID,
            isLoggedIn: true
        )

        var receivedNotification: Notification?
        let expectation = expectation(description: "Notification should be posted")

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        authStateManager.dispatch(action: action, for: windowUUID)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(receivedNotification)

        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["windowUUID"] as? WindowUUID, windowUUID)
            XCTAssertEqual(userInfo["actionType"] as? String, "userLoggedIn")

            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertEqual(authState.windowUUID, windowUUID)
                XCTAssertTrue(authState.isLoggedIn)
            } else {
                XCTFail("authState should be included in userInfo")
            }
        } else {
            XCTFail("Notification should include userInfo")
        }
    }

    func testSubscribe_receivesNotifications() {
        // Arrange
        let windowUUID = testWindowUUID1!
        var notificationReceived = false
        let expectation = expectation(description: "Observer should receive notification")

        let observer = NSObject()
        authStateManager.subscribe(observer: observer, selector: #selector(NSObject.init))

        NotificationCenter.default.addObserver(forName: .EcosiaAuthStateChanged, object: authStateManager, queue: .main) { _ in
            notificationReceived = true
            expectation.fulfill()
        }

        // Act
        let action = AuthStateAction(type: .userLoggedIn, windowUUID: windowUUID, isLoggedIn: true)
        authStateManager.dispatch(action: action, for: windowUUID)

        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(notificationReceived)
    }

    // MARK: - State Cleanup Tests

    func testRemoveWindowState_removesSpecificWindowState() {
        // Arrange
        let action1 = AuthStateAction(type: .authStateLoaded, windowUUID: testWindowUUID1, isLoggedIn: true)
        let action2 = AuthStateAction(type: .authStateLoaded, windowUUID: testWindowUUID2, isLoggedIn: false)

        authStateManager.dispatch(action: action1, for: testWindowUUID1)
        authStateManager.dispatch(action: action2, for: testWindowUUID2)

        // Act
        authStateManager.removeWindowState(for: testWindowUUID1)

        // Assert
        XCTAssertNil(authStateManager.getAuthState(for: testWindowUUID1))
        XCTAssertNotNil(authStateManager.getAuthState(for: testWindowUUID2))
    }

    func testClearAllStates_removesAllWindowStates() {
        // Arrange
        let action1 = AuthStateAction(type: .authStateLoaded, windowUUID: testWindowUUID1, isLoggedIn: true)
        let action2 = AuthStateAction(type: .authStateLoaded, windowUUID: testWindowUUID2, isLoggedIn: false)

        authStateManager.dispatch(action: action1, for: testWindowUUID1)
        authStateManager.dispatch(action: action2, for: testWindowUUID2)

        // Act
        authStateManager.clearAllStates()

        // Assert
        let allStates = authStateManager.getAllAuthStates()
        XCTAssertTrue(allStates.isEmpty)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess_maintainsDataIntegrity() {
        // Arrange
        let expectation = expectation(description: "Concurrent operations should complete")
        expectation.expectedFulfillmentCount = 10

        // Act - Perform concurrent operations
        for i in 0..<10 {
            DispatchQueue.global().async {
                let windowUUID = WindowUUID()
                let action = AuthStateAction(
                    type: .authStateLoaded,
                    windowUUID: windowUUID,
                    isLoggedIn: i % 2 == 0
                )
                self.authStateManager.dispatch(action: action, for: windowUUID)
                expectation.fulfill()
            }
        }

        // Assert
        waitForExpectations(timeout: 5.0)
        let allStates = authStateManager.getAllAuthStates()
        XCTAssertEqual(allStates.count, 10, "All concurrent operations should complete successfully")
    }
}

// MARK: - Mock Classes

private class MockNotificationCenter: NotificationCenter, @unchecked Sendable {
    var postedNotifications: [Notification] = []

    override func post(_ notification: Notification) {
        postedNotifications.append(notification)
        super.post(notification)
    }

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        let notification = Notification(name: aName, object: anObject, userInfo: aUserInfo)
        postedNotifications.append(notification)
        super.post(name: aName, object: anObject, userInfo: aUserInfo)
    }
}
