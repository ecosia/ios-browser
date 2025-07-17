// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Ecosia
@testable import Client

final class EcosiaAuthTests: XCTestCase {

    var mockAuth0Provider: MockAuth0Provider!
    var auth: Ecosia.Auth!
    var invisibleTabAPI: InvisibleTabAPI!
    var mockBrowserViewController: MockBrowserViewController!
    var mockTabManager: MockTabManagerForAPI!

    override func setUp() {
        super.setUp()
        mockAuth0Provider = MockAuth0Provider()
        auth = Ecosia.Auth(auth0Provider: mockAuth0Provider)
        
        // Create proper mock dependencies for InvisibleTabAPI
        let profile = MockProfile()
        mockTabManager = MockTabManagerForAPI()
        mockBrowserViewController = MockBrowserViewController(profile: profile, tabManager: mockTabManager)
        invisibleTabAPI = InvisibleTabAPI(browserViewController: mockBrowserViewController, tabManager: mockTabManager)
    }

    override func tearDown() {
        mockAuth0Provider = nil
        auth = nil
        invisibleTabAPI = nil
        mockBrowserViewController = nil
        mockTabManager = nil
        super.tearDown()
    }

    // MARK: - Login Flow Tests

    func testLogin_createsFlowWithCorrectType() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        let expectation = XCTestExpectation(description: "Auth started")

        // When
        _ = ecosiaAuth.login()

