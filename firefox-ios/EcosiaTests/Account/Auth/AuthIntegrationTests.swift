// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Auth0
import Ecosia
@testable import Client

final class AuthIntegrationTests: XCTestCase {

    var ecosiaAuth: EcosiaAuth!
    var authStateManager: AuthStateManager!
    var mockBrowserViewController: MockBrowserViewController!

    override func setUp() {
        super.setUp()
        authStateManager = AuthStateManager()
        mockBrowserViewController = MockBrowserViewController()
        ecosiaAuth = EcosiaAuth(
            browserViewController: mockBrowserViewController,
            authProvider: Ecosia.Auth.shared,
            authStateManager: authStateManager
        )
    }

    override func tearDown() {
        authStateManager.reset()
        authStateManager = nil
        ecosiaAuth = nil
        mockBrowserViewController = nil
        super.tearDown()
    }

    // MARK: - Full Authentication Lifecycle Tests

    func testCompleteAuthenticationLifecycle_loginLogout_worksEndToEnd() {
        // Arrange
        XCTAssertFalse(ecosiaAuth.isLoggedIn, "Should start logged out")
        XCTAssertEqual(authStateManager.currentState, .idle)

        // Act - Login flow (testing chainable API)
        let loginFlow = ecosiaAuth.login()
        XCTAssertNotNil(loginFlow)

        // Simulate successful authentication for state testing
        let testUser = AuthUser(idToken: "test-id-token", accessToken: "test-access-token")
        authStateManager.completeAuthentication(with: testUser)

        // Assert - Logged in state
        XCTAssertTrue(ecosiaAuth.isLoggedIn, "Should be logged in after successful login")
        XCTAssertEqual(ecosiaAuth.idToken, testUser.idToken)
        XCTAssertEqual(ecosiaAuth.accessToken, testUser.accessToken)
        XCTAssertEqual(authStateManager.currentState, .authenticated(user: testUser))

        // Act - Logout flow
        let logoutFlow = ecosiaAuth.logout()
        XCTAssertNotNil(logoutFlow)

        // Simulate successful logout for state testing
        authStateManager.completeLogout()

        // Assert - Logged out state
        XCTAssertFalse(ecosiaAuth.isLoggedIn, "Should be logged out after logout")
        XCTAssertNil(ecosiaAuth.idToken, "ID token should be cleared")
        XCTAssertNil(ecosiaAuth.accessToken, "Access token should be cleared")
        XCTAssertEqual(authStateManager.currentState, .loggedOut)
    }

    func testAuthenticationFlow_withChainedAPI() {
        // Arrange
        var nativeAuthCompletedCalled = false
        var authFlowCompletedCalled = false
        var errorCalled = false

        // Act - Use chainable API
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
        // Callbacks are set up for the authentication flow
        // Actual invocation depends on the real Ecosia.Auth behavior
    }

    func testErrorHandling_authenticationFailure_maintainsProperState() {
        // Arrange
        let expectedError = AuthError.userCancelled
        XCTAssertEqual(authStateManager.currentState, .idle)

        // Act - Simulate authentication failure
        authStateManager.beginAuthentication()
        authStateManager.failAuthentication(with: expectedError)

        // Assert
        XCTAssertFalse(ecosiaAuth.isLoggedIn)
        XCTAssertEqual(authStateManager.currentState, .authenticationFailed(error: expectedError))
        XCTAssertNil(authStateManager.currentUser)
    }

    func testErrorHandling_duringLogout_maintainsProperState() {
        // Arrange - Setup logged in state
        let testUser = AuthUser(idToken: "logout-test-id", accessToken: "logout-test-access")
        authStateManager.completeAuthentication(with: testUser)
        XCTAssertTrue(ecosiaAuth.isLoggedIn)

        // Act - Start logout flow
        let logoutFlow = ecosiaAuth.logout()
        XCTAssertNotNil(logoutFlow)

        // Simulate logout being initiated but not completed
        authStateManager.beginLogout()

        // Assert - Should be in logging out state
        XCTAssertEqual(authStateManager.currentState, .loggingOut)
        XCTAssertFalse(authStateManager.isAuthenticated) // isAuthenticated should be false during logout
    }

    func testMemoryManagement_authInstanceDeallocation_cleansUpCorrectly() {
        // Arrange
        weak var weakEcosiaAuth: EcosiaAuth?
        weak var weakAuthStateManager: AuthStateManager?
        
        do {
            let tempAuthStateManager = AuthStateManager()
            let tempBrowserViewController = MockBrowserViewController()
            let tempEcosiaAuth = EcosiaAuth(
                browserViewController: tempBrowserViewController,
                authProvider: Ecosia.Auth.shared,
                authStateManager: tempAuthStateManager
            )
            
            weakEcosiaAuth = tempEcosiaAuth
            weakAuthStateManager = tempAuthStateManager
            
            // Use the instances
            XCTAssertNotNil(weakEcosiaAuth)
            XCTAssertNotNil(weakAuthStateManager)
            
            // Setup auth state
            let testUser = AuthUser(idToken: "test-id", accessToken: "test-access")
            tempAuthStateManager.completeAuthentication(with: testUser)
            XCTAssertTrue(tempEcosiaAuth.isLoggedIn)
            
            // tempEcosiaAuth and tempAuthStateManager should be deallocated here
        }
        
        // Assert - Instances should be deallocated
        XCTAssertNil(weakEcosiaAuth, "EcosiaAuth should be deallocated")
        XCTAssertNil(weakAuthStateManager, "AuthStateManager should be deallocated")
    }

