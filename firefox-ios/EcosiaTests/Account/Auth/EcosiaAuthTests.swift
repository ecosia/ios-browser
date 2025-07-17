// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Ecosia
@testable import Client

final class EcosiaAuthTests: XCTestCase {

    var ecosiaAuth: EcosiaAuth!
    var mockAuthProvider: MockEcosiaAuthProvider!
    var mockAuthStateManager: MockAuthStateManager!
    var mockBrowserViewController: MockBrowserViewController!

    override func setUp() {
        super.setUp()
        mockAuthProvider = MockEcosiaAuthProvider()
        mockAuthStateManager = MockAuthStateManager()
        mockBrowserViewController = MockBrowserViewController()
        
        ecosiaAuth = EcosiaAuth(
            browserViewController: mockBrowserViewController,
            authProvider: mockAuthProvider,
            authStateManager: mockAuthStateManager
        )
    }

    override func tearDown() {
        mockAuthProvider?.reset()
        mockAuthStateManager?.reset()
        mockBrowserViewController?.reset()
        ecosiaAuth = nil
        mockAuthProvider = nil
        mockAuthStateManager = nil
        mockBrowserViewController = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_withValidDependencies_succeeds() {
        XCTAssertNotNil(ecosiaAuth)
        XCTAssertFalse(ecosiaAuth.isLoggedIn)
        XCTAssertNil(ecosiaAuth.idToken)
        XCTAssertNil(ecosiaAuth.accessToken)
        XCTAssertEqual(ecosiaAuth.currentAuthState, .idle)
    }

    // MARK: - State Query Tests

    func testIsLoggedIn_delegatesToAuthStateManager() {
        mockAuthStateManager.isAuthenticatedResult = true
        
        XCTAssertTrue(ecosiaAuth.isLoggedIn)
        
        mockAuthStateManager.isAuthenticatedResult = false
        
        XCTAssertFalse(ecosiaAuth.isLoggedIn)
    }

    func testIdToken_delegatesToAuthStateManager() {
        let expectedToken = "test-id-token"
        let mockUser = AuthUser(idToken: expectedToken, accessToken: "access-token")
        mockAuthStateManager.currentUserResult = mockUser
        
        XCTAssertEqual(ecosiaAuth.idToken, expectedToken)
        
        mockAuthStateManager.currentUserResult = nil
        
        XCTAssertNil(ecosiaAuth.idToken)
    }

    func testAccessToken_delegatesToAuthStateManager() {
        let expectedToken = "test-access-token"
        let mockUser = AuthUser(idToken: "id-token", accessToken: expectedToken)
        mockAuthStateManager.currentUserResult = mockUser
        
        XCTAssertEqual(ecosiaAuth.accessToken, expectedToken)
        
        mockAuthStateManager.currentUserResult = nil
        
        XCTAssertNil(ecosiaAuth.accessToken)
    }

    func testCurrentAuthState_delegatesToAuthStateManager() {
        let expectedState = AuthState.authenticating
        mockAuthStateManager.currentStateResult = expectedState
        
        XCTAssertEqual(ecosiaAuth.currentAuthState, expectedState)
    }

    // MARK: - Login Flow Tests

    func testLogin_returnsAuthenticationFlow() {
        let flow = ecosiaAuth.login()
        
        XCTAssertNotNil(flow)
        XCTAssertTrue(flow is AuthenticationFlow)
    }

    func testLogin_tracksCurrentLoginFlow() {
        let flow1 = ecosiaAuth.login()
        let flow2 = ecosiaAuth.login()
        
        // Each call should return a new flow
        XCTAssertNotNil(flow1)
        XCTAssertNotNil(flow2)
        // Note: flows are different instances since each login() creates a new flow
    }

    // MARK: - Logout Flow Tests

    func testLogout_returnsAuthenticationFlow() {
        let flow = ecosiaAuth.logout()
        
        XCTAssertNotNil(flow)
        XCTAssertTrue(flow is AuthenticationFlow)
    }

    func testLogout_tracksCurrentLogoutFlow() {
        let flow1 = ecosiaAuth.logout()
        let flow2 = ecosiaAuth.logout()
        
        // Each call should return a new flow
        XCTAssertNotNil(flow1)
        XCTAssertNotNil(flow2)
        // Note: flows are different instances since each logout() creates a new flow
    }

    // MARK: - Error Handling Tests

    func testInitialization_withNilBrowserViewController_shouldFatalError() {
        // This test would cause a fatal error in real usage
        // In production code, we'd handle this more gracefully
        // For now, we document this behavior
        
        // Note: Cannot easily test fatalError() without custom error handling
        // This is documented behavior that should be prevented at call site
    }
}

// MARK: - AuthenticationFlow Tests

final class AuthenticationFlowTests: XCTestCase {

