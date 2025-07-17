// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
@testable import Client

final class AuthStateManagerTests: XCTestCase {

    var authStateManager: AuthStateManager!
    fileprivate var mockNotificationCenter: MockNotificationCenter!

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
        XCTAssertFalse(authStateManager.isLoggingOut)
    }

    func testCompleteAuthentication() {
        let user = AuthUser(idToken: "test-id-token", accessToken: "test-access-token")

        authStateManager.completeAuthentication(with: user)

        XCTAssertEqual(authStateManager.currentState, .authenticated(user: user))
        XCTAssertTrue(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isAuthenticating)
        XCTAssertFalse(authStateManager.isLoggingOut)
        XCTAssertEqual(authStateManager.currentUser, user)
    }

    func testFailAuthentication() {
        let error = AuthError.networkError("Connection failed")

        authStateManager.failAuthentication(with: error)

        XCTAssertEqual(authStateManager.currentState, .authenticationFailed(error: error))
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isAuthenticating)
        XCTAssertFalse(authStateManager.isLoggingOut)
        XCTAssertNil(authStateManager.currentUser)
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
        XCTAssertFalse(authStateManager.isAuthenticating)
        XCTAssertNil(authStateManager.currentUser) // User is cleared during logout
    }

    func testCompleteLogout() {
        authStateManager.completeLogout()

        XCTAssertEqual(authStateManager.currentState, .loggedOut)
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertFalse(authStateManager.isLoggingOut)
        XCTAssertFalse(authStateManager.isAuthenticating)
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
        XCTAssertFalse(authStateManager.isLoggingOut)
        XCTAssertNil(authStateManager.currentUser)
    }

    func testUpdateAuthStateDirect() {
        let user = AuthUser(idToken: "direct-token", accessToken: "direct-access")
        let state = AuthState.authenticated(user: user)

        authStateManager.updateAuthState(state)

        XCTAssertEqual(authStateManager.currentState, state)
        XCTAssertTrue(authStateManager.isAuthenticated)
        XCTAssertEqual(authStateManager.currentUser, user)
    }

    // MARK: - Observer Tests

    func testAddObserver_receivesStateUpdates() {
        let mockObserver = MockAuthStateObserver()

        authStateManager.addObserver(mockObserver)
        authStateManager.beginAuthentication()

        XCTAssertEqual(mockObserver.stateChanges.count, 1)
        XCTAssertEqual(mockObserver.stateChanges.first?.currentState, .authenticating)
        XCTAssertEqual(mockObserver.stateChanges.first?.previousState, .idle)
    }

    func testMultipleObservers_allReceiveUpdates() {
        let observer1 = MockAuthStateObserver()
        let observer2 = MockAuthStateObserver()

        authStateManager.addObserver(observer1)
        authStateManager.addObserver(observer2)

        authStateManager.beginAuthentication()

        XCTAssertEqual(observer1.stateChanges.count, 1)
        XCTAssertEqual(observer2.stateChanges.count, 1)
        
        for observer in [observer1, observer2] {
            XCTAssertEqual(observer.stateChanges.first?.currentState, .authenticating)
            XCTAssertEqual(observer.stateChanges.first?.previousState, .idle)
        }
    }

    func testRemoveObserver_stopsReceivingUpdates() {
        let mockObserver = MockAuthStateObserver()

        authStateManager.addObserver(mockObserver)
        authStateManager.removeObserver(mockObserver)

        authStateManager.beginAuthentication()

        XCTAssertEqual(mockObserver.stateChanges.count, 0)
    }

    func testWeakObserverReferences_cleanupDeallocatedObservers() {
        var mockObserver: MockAuthStateObserver? = MockAuthStateObserver()

        authStateManager.addObserver(mockObserver!)

        // Release the observer
        mockObserver = nil

        authStateManager.beginAuthentication()

        // The observer should have been cleaned up and not cause any issues
        XCTAssertEqual(authStateManager.currentState, .authenticating)
    }

    // MARK: - Legacy Notification Tests

    func testLegacyNotifications_postedForStateChanges() {
        authStateManager.beginAuthentication()

        XCTAssertEqual(mockNotificationCenter.postedNotifications.count, 1)
        let notification = mockNotificationCenter.postedNotifications.first
        XCTAssertEqual(notification?.name, .EcosiaAuthStateChanged)
        XCTAssertEqual(notification?.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String, 
                      EcosiaAuthConstants.State.authenticationStarted.rawValue)
    }

    func testLegacyNotifications_userLoggedIn() {
        let user = AuthUser(idToken: "test-token", accessToken: "test-access")
        authStateManager.completeAuthentication(with: user)

        let notification = mockNotificationCenter.postedNotifications.last
        XCTAssertEqual(notification?.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String,
                      EcosiaAuthConstants.State.userLoggedIn.rawValue)
    }

    func testLegacyNotifications_authenticationFailed() {
        let error = AuthError.userCancelled
        authStateManager.failAuthentication(with: error)

        let notification = mockNotificationCenter.postedNotifications.last
        XCTAssertEqual(notification?.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String,
                      EcosiaAuthConstants.State.authenticationFailed.rawValue)
    }

    func testLegacyNotifications_userLoggedOut() {
        authStateManager.completeLogout()

        let notification = mockNotificationCenter.postedNotifications.last
        XCTAssertEqual(notification?.userInfo?[EcosiaAuthConstants.Keys.actionType] as? String,
                      EcosiaAuthConstants.State.userLoggedOut.rawValue)
    }

    func testLegacyNotifications_noNotificationForIdleAndLoggingOut() {
        authStateManager.reset()
        authStateManager.beginLogout()

        // Should not post notifications for idle and loggingOut states
        XCTAssertTrue(mockNotificationCenter.postedNotifications.isEmpty)
    }

    // MARK: - Complex State Transition Tests

    func testCompleteAuthenticationWorkflow() {
        let user = AuthUser(idToken: "workflow-token", accessToken: "workflow-access")
        let mockObserver = MockAuthStateObserver()
        authStateManager.addObserver(mockObserver)

        // Full workflow: idle -> authenticating -> authenticated -> loggingOut -> loggedOut
        authStateManager.beginAuthentication()
        authStateManager.completeAuthentication(with: user)
        authStateManager.beginLogout()
        authStateManager.completeLogout()

        XCTAssertEqual(mockObserver.stateChanges.count, 4)
        XCTAssertEqual(mockObserver.stateChanges[0].currentState, .authenticating)
        XCTAssertEqual(mockObserver.stateChanges[1].currentState, .authenticated(user: user))
        XCTAssertEqual(mockObserver.stateChanges[2].currentState, .loggingOut)
        XCTAssertEqual(mockObserver.stateChanges[3].currentState, .loggedOut)
    }

    func testFailedAuthenticationWorkflow() {
        let error = AuthError.networkError("Test error")
        let mockObserver = MockAuthStateObserver()
        authStateManager.addObserver(mockObserver)

        authStateManager.beginAuthentication()
        authStateManager.failAuthentication(with: error)
        authStateManager.reset()

        XCTAssertEqual(mockObserver.stateChanges.count, 3)
        XCTAssertEqual(mockObserver.stateChanges[0].currentState, .authenticating)
        XCTAssertEqual(mockObserver.stateChanges[1].currentState, .authenticationFailed(error: error))
        XCTAssertEqual(mockObserver.stateChanges[2].currentState, .idle)
    }
}

// MARK: - Mock Objects

private class MockAuthStateObserver: AuthStateObserver {
    struct StateChange {
        let currentState: AuthState
        let previousState: AuthState
    }

    var stateChanges: [StateChange] = []

    func authStateDidChange(_ state: AuthState, previousState: AuthState) {
        stateChanges.append(StateChange(currentState: state, previousState: previousState))
    }
}

fileprivate class MockNotificationCenter: NotificationCenter, @unchecked Sendable {
    struct PostedNotification {
        let name: Notification.Name
        let object: Any?
        let userInfo: [AnyHashable: Any]?
    }

    var postedNotifications: [PostedNotification] = []

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        postedNotifications.append(PostedNotification(name: aName, object: anObject, userInfo: aUserInfo))
    }
}
