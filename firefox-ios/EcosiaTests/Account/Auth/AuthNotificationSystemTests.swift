// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia

final class AuthNotificationSystemTests: XCTestCase {

    var authStateManager: AuthStateManager!
    var windowRegistry: EcosiaAuthWindowRegistry!
    var testWindowUUID: WindowUUID!
    fileprivate var notificationObserver: NotificationObserver!

    override func setUp() {
        super.setUp()
        authStateManager = AuthStateManager.shared
        windowRegistry = EcosiaAuthWindowRegistry.shared
        testWindowUUID = WindowUUID.XCTestDefaultUUID
        notificationObserver = NotificationObserver()
        
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
        notificationObserver.cleanup()
        notificationObserver = nil
        authStateManager = nil
        windowRegistry = nil
        testWindowUUID = nil
        super.tearDown()
    }

    // MARK: - Notification Names Tests

    func testNotificationNames_haveCorrectValues() {
        // Test all notification names have correct string values
        XCTAssertEqual(Notification.Name.EcosiaAuthStateChanged.rawValue, "EcosiaAuthStateChanged")
        XCTAssertEqual(Notification.Name.EcosiaAuthDidLoginWithSessionToken.rawValue, "EcosiaAuthDidLoginWithSessionToken")
        XCTAssertEqual(Notification.Name.EcosiaAuthDidLogout.rawValue, "EcosiaAuthDidLogout")
        XCTAssertEqual(Notification.Name.EcosiaAuthStateReady.rawValue, "EcosiaAuthStateReady")
        XCTAssertEqual(Notification.Name.EcosiaAuthShouldLogoutFromWeb.rawValue, "EcosiaAuthShouldLogoutFromWeb")
    }

    // MARK: - EcosiaAuthStateChanged Notification Tests

    func testEcosiaAuthStateChanged_withUserLoggedIn_postsCorrectNotification() {
        // Arrange
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        
        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 1
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)
        
        let receivedNotification = notificationObserver.receivedNotifications.first
        XCTAssertNotNil(receivedNotification, "Should receive notification")
        XCTAssertEqual(receivedNotification?.name, .EcosiaAuthStateChanged, "Should have correct notification name")
        XCTAssertTrue(receivedNotification?.object is AuthStateManager, "Should have correct object")
        