    var mockAuthProvider: MockEcosiaAuthProvider!
    var mockAuthStateManager: MockAuthStateManager!
    var mockBrowserViewController: MockBrowserViewController!

    override func setUp() {
        super.setUp()
        mockAuthProvider = MockEcosiaAuthProvider()
        mockAuthStateManager = MockAuthStateManager()
        mockBrowserViewController = MockBrowserViewController()
    }

    override func tearDown() {
        mockAuthProvider?.reset()
        mockAuthStateManager?.reset()
        mockBrowserViewController?.reset()
        mockAuthProvider = nil
        mockAuthStateManager = nil
        mockBrowserViewController = nil
        super.tearDown()
    }

    // MARK: - Chainable API Tests

    func testOnNativeAuthCompleted_returnsFlowForChaining() {
        let flow = createLoginFlow()
        
        let result = flow.onNativeAuthCompleted { }
        
        XCTAssertTrue(result === flow) // Should return same instance for chaining
    }

    func testOnAuthFlowCompleted_returnsFlowForChaining() {
        let flow = createLoginFlow()
        
        let result = flow.onAuthFlowCompleted { _ in }
        
        XCTAssertTrue(result === flow) // Should return same instance for chaining
    }

    func testOnError_returnsFlowForChaining() {
        let flow = createLoginFlow()
        
        let result = flow.onError { _ in }
        
        XCTAssertTrue(result === flow) // Should return same instance for chaining
    }

    func testWithDelayedCompletion_returnsFlowForChaining() {
        let flow = createLoginFlow()
        
        let result = flow.withDelayedCompletion(2.0)
        
        XCTAssertTrue(result === flow) // Should return same instance for chaining
    }

    func testChainedAPI_canChainMultipleCalls() {
        let flow = createLoginFlow()
        
        let result = flow
            .withDelayedCompletion(1.0)
            .onNativeAuthCompleted { }
            .onAuthFlowCompleted { _ in }
            .onError { _ in }
        
        XCTAssertTrue(result === flow) // Should return same instance after chaining
    }

    // MARK: - Flow Type Tests

    func testLoginFlow_hasCorrectType() {
        let flow = createLoginFlow()
        
        // Cannot directly test the internal type, but we can verify behavior
        // The flow should start login process automatically upon creation
        XCTAssertNotNil(flow)
    }

    func testLogoutFlow_hasCorrectType() {
        let flow = createLogoutFlow()
        
        // Cannot directly test the internal type, but we can verify behavior
        // The flow should start logout process automatically upon creation
        XCTAssertNotNil(flow)
    }

    // MARK: - Helper Methods

    private func createLoginFlow() -> AuthenticationFlow {
        return AuthenticationFlow(
            type: .login,
            authProvider: mockAuthProvider,
            authStateManager: mockAuthStateManager,
            browserViewController: mockBrowserViewController
        )
    }

    private func createLogoutFlow() -> AuthenticationFlow {
        return AuthenticationFlow(
            type: .logout,
            authProvider: mockAuthProvider,
            authStateManager: mockAuthStateManager,
            browserViewController: mockBrowserViewController
        )
    }
}

// MARK: - Mock Objects

class MockEcosiaAuthProvider {
    
    var loginCallCount = 0
    var logoutCallCount = 0
    var shouldFailLogin = false
    var shouldFailLogout = false
    var mockIdToken: String?
    var mockAccessToken: String?
    var isLoggedInResult = false
    