    func testAuthenticationStatus_withAuthenticatedState_reflectsCorrectly() {
        // Arrange
        let testUser = AuthUser(idToken: "status-id", accessToken: "status-access")
        XCTAssertEqual(authStateManager.currentState, .idle)

        // Act
        authStateManager.completeAuthentication(with: testUser)

        // Assert
        XCTAssertTrue(ecosiaAuth.isLoggedIn)
        XCTAssertEqual(authStateManager.currentState, .authenticated(user: testUser))
        XCTAssertEqual(ecosiaAuth.idToken, testUser.idToken)
        XCTAssertEqual(ecosiaAuth.accessToken, testUser.accessToken)
    }

    func testAuthenticationStatus_withLoggedOutState_reflectsCorrectly() {
        // Arrange
        authStateManager.completeLogout()

        // Act & Assert
        XCTAssertFalse(ecosiaAuth.isLoggedIn)
        XCTAssertEqual(authStateManager.currentState, .loggedOut)
        XCTAssertNil(ecosiaAuth.idToken)
        XCTAssertNil(ecosiaAuth.accessToken)
    }

    func testConcurrentAuthOperations_handlesGracefully() {
        // Arrange
        let testUser = AuthUser(idToken: "concurrent-id", accessToken: "concurrent-access")

        // Act - Create multiple flows (testing that it doesn't crash)
        let loginFlow1 = ecosiaAuth.login()
        let loginFlow2 = ecosiaAuth.login()
        let loginFlow3 = ecosiaAuth.login()

        // Assert - Should handle gracefully without crashing
        XCTAssertNotNil(loginFlow1)
        XCTAssertNotNil(loginFlow2)
        XCTAssertNotNil(loginFlow3)
        
        // Simulate one successful authentication
        authStateManager.completeAuthentication(with: testUser)
        XCTAssertTrue(ecosiaAuth.isLoggedIn)
        XCTAssertEqual(authStateManager.currentState, .authenticated(user: testUser))
    }

    func testStateTransitions_followCorrectSequence() {
        // Arrange
        let observer = MockAuthStateObserver()
        authStateManager.addObserver(observer)
        defer { authStateManager.removeObserver(observer) }

        let testUser = AuthUser(idToken: "sequence-id", accessToken: "sequence-access")

        // Act - Login sequence
        authStateManager.beginAuthentication()
        authStateManager.completeAuthentication(with: testUser)

        // Assert - Should see proper state sequence
        XCTAssertTrue(observer.stateChanges.count >= 2)
        
        // Should start with idle -> authenticating
        let firstChange = observer.stateChanges.first!
        XCTAssertEqual(firstChange.previousState, .idle)
        XCTAssertEqual(firstChange.currentState, .authenticating)
        
        // Should end with authenticated
        let lastChange = observer.stateChanges.last!
        XCTAssertEqual(lastChange.currentState, .authenticated(user: testUser))

        // Reset observer for logout test
        observer.reset()

        // Act - Logout sequence
        authStateManager.beginLogout()
        authStateManager.completeLogout()

        // Assert - Should see logout sequence
        XCTAssertTrue(observer.stateChanges.count >= 2)
        
        // Should end with logged out
        let logoutChange = observer.stateChanges.last!
        XCTAssertEqual(logoutChange.currentState, .loggedOut)
    }

    func testChainableAPI_multipleCalls_worksCorrectly() {
        // Arrange & Act
        let flow = ecosiaAuth.login()
            .onNativeAuthCompleted {
                // Native auth completed
            }
            .onAuthFlowCompleted { success in
                // Flow completed
            }
            .onError { error in
                // Error occurred
            }

        // Assert
        XCTAssertNotNil(flow)
        
        // Test logout chain as well
        let logoutFlow = ecosiaAuth.logout()
            .onNativeAuthCompleted {
                // Native logout completed
            }
            .onAuthFlowCompleted { success in
                // Logout flow completed
            }
            .onError { error in
                // Logout error occurred
            }

        XCTAssertNotNil(logoutFlow)
    }

    func testStateManager_multipleOperations_maintainsConsistency() {
        // Arrange
        let testUser = AuthUser(idToken: "consistency-id", accessToken: "consistency-access")

        // Act - Multiple rapid state changes
        authStateManager.beginAuthentication()
        XCTAssertEqual(authStateManager.currentState, .authenticating)
        
        authStateManager.completeAuthentication(with: testUser)
        XCTAssertEqual(authStateManager.currentState, .authenticated(user: testUser))
        XCTAssertTrue(ecosiaAuth.isLoggedIn)
        
        authStateManager.beginLogout()
        XCTAssertEqual(authStateManager.currentState, .loggingOut)
        XCTAssertFalse(authStateManager.isAuthenticated)
        
        authStateManager.completeLogout()
        XCTAssertEqual(authStateManager.currentState, .loggedOut)
        XCTAssertFalse(ecosiaAuth.isLoggedIn)

        // Assert - Final state consistency
        XCTAssertFalse(ecosiaAuth.isLoggedIn)
        XCTAssertNil(ecosiaAuth.idToken)
        XCTAssertNil(ecosiaAuth.accessToken)
        XCTAssertEqual(ecosiaAuth.currentAuthState, .loggedOut)
    }
}

// MARK: - Mock Browser View Controller

private class MockBrowserViewController: BrowserViewController {
    // Minimal mock for testing - most functionality not needed for integration tests
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