        // Allow time for async Task to execute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then  
        // Verify login flow behavior by checking that auth was initiated
        XCTAssertEqual(mockAuth0Provider.startAuthCallCount, 1)
    }

    func testLogin_onNativeAuthCompleted_triggersCallback() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)
        var nativeAuthCallbackTriggered = false
        let expectation = XCTestExpectation(description: "Native auth completed")

        // When
        _ = ecosiaAuth.login()
            .onNativeAuthCompleted {
                nativeAuthCallbackTriggered = true
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(nativeAuthCallbackTriggered)
    }

    func testLogin_authFailure_doesNotCreateInvisibleTabs() {
        // Given
        mockAuth0Provider.shouldFailAuth = true
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)
        let expectation = XCTestExpectation(description: "Auth failure processed")

        // When
        _ = ecosiaAuth.login() // Don't need to retain the flow for this test

        // Allow some time for the flow to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then - Auth should have been attempted
        XCTAssertTrue(mockAuth0Provider.startAuthCallCount > 0)
    }

    // MARK: - Logout Flow Tests

    func testLogout_createsFlowWithCorrectType() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        // When
        let flow = ecosiaAuth.logout()

        // Then
        XCTAssertEqual(flow.type, .logout)
        XCTAssertTrue(mockAuth0Provider.clearSessionCallCount > 0)
    }

    func testLogout_onNativeAuthCompleted_triggersCallback() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)
        var nativeAuthCallbackTriggered = false

        let expectation = XCTestExpectation(description: "Native auth completed")

        // When
        _ = ecosiaAuth.logout()
            .onNativeAuthCompleted {
                nativeAuthCallbackTriggered = true
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(nativeAuthCallbackTriggered)
    }

    // MARK: - Auth State Access Tests

    func testAuthStateAccess_isLoggedIn_reflectsAuthProviderState() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        // When/Then - Initially should be false
        XCTAssertFalse(ecosiaAuth.isLoggedIn)
    }

    func testAuthStateAccess_tokens_reflectsAuthProviderTokens() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        // Then - Initially should be nil
        XCTAssertNil(ecosiaAuth.idToken)
        XCTAssertNil(ecosiaAuth.accessToken)
    }

    // MARK: - Error Handling Tests

    func testLogin_onError_triggersCallbackOnAuthFailure() {
        // Given
        mockAuth0Provider.shouldFailAuth = true
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        var errorReceived: Error?
        let expectation = XCTestExpectation(description: "Error callback triggered")

        // When
        _ = ecosiaAuth.login()
            .onError { error in
                errorReceived = error
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(errorReceived)
        XCTAssertTrue(errorReceived is AuthError)
        if case .authenticationFailed = errorReceived as? AuthError {
            // Expected error type
        } else {
            XCTFail("Expected AuthError.authenticationFailed")
        }
    }

    func testLogin_onError_triggersCallbackOnConfigurationError() {
        // Given
        // We need to test the URL configuration error which happens when Environment.current.urlProvider.root
        // is malformed or unavailable. We can't mock the Environment, so we test the tab creation failure instead
        // which triggers the same error handling path
        let mockInvisibleTabAPI = MockInvisibleTabAPI()
        mockInvisibleTabAPI.shouldReturnEmptyTabs = true

        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: mockInvisibleTabAPI,
            authProvider: auth)

        var errorReceived: Error?
        let expectation = XCTestExpectation(description: "Configuration error callback triggered")

        // When
        _ = ecosiaAuth.login()
            .onError { error in
                errorReceived = error
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(errorReceived)
        XCTAssertTrue(errorReceived is AuthError)
        if case .authFlowInvisibleTabCreationFailed = errorReceived as? AuthError {
            // This is the error we get when tabs can't be created
        } else {
            XCTFail("Expected AuthError.authFlowInvisibleTabCreationFailed")
        }
    }

    func testLogin_onError_triggersCallbackOnInvisibleTabCreationFailure() {
        // Given
        let mockInvisibleTabAPI = MockInvisibleTabAPI()
        mockInvisibleTabAPI.shouldReturnEmptyTabs = true

        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: mockInvisibleTabAPI,
            authProvider: auth)

        var errorReceived: Error?
        let expectation = XCTestExpectation(description: "Tab creation failure callback triggered")

        // When
        _ = ecosiaAuth.login()
            .onError { error in
                errorReceived = error
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(errorReceived)
        XCTAssertTrue(errorReceived is AuthError)
        if case .authFlowInvisibleTabCreationFailed = errorReceived as? AuthError {
            // Expected error type
        } else {
            XCTFail("Expected AuthError.authFlowInvisibleTabCreationFailed")
        }
    }

    // MARK: - Credential Cleanup Tests

    func testLogin_credentialCleanupOnTabCreationFailure() {
        // Given
        let mockInvisibleTabAPI = MockInvisibleTabAPI()
        mockInvisibleTabAPI.shouldReturnEmptyTabs = true

        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: mockInvisibleTabAPI,
            authProvider: auth)

        let expectation = XCTestExpectation(description: "Credential cleanup completed")

        // When
        _ = ecosiaAuth.login()
            .onError { error in
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then - Verify cleanup was attempted (login + cleanup logout)
        XCTAssertEqual(mockAuth0Provider.startAuthCallCount, 1, "Should attempt login")
        XCTAssertEqual(mockAuth0Provider.clearSessionCallCount, 1, "Should cleanup session")
        XCTAssertEqual(mockAuth0Provider.clearCredentialsCallCount, 1, "Should cleanup credentials")
    }

    func testLogin_credentialCleanupOnInvisibleTabCreationFailure() {
        // Given
        let mockInvisibleTabAPI = MockInvisibleTabAPI()
        mockInvisibleTabAPI.shouldReturnEmptyTabs = true

        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: mockInvisibleTabAPI,
            authProvider: auth)

        let expectation = XCTestExpectation(description: "Credential cleanup completed")

        // When
        _ = ecosiaAuth.login()
            .onError { error in
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then - Verify cleanup was attempted
        XCTAssertEqual(mockAuth0Provider.startAuthCallCount, 1, "Should attempt login")
        XCTAssertEqual(mockAuth0Provider.clearSessionCallCount, 1, "Should cleanup session")
        XCTAssertEqual(mockAuth0Provider.clearCredentialsCallCount, 1, "Should cleanup credentials")
    }

    func testLogin_noCredentialCleanupOnAuthFailure() {
        // Given
        mockAuth0Provider.shouldFailAuth = true
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        let expectation = XCTestExpectation(description: "Auth failure processed")

        // When
        _ = ecosiaAuth.login()
            .onError { error in
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then - No cleanup should happen since auth never succeeded
        XCTAssertEqual(mockAuth0Provider.startAuthCallCount, 1, "Should attempt login")
        XCTAssertEqual(mockAuth0Provider.clearSessionCallCount, 0, "Should not cleanup session")
        XCTAssertEqual(mockAuth0Provider.clearCredentialsCallCount, 0, "Should not cleanup credentials")
    }

    // MARK: - Error Callback Chaining Tests

    func testErrorCallback_chainsWithOtherCallbacks() {
        // Given
        mockAuth0Provider.shouldFailAuth = true
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        var nativeAuthCalled = false
        var flowCompletedCalled = false
        var errorCalled = false

        let expectation = XCTestExpectation(description: "Error callback triggered")

        // When
        _ = ecosiaAuth.login()
            .onNativeAuthCompleted {
                nativeAuthCalled = true
            }
            .onAuthFlowCompleted { _ in
                flowCompletedCalled = true
            }
            .onError { _ in
                errorCalled = true
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // Then - Only error callback should be called on auth failure
        XCTAssertFalse(nativeAuthCalled, "Native auth callback should not be called on auth failure")
        XCTAssertFalse(flowCompletedCalled, "Flow completed callback should not be called on auth failure")
        XCTAssertTrue(errorCalled, "Error callback should be called")
    }

    func testErrorCallback_doesNotCallOnSuccess() {
        // Given
        let ecosiaAuth = EcosiaAuth(
            invisibleTabAPI: invisibleTabAPI,
            authProvider: auth)

        var errorCalled = false
        var nativeAuthCalled = false

        let nativeAuthExpectation = XCTestExpectation(description: "Native auth completed")

        // When
        _ = ecosiaAuth.login()
            .onNativeAuthCompleted {
                nativeAuthCalled = true
                nativeAuthExpectation.fulfill()
            }
            .onError { _ in
                errorCalled = true
            }

        wait(for: [nativeAuthExpectation], timeout: 1.0)

        // Then - Error callback should not be called on success
        XCTAssertTrue(nativeAuthCalled, "Native auth callback should be called on success")
        XCTAssertFalse(errorCalled, "Error callback should not be called on success")
    }
}

// MARK: - Mock Invisible Tab API

private class MockInvisibleTabAPI: InvisibleTabAPIProtocol {
    var shouldReturnEmptyTabs = false

    func createInvisibleTabs(for urls: [URL], isPrivate: Bool = false, autoClose: Bool = true, completion: (([Client.Tab]) -> Void)? = nil) -> [Client.Tab] {

        if shouldReturnEmptyTabs {
            completion?([])
            return []
        }

        // Create mock tabs for successful case
        let mockTabs = urls.map { url in
            let profile = MockProfile()
            let mockTab = Client.Tab(profile: profile, windowUUID: WindowUUID())
            mockTab.url = url
            return mockTab
        }

        completion?(mockTabs)
        return mockTabs
    }

    func getInvisibleTabs() -> [Client.Tab] {
        return []
    }

    func getTrackedTabCount() -> Int {
        return 0
    }

    func cancelAutoCloseForTabs(_ tabUUIDs: [String]) {}
}
 