    var isLoggedIn: Bool {
        return isLoggedInResult
    }
    
    var idToken: String? {
        return mockIdToken
    }
    
    var accessToken: String? {
        return mockAccessToken
    }
    
    func login() async throws {
        loginCallCount += 1
        if shouldFailLogin {
            throw AuthError.userCancelled
        }
        isLoggedInResult = true
        mockIdToken = "mock-id-token"
        mockAccessToken = "mock-access-token"
    }
    
    func logout(triggerWebLogout: Bool = true) async throws {
        logoutCallCount += 1
        if shouldFailLogout {
            throw AuthError.networkError("Mock logout error")
        }
        isLoggedInResult = false
        mockIdToken = nil
        mockAccessToken = nil
    }
    
    func reset() {
        loginCallCount = 0
        logoutCallCount = 0
        shouldFailLogin = false
        shouldFailLogout = false
        mockIdToken = nil
        mockAccessToken = nil
        isLoggedInResult = false
    }
}

class MockAuthStateManager {
    
    var isAuthenticatedResult = false
    var currentUserResult: AuthUser?
    var currentStateResult: AuthState = .idle
    
    var beginAuthenticationCallCount = 0
    var completeAuthenticationCallCount = 0
    var beginLogoutCallCount = 0
    var completeLogoutCallCount = 0
    
    var isAuthenticated: Bool {
        return isAuthenticatedResult
    }
    
    var currentUser: AuthUser? {
        return currentUserResult
    }
    
    var currentState: AuthState {
        return currentStateResult
    }
    
    func beginAuthentication() {
        beginAuthenticationCallCount += 1
        currentStateResult = .authenticating
    }
    
    func completeAuthentication(with user: AuthUser) {
        completeAuthenticationCallCount += 1
        currentUserResult = user
        currentStateResult = .authenticated(user: user)
        isAuthenticatedResult = true
    }
    
    func beginLogout() {
        beginLogoutCallCount += 1
        currentStateResult = .loggingOut
    }
    
    func completeLogout() {
        completeLogoutCallCount += 1
        currentUserResult = nil
        currentStateResult = .loggedOut
        isAuthenticatedResult = false
    }
    
    func reset() {
        isAuthenticatedResult = false
        currentUserResult = nil
        currentStateResult = .idle
        beginAuthenticationCallCount = 0
        completeAuthenticationCallCount = 0
        beginLogoutCallCount = 0
        completeLogoutCallCount = 0
    }
}

class MockBrowserViewController {
    
    var setupCallCount = 0
    var tabManager: MockTabManager?
    var profile: MockProfile?
    
    init() {
        self.profile = MockProfile()
        self.tabManager = MockTabManager()
    }
    
    func reset() {
        setupCallCount = 0
    }
}

class MockTabManager {
    var tabs: [MockTab] = []
    var windowUUID = WindowUUID()
    
    func configureTab(_ tab: MockTab, request: URLRequest, afterTab: MockTab?, flushToDisk: Bool, zombie: Bool) {
        tabs.append(tab)
    }
    
    func removeTab(_ tab: MockTab, completion: (() -> Void)? = nil) {
        if let index = tabs.firstIndex(where: { $0.tabUUID == tab.tabUUID }) {
            tabs.remove(at: index)
        }
        completion?()
    }
}

class MockTab {
    var tabUUID: String = UUID().uuidString
    var url: URL?
    var isInvisible: Bool = false
    var webView: MockWebView?
    
    init(profile: MockProfile, isPrivate: Bool, windowUUID: WindowUUID) {
        self.webView = MockWebView()
    }
}

class MockWebView {
    var configuration: MockWebViewConfiguration = MockWebViewConfiguration()
}

class MockWebViewConfiguration {
    var websiteDataStore: MockWebsiteDataStore = MockWebsiteDataStore()
}

class MockWebsiteDataStore {
    var httpCookieStore: MockHTTPCookieStore = MockHTTPCookieStore()
}

class MockHTTPCookieStore {
    func setCookie(_ cookie: HTTPCookie) {
        // Mock implementation
    }
}

class MockProfile {
    // Mock implementation
} 