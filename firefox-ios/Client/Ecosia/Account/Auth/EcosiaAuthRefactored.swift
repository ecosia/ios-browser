// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/**
 Refactored EcosiaAuth that maintains API compatibility while using the new coordinator architecture.
 
 This class provides the same chainable API as before but delegates to specialized coordinators
 for improved maintainability and testability.
 
 ## Usage
 
 ```swift 
 ecosiaAuthInstance.login()
     .onNativeAuthCompleted {
         // Called when Auth0 authentication completes
     }
     .onAuthFlowCompleted { success in
         // Called when entire flow completes
     }
     .onError { error in
         // Called when authentication fails
     }
 ```
 */
public final class EcosiaAuthRefactored {

    // MARK: - Dependencies

    private let authProvider: Ecosia.Auth
    private let authStateManager: AuthStateManager
    private weak var browserViewController: BrowserViewController?

    // MARK: - Current Flow Tracking

    private var currentLoginFlow: AuthenticationFlowRefactored?
    private var currentLogoutFlow: AuthenticationFlowRefactored?

    // MARK: - Initialization

    /// Initializes EcosiaAuth with required dependencies (LEAN VERSION)
    /// - Parameters:
    ///   - browserViewController: The browser view controller for tab operations
    ///   - authProvider: The auth provider for authentication operations (defaults to Ecosia.Auth.shared)
    ///   - authStateManager: The auth state manager for state coordination (defaults to new instance)
    internal init(
        browserViewController: BrowserViewController,
        authProvider: Ecosia.Auth = Ecosia.Auth.shared,
        authStateManager: AuthStateManager = AuthStateManager()
    ) {
        self.authProvider = authProvider
        self.authStateManager = authStateManager
        self.browserViewController = browserViewController

        EcosiaLogger.auth.info("EcosiaAuthRefactored initialized (lean version)")
    }

    // MARK: - Public API

    /// Starts the login authentication flow
    /// - Returns: AuthenticationFlow for chaining callbacks
    public func login() -> AuthenticationFlowRefactored {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }
        
        let flow = AuthenticationFlowRefactored(
            type: .login,
            authProvider: authProvider,
            authStateManager: authStateManager,
            browserViewController: browserViewController
        )
        currentLoginFlow = flow
        return flow
    }

    /// Starts the logout authentication flow
    /// - Returns: AuthenticationFlow for chaining callbacks  
    public func logout() -> AuthenticationFlowRefactored {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }
        
        let flow = AuthenticationFlowRefactored(
            type: .logout,
            authProvider: authProvider,
            authStateManager: authStateManager,
            browserViewController: browserViewController
        )
        currentLogoutFlow = flow
        return flow
    }

    // MARK: - State Queries

    public var isLoggedIn: Bool {
        return authStateManager.isAuthenticated
    }

    public var idToken: String? {
        return authStateManager.currentUser?.idToken
    }

    public var accessToken: String? {
        return authStateManager.currentUser?.accessToken
    }

    public var currentAuthState: AuthState {
        return authStateManager.currentState
    }
}

// MARK: - AuthenticationFlowRefactored

/**
 Refactored authentication flow that maintains the same chainable API
 but uses the new coordinator architecture under the hood.
 */
public final class AuthenticationFlowRefactored {

    public enum FlowType {
        case login
        case logout
    }

    // MARK: - Properties

    private let type: FlowType
    private let authFlow: AuthFlow

    // MARK: - Callbacks

    private var onNativeAuthCompletedCallback: (() -> Void)?
    private var onAuthFlowCompletedCallback: ((Bool) -> Void)?
    private var onErrorCallback: ((AuthError) -> Void)?

    // MARK: - Configuration

    private var delayedCompletionTime: TimeInterval = 0.0

    // MARK: - Initialization

    internal init(
        type: FlowType,
        authProvider: Ecosia.Auth,
        authStateManager: AuthStateManager,
        browserViewController: BrowserViewController
    ) {
        self.type = type
        self.authFlow = AuthFlow(
            authProvider: authProvider,
            authStateManager: authStateManager,
            browserViewController: browserViewController
        )

        // Start the authentication process
        startAuthentication()
    }

    // MARK: - Public Chainable API

    /// Sets callback for when native Auth0 authentication completes
    /// - Parameter callback: Closure called when Auth0 authentication finishes
    /// - Returns: Self for chaining
    @discardableResult
    public func onNativeAuthCompleted(_ callback: @escaping () -> Void) -> AuthenticationFlowRefactored {
        onNativeAuthCompletedCallback = callback
        return self
    }

    /// Sets callback for when the complete authentication flow finishes
    /// - Parameter callback: Closure called with success status when entire flow completes
    /// - Returns: Self for chaining
    @discardableResult
    public func onAuthFlowCompleted(_ callback: @escaping (Bool) -> Void) -> AuthenticationFlowRefactored {
        onAuthFlowCompletedCallback = callback
        return self
    }

    /// Sets callback for when an error occurs during the authentication flow
    /// - Parameter callback: Closure called with the error when authentication fails
    /// - Returns: Self for chaining
    @discardableResult
    public func onError(_ callback: @escaping (AuthError) -> Void) -> AuthenticationFlowRefactored {
        onErrorCallback = callback
        return self
    }

    /// Sets the delay before firing the onNativeAuthCompleted callback
    /// - Parameter delay: Delay in seconds before calling onNativeAuthCompleted
    /// - Returns: Self for chaining
    @discardableResult
    public func withDelayedCompletion(_ delay: TimeInterval) -> AuthenticationFlowRefactored {
        delayedCompletionTime = delay
        return self
    }

    // MARK: - Private Implementation

    private func startAuthentication() {
        Task {
            switch type {
            case .login:
                await performLogin()
            case .logout:
                await performLogout()
            }
        }
    }

    private func performLogin() async {
        // Use the new lean AuthFlow - no coordinators, no complexity
        Task {
            let result = await authFlow.startLogin(
                delayedCompletion: delayedCompletionTime,
                onNativeAuthCompleted: onNativeAuthCompletedCallback,
                onFlowCompleted: onAuthFlowCompletedCallback,
                onError: onErrorCallback
            )
            
            switch result {
            case .success:
                EcosiaLogger.auth.debug("Login flow completed successfully")
            case .failure(let error):
                EcosiaLogger.auth.error("Login flow failed: \(error)")
            }
        }
    }

    private func performLogout() async {
        // Use the new lean AuthFlow - no coordinators, no complexity
        let result = await authFlow.startLogout(
            delayedCompletion: delayedCompletionTime,
            onNativeAuthCompleted: onNativeAuthCompletedCallback,
            onFlowCompleted: onAuthFlowCompletedCallback,
            onError: onErrorCallback
        )

        switch result {
        case .success:
            EcosiaLogger.auth.info("Logout flow completed successfully")
        case .failure(let error):
            EcosiaLogger.auth.error("Logout flow failed: \(error)")
        }
    }
}
