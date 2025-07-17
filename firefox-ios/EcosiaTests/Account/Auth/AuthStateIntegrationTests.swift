// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
import Common
import Ecosia
@testable import Client

final class AuthStateIntegrationTests: XCTestCase {

    var ecosiaAuth: EcosiaAuth!
    var authStateManager: AuthStateManager!
    var mockObserver: MockAuthStateObserver!
    var mockBrowserViewController: MockBrowserViewController!

    override func setUp() {
        super.setUp()
        authStateManager = AuthStateManager()
        mockObserver = MockAuthStateObserver()
        mockBrowserViewController = MockBrowserViewController()
        
        ecosiaAuth = EcosiaAuth(
            browserViewController: mockBrowserViewController,
            authProvider: Ecosia.Auth.shared,
            authStateManager: authStateManager
        )
        
        authStateManager.addObserver(mockObserver)
    }

    override func tearDown() {
        authStateManager.removeObserver(mockObserver)
        authStateManager.reset()
        authStateManager = nil
        mockObserver = nil
        ecosiaAuth = nil
        mockBrowserViewController = nil
        super.tearDown()
    }

    // MARK: - Login Integration Tests

    func testLogin_startsAuthenticationFlow() {
        // Arrange
        XCTAssertEqual(authStateManager.currentState, .idle)
        XCTAssertEqual(mockObserver.stateChanges.count, 0)

        // Act
        let flow = ecosiaAuth.login()

        // Assert
        XCTAssertNotNil(flow)
        
        // Flow should be started (state may change asynchronously)
        // We test the state manager integration separately
    }

    func testLoginFlow_withCallbacks_providesChainableAPI() {
        // Arrange
        var nativeAuthCompletedCalled = false
        var authFlowCompletedCalled = false
        var errorCalled = false

        // Act
        let flow = ecosiaAuth.login()
            .onNativeAuthCompleted {
                nativeAuthCompletedCalled = true
            }
            .onAuthFlowCompleted { success in
                authFlowCompletedCalled = true
            }
            .onError { error in
                errorCalled = true
            }

        // Assert
        XCTAssertNotNil(flow)
        // Callbacks are set up (actual invocation depends on auth provider behavior)
    }

    // MARK: - Logout Integration Tests

    func testLogout_startsLogoutFlow() {
        // Arrange
        // First set up authenticated state
        let testUser = AuthUser(idToken: "test-id", accessToken: "test-access")
        authStateManager.completeAuthentication(with: testUser)
        XCTAssertTrue(authStateManager.isAuthenticated)

        // Act
        let flow = ecosiaAuth.logout()

        // Assert
        XCTAssertNotNil(flow)
        
        // Flow should be started (state may change asynchronously)
    }

    func testLogoutFlow_withCallbacks_providesChainableAPI() {
        // Arrange
        let testUser = AuthUser(idToken: "test-id", accessToken: "test-access")
        authStateManager.completeAuthentication(with: testUser)
        
        var nativeAuthCompletedCalled = false
        var authFlowCompletedCalled = false
        var errorCalled = false

        // Act
        let flow = ecosiaAuth.logout()
            .onNativeAuthCompleted {
                nativeAuthCompletedCalled = true
            }
            .onAuthFlowCompleted { success in
                authFlowCompletedCalled = true
            }
            .onError { error in
                errorCalled = true
            }

        // Assert
        XCTAssertNotNil(flow)
        // Callbacks are set up (actual invocation depends on auth provider behavior)
    }

    // MARK: - State Integration Tests

    func testLogin_withMultipleObservers_notifiesAllObservers() {
        // Arrange
        let observer2 = MockAuthStateObserver()
        let observer3 = MockAuthStateObserver()
        authStateManager.addObserver(observer2)
        authStateManager.addObserver(observer3)
        defer {
            authStateManager.removeObserver(observer2)
            authStateManager.removeObserver(observer3)
        }

        // Act - Manually trigger state change to test observer integration
        let testUser = AuthUser(idToken: "test-id", accessToken: "test-access")
        authStateManager.beginAuthentication()
        authStateManager.completeAuthentication(with: testUser)

        // Assert
        XCTAssertTrue(mockObserver.stateChanges.count >= 2)
        XCTAssertTrue(observer2.stateChanges.count >= 2)
        XCTAssertTrue(observer3.stateChanges.count >= 2)
        
        // All observers should receive the same final state
        XCTAssertEqual(mockObserver.stateChanges.last?.currentState, .authenticated(user: testUser))
        XCTAssertEqual(observer2.stateChanges.last?.currentState, .authenticated(user: testUser))
        XCTAssertEqual(observer3.stateChanges.last?.currentState, .authenticated(user: testUser))
    }