        // Verify userInfo content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["windowUUID"] as? WindowUUID, testWindowUUID, "Should include window UUID")
            XCTAssertEqual(userInfo["actionType"] as? String, "userLoggedIn", "Should include action type")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertEqual(authState.windowUUID, testWindowUUID, "Auth state should have correct window UUID")
                XCTAssertTrue(authState.isLoggedIn, "Auth state should indicate user is logged in")
            } else {
                XCTFail("Should include auth state in userInfo")
            }
        } else {
            XCTFail("Should include userInfo in notification")
        }
    }

    func testEcosiaAuthStateChanged_withUserLoggedOut_postsCorrectNotification() {
        // Arrange
        let action = AuthStateAction(
            type: .userLoggedOut,
            windowUUID: testWindowUUID,
            isLoggedIn: false
        )
        
        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 1
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)
        
        let receivedNotification = notificationObserver.receivedNotifications.first
        XCTAssertNotNil(receivedNotification, "Should receive notification")
        
        // Verify userInfo content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? String, "userLoggedOut", "Should include action type")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertFalse(authState.isLoggedIn, "Auth state should indicate user is logged out")
            } else {
                XCTFail("Should include auth state in userInfo")
            }
        } else {
            XCTFail("Should include userInfo in notification")
        }
    }

    func testEcosiaAuthStateChanged_withAuthStateLoaded_postsCorrectNotification() {
        // Arrange
        let action = AuthStateAction(
            type: .authStateLoaded,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        
        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 1
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)
        
        let receivedNotification = notificationObserver.receivedNotifications.first
        XCTAssertNotNil(receivedNotification, "Should receive notification")
        
        // Verify userInfo content
        if let userInfo = receivedNotification?.userInfo {
            XCTAssertEqual(userInfo["actionType"] as? String, "authStateLoaded", "Should include action type")
            
            if let authState = userInfo["authState"] as? AuthWindowState {
                XCTAssertTrue(authState.isLoggedIn, "Auth state should indicate user is logged in")
                XCTAssertTrue(authState.authStateLoaded, "Auth state should indicate state is loaded")
            } else {
                XCTFail("Should include auth state in userInfo")
            }
        } else {
            XCTFail("Should include userInfo in notification")
        }
    }

    // MARK: - Multi-Window Notification Tests

    func testEcosiaAuthStateChanged_withMultipleWindows_postsNotificationForEachWindow() {
        // Arrange
        let windowUUID2 = WindowUUID()
        let windowUUID3 = WindowUUID()
        
        windowRegistry.registerWindow(windowUUID2)
        windowRegistry.registerWindow(windowUUID3)
        
        notificationObserver.expectNotification(
            name: .EcosiaAuthStateChanged,
            object: authStateManager,
            expectedCount: 3
        )

        // Act
        authStateManager.dispatchAuthState(isLoggedIn: true, actionType: .userLoggedIn)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(notificationObserver.receivedNotifications.count, 3, "Should receive 3 notifications")
        
        // Verify all notifications have correct content
        let windowUUIDs = Set([testWindowUUID, windowUUID2, windowUUID3])
        var receivedWindowUUIDs = Set<WindowUUID>()
        
        for notification in notificationObserver.receivedNotifications {
            XCTAssertEqual(notification.name, .EcosiaAuthStateChanged, "Should have correct notification name")
            
            if let userInfo = notification.userInfo,
               let windowUUID = userInfo["windowUUID"] as? WindowUUID {
                receivedWindowUUIDs.insert(windowUUID)
                XCTAssertEqual(userInfo["actionType"] as? String, "userLoggedIn", "Should have correct action type")
            } else {
                XCTFail("Should include window UUID in userInfo")
            }
        }
        
        XCTAssertEqual(receivedWindowUUIDs, windowUUIDs, "Should receive notifications for all windows")
    }

    // MARK: - Notification Subscription Tests

    func testSubscribe_withObserver_receivesNotifications() {
        // Arrange
        let observer = TestNotificationObserver()
        authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))
        
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)

        // Assert
        // Give some time for the notification to be processed
        let expectation = expectation(description: "Observer should receive notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(observer.receivedNotifications.count, 1, "Observer should receive one notification")
        
        if let notification = observer.receivedNotifications.first {
            XCTAssertEqual(notification.name, .EcosiaAuthStateChanged, "Should have correct notification name")
            XCTAssertTrue(notification.object is AuthStateManager, "Should have correct object")
        }
    }

    func testUnsubscribe_withObserver_stopsReceivingNotifications() {
        // Arrange
        let observer = TestNotificationObserver()
        authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))
        
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Act
        authStateManager.dispatch(action: action, for: testWindowUUID)
        
        // Unsubscribe
        authStateManager.unsubscribe(observer: observer)
        
        // Dispatch another action
        let action2 = AuthStateAction(
            type: .userLoggedOut,
            windowUUID: testWindowUUID,
            isLoggedIn: false
        )
        authStateManager.dispatch(action: action2, for: testWindowUUID)

        // Assert
        // Give some time for the notifications to be processed
        let expectation = expectation(description: "Observer should receive limited notifications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(observer.receivedNotifications.count, 1, "Observer should receive only one notification (before unsubscribe)")
    }

    // MARK: - Legacy Notification Compatibility Tests

    func testLegacyNotificationNames_areAccessible() {
        // Test that legacy notification names are accessible
        let loginNotification = Notification.Name.EcosiaAuthDidLoginWithSessionToken
        let logoutNotification = Notification.Name.EcosiaAuthDidLogout
        let stateReadyNotification = Notification.Name.EcosiaAuthStateReady
        let shouldLogoutFromWebNotification = Notification.Name.EcosiaAuthShouldLogoutFromWeb
        
        XCTAssertNotNil(loginNotification, "Login notification should be accessible")
        XCTAssertNotNil(logoutNotification, "Logout notification should be accessible")
        XCTAssertNotNil(stateReadyNotification, "State ready notification should be accessible")
        XCTAssertNotNil(shouldLogoutFromWebNotification, "Should logout from web notification should be accessible")
    }

    func testLegacyNotificationObservation_worksWithNewSystem() {
        // Arrange
        notificationObserver.expectNotification(
            name: .EcosiaAuthDidLoginWithSessionToken,
            object: nil,
            expectedCount: 1
        )
        
        // Act - Post a legacy notification manually (simulating Auth.swift posting it)
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)

        // Assert
        notificationObserver.waitForExpectations(timeout: 1.0)
        
        let receivedNotification = notificationObserver.receivedNotifications.first
        XCTAssertNotNil(receivedNotification, "Should receive legacy notification")
        XCTAssertEqual(receivedNotification?.name, .EcosiaAuthDidLoginWithSessionToken, "Should have correct notification name")
    }

    // MARK: - Notification Performance Tests

    func testNotificationPerformance_withManyObservers() {
        // Arrange
        let observers = (0..<100).map { _ in TestNotificationObserver() }
        
        // Subscribe all observers
        for observer in observers {
            authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))
        }
        
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Act
        let startTime = Date()
        authStateManager.dispatch(action: action, for: testWindowUUID)
        let endTime = Date()

        // Assert
        XCTAssertLessThan(endTime.timeIntervalSince(startTime), 0.5, "Should post notification quickly even with many observers")
        
        // Give some time for all observers to process
        let expectation = expectation(description: "All observers should receive notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Verify all observers received the notification
        for observer in observers {
            XCTAssertEqual(observer.receivedNotifications.count, 1, "Each observer should receive one notification")
        }
    }

    func testNotificationPerformance_withManyActions() {
        // Arrange
        let observer = TestNotificationObserver()
        authStateManager.subscribe(observer: observer, selector: #selector(TestNotificationObserver.handleAuthStateChanged(_:)))
        
        let actions = (0..<100).map { i in
            AuthStateAction(
                type: i % 2 == 0 ? .userLoggedIn : .userLoggedOut,
                windowUUID: testWindowUUID,
                isLoggedIn: i % 2 == 0
            )
        }

        // Act
        let startTime = Date()
        for action in actions {
            authStateManager.dispatch(action: action, for: testWindowUUID)
        }
        let endTime = Date()

        // Assert
        XCTAssertLessThan(endTime.timeIntervalSince(startTime), 1.0, "Should dispatch many actions quickly")
        
        // Give some time for all notifications to be processed
        let expectation = expectation(description: "All notifications should be processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        XCTAssertEqual(observer.receivedNotifications.count, 100, "Observer should receive all notifications")
    }

    // MARK: - Error Handling Tests

    func testNotificationPosting_withNilObserver_doesNotCrash() {
        // Arrange
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )

        // Act & Assert - Should not crash
        XCTAssertNoThrow(authStateManager.dispatch(action: action, for: testWindowUUID))
    }

    func testNotificationPosting_withInvalidSelector_doesNotCrash() {
        // Arrange
        let observer = TestNotificationObserver()
        let invalidSelector = #selector(TestNotificationObserver.nonExistentMethod)
        
        // Act & Assert - Should not crash when subscribing with invalid selector
        XCTAssertNoThrow(authStateManager.subscribe(observer: observer, selector: invalidSelector))
        
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        
        // Should not crash when dispatching with invalid selector
        XCTAssertNoThrow(authStateManager.dispatch(action: action, for: testWindowUUID))
    }
}

// MARK: - Helper Classes

fileprivate class NotificationObserver {
    var receivedNotifications: [Notification] = []
    private var expectations: [XCTestExpectation] = []
    
    func expectNotification(name: Notification.Name, object: Any?, expectedCount: Int) {
        let expectation = XCTestExpectation(description: "Should receive \(expectedCount) notification(s) for \(name)")
        expectation.expectedFulfillmentCount = expectedCount
        expectations.append(expectation)
        
        NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] notification in
            self?.receivedNotifications.append(notification)
            expectation.fulfill()
        }
    }
    
    func waitForExpectations(timeout: TimeInterval) {
        let waiter = XCTWaiter()
        waiter.wait(for: expectations, timeout: timeout)
    }
    
    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        receivedNotifications.removeAll()
        expectations.removeAll()
    }
}

fileprivate class TestNotificationObserver: NSObject {
    var receivedNotifications: [Notification] = []
    
    @objc func handleAuthStateChanged(_ notification: Notification) {
        receivedNotifications.append(notification)
    }
    
    @objc func nonExistentMethod() {
        // This method is intentionally empty and used for testing invalid selectors
    }
} 