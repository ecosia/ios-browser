// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia
@testable import Client

final class EcosiaAuthTests: XCTestCase {

    var mockAuth: MockAuth!
    var mockInvisibleTabAPI: MockInvisibleTabAPI!
    var mockNotificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()
        mockAuth = MockAuth()
        mockInvisibleTabAPI = MockInvisibleTabAPI()
        mockNotificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        mockAuth = nil
        mockInvisibleTabAPI = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    // MARK: - Login Flow Tests

    func testLogin_createsFlowWithCorrectType() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            authProvider: mockAuth,
            invisibleTabAPI: mockInvisibleTabAPI,
            notificationCenter: mockNotificationCenter
        )

        // When
        let flow = ecosiaAuth.login()

        // Then
        XCTAssertEqual(flow.type, .login)
        XCTAssertTrue(mockAuth.loginCalled)
    }

    func testLogin_onNativeAuthCompleted_triggersCallback() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            authProvider: mockAuth,
            invisibleTabAPI: mockInvisibleTabAPI,
            notificationCenter: mockNotificationCenter
        )
        var nativeAuthCallbackTriggered = false

        // When
        let flow = ecosiaAuth.login()
            .onNativeAuthCompleted {
                nativeAuthCallbackTriggered = true
            }

        // Simulate Auth0 completion
        mockAuth.simulateLoginSuccess()

        // Then
        XCTAssertTrue(nativeAuthCallbackTriggered)
        XCTAssertTrue(mockInvisibleTabAPI.createInvisibleTabsCalled)
    }

    func testLogin_onAuthFlowCompleted_triggersAfterTabsClose() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            authProvider: mockAuth,
            invisibleTabAPI: mockInvisibleTabAPI,
            notificationCenter: mockNotificationCenter
        )
        var authFlowCompletedCalled = false
        var authFlowSuccess: Bool?

        // When
        let flow = ecosiaAuth.login()
            .onAuthFlowCompleted { success in
                authFlowCompletedCalled = true
                authFlowSuccess = success
            }

        // Simulate complete flow: Auth0 → invisible tabs → auto-close
        mockAuth.simulateLoginSuccess()
        mockNotificationCenter.simulateNotification(
            name: .EcosiaAuthStateChanged,
            userInfo: [
                EcosiaAuthConstants.Keys.actionType: EcosiaAuthConstants.State.userLoggedIn.rawValue,
                EcosiaAuthConstants.Keys.windowUUID: WindowUUID.XCTestDefaultUUID.uuidString
            ]
        )

        // Then
        XCTAssertTrue(authFlowCompletedCalled)
        XCTAssertEqual(authFlowSuccess, true)
    }

    // MARK: - Logout Flow Tests

    func testLogout_createsFlowWithCorrectType() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            authProvider: mockAuth,
            invisibleTabAPI: mockInvisibleTabAPI,
            notificationCenter: mockNotificationCenter
        )

        // When
        let flow = ecosiaAuth.logout()

        // Then
        XCTAssertEqual(flow.type, .logout)
        XCTAssertTrue(mockAuth.logoutCalled)
    }

    func testLogout_onNativeAuthCompleted_triggersCallback() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            authProvider: mockAuth,
            invisibleTabAPI: mockInvisibleTabAPI,
            notificationCenter: mockNotificationCenter
        )
        var nativeAuthCallbackTriggered = false

        // When
        let flow = ecosiaAuth.logout()
            .onNativeAuthCompleted {
                nativeAuthCallbackTriggered = true
            }

        // Simulate Auth0 completion
        mockAuth.simulateLogoutSuccess()

        // Then
        XCTAssertTrue(nativeAuthCallbackTriggered)
        XCTAssertTrue(mockInvisibleTabAPI.createInvisibleTabsCalled)
    }

    // MARK: - Constants Tests

    func testEcosiaAuthConstants_keysAreDefined() {
        // Test that our constants are properly defined to avoid typos
        XCTAssertEqual(EcosiaAuthConstants.Keys.windowUUID, "windowUUID")
        XCTAssertEqual(EcosiaAuthConstants.Keys.authState, "authState")
        XCTAssertEqual(EcosiaAuthConstants.Keys.actionType, "actionType")
    }

    func testEcosiaAuthConstants_statesAreDefined() {
        // Test that our state constants are properly defined
        XCTAssertEqual(EcosiaAuthConstants.State.userLoggedIn.rawValue, "userLoggedIn")
        XCTAssertEqual(EcosiaAuthConstants.State.userLoggedOut.rawValue, "userLoggedOut")
        XCTAssertEqual(EcosiaAuthConstants.State.authenticationStarted.rawValue, "authenticationStarted")
        XCTAssertEqual(EcosiaAuthConstants.State.authenticationFailed.rawValue, "authenticationFailed")
    }

    func testEcosiaAuthConstants_statesCaseIterable() {
        // Test that we can iterate over all states
        let allStates = EcosiaAuthConstants.State.allCases
        XCTAssertEqual(allStates.count, 4)
        XCTAssertTrue(allStates.contains(.userLoggedIn))
        XCTAssertTrue(allStates.contains(.userLoggedOut))
        XCTAssertTrue(allStates.contains(.authenticationStarted))
        XCTAssertTrue(allStates.contains(.authenticationFailed))
    }

    // MARK: - Error Handling Tests

    func testLogin_authFailure_doesNotTriggerInvisibleTabs() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            authProvider: mockAuth,
            invisibleTabAPI: mockInvisibleTabAPI,
            notificationCenter: mockNotificationCenter
        )

        // When
        let flow = ecosiaAuth.login()
        mockAuth.simulateLoginFailure()

        // Then
        XCTAssertFalse(mockInvisibleTabAPI.createInvisibleTabsCalled)
    }
}

// MARK: - Mock Classes

class MockAuth: AuthProtocol {
    var isLoggedIn: Bool = false
    var loginCalled = false
    var logoutCalled = false

    private var loginCompletion: ((Result<Void, Error>) -> Void)?
    private var logoutCompletion: ((Result<Void, Error>) -> Void)?

    func login() async throws {
        loginCalled = true
        return try await withCheckedThrowingContinuation { continuation in
            loginCompletion = { result in
                continuation.resume(with: result)
            }
        }
    }

    func logout() async throws {
        logoutCalled = true
        return try await withCheckedThrowingContinuation { continuation in
            logoutCompletion = { result in
                continuation.resume(with: result)
            }
        }
    }

    func simulateLoginSuccess() {
        isLoggedIn = true
        loginCompletion?(.success(()))
    }

    func simulateLoginFailure() {
        isLoggedIn = false
        loginCompletion?(.failure(NSError(domain: "TestError", code: 1)))
    }

    func simulateLogoutSuccess() {
        isLoggedIn = false
        logoutCompletion?(.success(()))
    }
}

class MockInvisibleTabAPI {
    var createInvisibleTabsCalled = false

    func createInvisibleTabsForSessionManagement() {
        createInvisibleTabsCalled = true
    }
}

class MockNotificationCenter: NotificationCenter {
    private var observers: [(Notification.Name, Any, Selector)] = []

    override func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        if let name = aName {
            observers.append((name, observer, aSelector))
        }
    }

    override func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        observers.removeAll { _, obs, _ in
            return (obs as AnyObject) === (observer as AnyObject)
        }
    }

    func simulateNotification(name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        let notification = Notification(name: name, userInfo: userInfo)

        for (notificationName, observer, selector) in observers {
            if notificationName == name {
                (observer as AnyObject).perform(selector, with: notification)
            }
        }
    }
}