    func testStateQueries_reflectAuthStateManagerState() {
        // Arrange
        XCTAssertFalse(ecosiaAuth.isLoggedIn)
        XCTAssertNil(ecosiaAuth.idToken)
        XCTAssertNil(ecosiaAuth.accessToken)
        XCTAssertEqual(ecosiaAuth.currentAuthState, .idle)

        // Act - Set authenticated state
        let testUser = AuthUser(idToken: "query-id-token", accessToken: "query-access-token")
        authStateManager.completeAuthentication(with: testUser)

        // Assert
        XCTAssertTrue(ecosiaAuth.isLoggedIn)
        XCTAssertEqual(ecosiaAuth.idToken, testUser.idToken)
        XCTAssertEqual(ecosiaAuth.accessToken, testUser.accessToken)
        XCTAssertEqual(ecosiaAuth.currentAuthState, .authenticated(user: testUser))
    }

    func testStateTransitions_followCorrectSequence() {
        // Arrange
        XCTAssertEqual(authStateManager.currentState, .idle)

        // Act - Login sequence
        authStateManager.beginAuthentication()
        XCTAssertEqual(authStateManager.currentState, .authenticating)
        
        let testUser = AuthUser(idToken: "sequence-id", accessToken: "sequence-access")
        authStateManager.completeAuthentication(with: testUser)
        XCTAssertEqual(authStateManager.currentState, .authenticated(user: testUser))

        // Act - Logout sequence
        authStateManager.beginLogout()
        XCTAssertEqual(authStateManager.currentState, .loggingOut)
        
        authStateManager.completeLogout()
        XCTAssertEqual(authStateManager.currentState, .loggedOut)

        // Assert - Observer received all state changes
        XCTAssertTrue(mockObserver.stateChanges.count >= 4)
        
        // Verify sequence
        let states = mockObserver.stateChanges.map { $0.currentState }
        XCTAssertEqual(states[0], .authenticating)
        XCTAssertEqual(states[1], .authenticated(user: testUser))
        XCTAssertEqual(states[2], .loggingOut)
        XCTAssertEqual(states[3], .loggedOut)
    }

    func testErrorStateHandling_updatesStateCorrectly() {
        // Arrange
        let expectedError = AuthError.userCancelled

        // Act
        authStateManager.beginAuthentication()
        authStateManager.failAuthentication(with: expectedError)

        // Assert
        XCTAssertEqual(authStateManager.currentState, .authenticationFailed(error: expectedError))
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertNil(authStateManager.currentUser)
        
        // Observer should receive the error state
        XCTAssertTrue(mockObserver.stateChanges.count >= 2)
        XCTAssertEqual(mockObserver.stateChanges.last?.currentState, .authenticationFailed(error: expectedError))
    }

    func testAuthStateManager_maintainsStateAcrossOperations() {
        // Arrange
        let testUser = AuthUser(idToken: "persistent-id", accessToken: "persistent-access")
        authStateManager.completeAuthentication(with: testUser)
        let stateAfterLogin = authStateManager.currentState
        let userAfterLogin = authStateManager.currentUser

        // Act - Check that state persists
        let currentState = authStateManager.currentState
        let currentUser = authStateManager.currentUser

        // Assert
        XCTAssertEqual(currentState, stateAfterLogin)
        XCTAssertEqual(currentUser?.idToken, userAfterLogin?.idToken)
        XCTAssertEqual(currentUser?.accessToken, userAfterLogin?.accessToken)
    }

    func testConcurrentStateUpdates_handledCorrectly() {
        // Arrange
        let testUser = AuthUser(idToken: "concurrent-id", accessToken: "concurrent-access")

        // Act - Rapid state changes
        authStateManager.beginAuthentication()
        authStateManager.completeAuthentication(with: testUser)
        authStateManager.beginLogout()
        authStateManager.completeLogout()

        // Assert - Final state should be logged out
        XCTAssertEqual(authStateManager.currentState, .loggedOut)
        XCTAssertFalse(authStateManager.isAuthenticated)
        
        // Observer should receive all state changes
        XCTAssertTrue(mockObserver.stateChanges.count >= 4)
    }

    func testStateManager_reset_clearsState() {
        // Arrange
        let testUser = AuthUser(idToken: "reset-id", accessToken: "reset-access")
        authStateManager.completeAuthentication(with: testUser)
        XCTAssertTrue(authStateManager.isAuthenticated)

        // Act
        authStateManager.reset()

        // Assert
        XCTAssertEqual(authStateManager.currentState, .idle)
        XCTAssertFalse(authStateManager.isAuthenticated)
        XCTAssertNil(authStateManager.currentUser)
    }
}

// MARK: - Mock Browser View Controller

private class MockBrowserViewController: BrowserViewController {
    // Minimal mock for testing - most functionality not needed for state integration tests
    override init() {
        super.init()
    }
}

// MARK: - Mock Auth State Observer

private class MockAuthStateObserver: AuthStateObserver {
    
    struct StateChange {
        let currentState: AuthState
        let previousState: AuthState
    }
    
    var stateChanges: [StateChange] = []
    
    func authStateDidChange(_ currentState: AuthState, previousState: AuthState) {
        stateChanges.append(StateChange(currentState: currentState, previousState: previousState))
    }
    
    func reset() {
        stateChanges.removeAll()
    }
}
