// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
@testable import Client

class AuthStateManagerTests: XCTestCase {
    
    var authStateManager: AuthStateManager!
    var mockNotificationCenter: MockNotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockNotificationCenter = MockNotificationCenter()
        authStateManager = AuthStateManager(notificationCenter: mockNotificationCenter)
    }
    
    override func tearDown() {
        authStateManager = nil
        mockNotificationCenter = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(authStateManager.currentState, .idle)
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isAuthenticating)
        XCTAssertFalse(authStateManager.isLoggingOut)
        XCTAssertNil(authStateManager.currentUser)
    }
    
    // MARK: - State Transition Tests
    
    func testBeginAuthentication() {
        authStateManager.beginAuthentication()
        
        XCTAssertEqual(authStateManager.currentState, .authenticating)
        XCTAssertTrue(authStateManager.isAuthenticating)
        XCTAssertFalse(authStateManager.isAuthenticated)
    }
    
    func testCompleteAuthentication() {
        let user = AuthUser(idToken: "test-id-token", accessToken: "test-access-token")
        
        authStateManager.completeAuthentication(with: user)
        
        XCTAssertEqual(authStateManager.currentState, .authenticated(user: user))
        XCTAssertTrue(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isAuthenticating)
        XCTAssertEqual(authStateManager.currentUser, user)
    }
    
    func testFailAuthentication() {
        let error = AuthError.networkError("Connection failed")
        
        authStateManager.failAuthentication(with: error)
        
        XCTAssertEqual(authStateManager.currentState, .authenticationFailed(error: error))
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isAuthenticating)
    }
    
    func testBeginLogout() {
        // First authenticate
        let user = AuthUser(idToken: "test-id", accessToken: "test-access")
        authStateManager.completeAuthentication(with: user)
        
        // Then begin logout
        authStateManager.beginLogout()
        
        XCTAssertEqual(authStateManager.currentState, .loggingOut)
        XCTAssertTrue(authStateManager.isLoggingOut)
        XCTAssertFalse(authStateManager.isAuthenticated)
    }
    
    func testCompleteLogout() {
        authStateManager.completeLogout()
        
        XCTAssertEqual(authStateManager.currentState, .loggedOut)
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isLoggingOut)
        XCTAssertNil(authStateManager.currentUser)
    }
    
    func testReset() {
        // Set some state first
        authStateManager.beginAuthentication()
        
        // Reset
        authStateManager.reset()
        
        XCTAssertEqual(authStateManager.currentState, .idle)
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isAuthenticating)
    }
    
    // MARK: - Observer Tests
    
    func testObserverNotifiedOnStateChange() {
        let mockObserver = MockAuthStateObserver()
        authStateManager.addObserver(mockObserver)
        
        authStateManager.beginAuthentication()
        
        // Give time for async notification
        let expectation = XCTestExpectation(description: "Observer notified")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockObserver.stateChanges.count, 1)
        XCTAssertEqual(mockObserver.stateChanges.first?.newState, .authenticating)
        XCTAssertEqual(mockObserver.stateChanges.first?.previousState, .idle)
    }
    
    func testMultipleObserversNotified() {
        let observer1 = MockAuthStateObserver()
        let observer2 = MockAuthStateObserver()
        
        authStateManager.addObserver(observer1)
        authStateManager.addObserver(observer2)
        
        authStateManager.beginAuthentication()
        
        // Give time for async notification
        let expectation = XCTestExpectation(description: "Observers notified")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(observer1.stateChanges.count, 1)
        XCTAssertEqual(observer2.stateChanges.count, 1)
    }
    
    func testObserverRemovedDoesNotReceiveNotifications() {
        let mockObserver = MockAuthStateObserver()
        authStateManager.addObserver(mockObserver)
        authStateManager.removeObserver(mockObserver)
        
        authStateManager.beginAuthentication()
        
        // Give time for potential notification
        let expectation = XCTestExpectation(description: "Wait for potential notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockObserver.stateChanges.isEmpty)
    }
    
    func testWeakObserverReferencesCleanedUp() {
        var mockObserver: MockAuthStateObserver? = MockAuthStateObserver()
        authStateManager.addObserver(mockObserver!)
        
        // Release the observer
        mockObserver = nil
        
        // Trigger state change to clean up weak references
        authStateManager.beginAuthentication()
        
        // This test mainly ensures no crash occurs when weak references are cleaned up
        XCTAssertEqual(authStateManager.currentState, .authenticating)
    }
    
    // MARK: - Legacy Notification Tests
    
    func testLegacyNotificationPostedForAuthenticating() {
        authStateManager.beginAuthentication()
        
        XCTAssertEqual(mockNotificationCenter.postedNotifications.count, 1)
        
        let notification = mockNotificationCenter.postedNotifications.first!
        XCTAssertEqual(notification.name, .EcosiaAuthStateChanged)
        
        let actionType = notification.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String
        XCTAssertEqual(actionType, EcosiaAuthConstants.State.authenticationStarted.rawValue)
    }
    
    func testLegacyNotificationPostedForAuthenticated() {
        let user = AuthUser(idToken: "test-id", accessToken: "test-access")
        authStateManager.completeAuthentication(with: user)
        
        XCTAssertEqual(mockNotificationCenter.postedNotifications.count, 1)
        
        let notification = mockNotificationCenter.postedNotifications.first!
        XCTAssertEqual(notification.name, .EcosiaAuthStateChanged)
        
        let actionType = notification.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String
        XCTAssertEqual(actionType, EcosiaAuthConstants.State.userLoggedIn.rawValue)
    }
    
    func testLegacyNotificationPostedForAuthenticationFailed() {
        let error = AuthError.networkError("Test error")
        authStateManager.failAuthentication(with: error)
        
        XCTAssertEqual(mockNotificationCenter.postedNotifications.count, 1)
        
        let notification = mockNotificationCenter.postedNotifications.first!
        let actionType = notification.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String
        XCTAssertEqual(actionType, EcosiaAuthConstants.State.authenticationFailed.rawValue)
    }
    
    func testLegacyNotificationPostedForLoggedOut() {
        authStateManager.completeLogout()
        
        XCTAssertEqual(mockNotificationCenter.postedNotifications.count, 1)
        
        let notification = mockNotificationCenter.postedNotifications.first!
        let actionType = notification.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String
        XCTAssertEqual(actionType, EcosiaAuthConstants.State.userLoggedOut.rawValue)
    }
    
    func testNoLegacyNotificationForIdleOrLoggingOut() {
        authStateManager.reset()
        authStateManager.beginLogout()
        
        // Only loggingOut should not post notification, reset/idle should not either
        XCTAssertTrue(mockNotificationCenter.postedNotifications.isEmpty)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentObserverOperations() {
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        let observers = (0..<10).map { _ in MockAuthStateObserver() }
        
        DispatchQueue.concurrentPerform(iterations: 10) { index in
            if index < 5 {
                authStateManager.addObserver(observers[index])
            } else {
                authStateManager.removeObserver(observers[index])
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Test passes if no crash occurs
        XCTAssertEqual(authStateManager.currentState, .idle)
    }
}

// MARK: - Mock Classes

class MockAuthStateObserver: AuthStateObserver {
    struct StateChange {
        let newState: AuthState
        let previousState: AuthState
    }
    
    var stateChanges: [StateChange] = []
    
    func authStateDidChange(_ state: AuthState, previousState: AuthState) {
        stateChanges.append(StateChange(newState: state, previousState: previousState))
    }
}

class MockNotificationCenter: NotificationCenter {
    struct PostedNotification {
        let name: Notification.Name
        let object: Any?
        let userInfo: [AnyHashable: Any]?
    }
    
    var postedNotifications: [PostedNotification] = []
    
    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        postedNotifications.append(PostedNotification(
            name: aName,
            object: anObject,
            userInfo: aUserInfo
        ))
    }
}
