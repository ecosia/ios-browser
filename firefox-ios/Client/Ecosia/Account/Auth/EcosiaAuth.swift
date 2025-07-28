// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia
import Common

/**
 EcosiaAuth provides authentication management for the Ecosia browser.
 
 This class provides a clean chainable API and delegates to specialized components
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
public final class EcosiaAuth {

    // MARK: - Dependencies

    private let authProvider: Ecosia.Auth
    private weak var browserViewController: BrowserViewController?

    // MARK: - Current Flow Tracking

    private var currentLoginFlow: AuthFlowWrapper?
    private var currentLogoutFlow: AuthFlowWrapper?

    // MARK: - Initialization

    /// Initializes EcosiaAuth with required dependencies
    /// - Parameters:
    ///   - browserViewController: The browser view controller for tab operations
    ///   - authProvider: The auth provider for authentication operations (defaults to Ecosia.Auth.shared)
    internal init(
        browserViewController: BrowserViewController,
        authProvider: Ecosia.Auth = Ecosia.Auth.shared
    ) {
        self.authProvider = authProvider
        self.browserViewController = browserViewController

        EcosiaLogger.auth.info("EcosiaAuth initialized")
    }

    // MARK: - Public API

    /// Starts the login authentication flow
    /// - Returns: AuthFlowWrapper for chaining callbacks
    public func login() -> AuthFlowWrapper {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }

        let flow = AuthFlowWrapper(
            type: .login,
            authProvider: authProvider,
            browserViewController: browserViewController
        )
        currentLoginFlow = flow
        return flow
    }

    /// Starts the logout authentication flow
    /// - Returns: AuthFlowWrapper for chaining callbacks  
    public func logout() -> AuthFlowWrapper {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }

        let flow = AuthFlowWrapper(
            type: .logout,
            authProvider: authProvider,
            browserViewController: browserViewController
        )
        currentLogoutFlow = flow
        return flow
    }

    // MARK: - State Queries

    public var isLoggedIn: Bool {
        if let windowUUID = browserViewController?.windowUUID,
           let authState = Ecosia.AuthStateManager.shared.getAuthState(for: windowUUID) {
            return authState.isLoggedIn
        }

        let allStates = Ecosia.AuthStateManager.shared.getAllAuthStates()
        return allStates.values.contains { $0.isLoggedIn }
    }

    public var idToken: String? {
        return authProvider.idToken
    }

    public var accessToken: String? {
        return authProvider.accessToken
    }
}

// MARK: - AuthFlowWrapper

/**
 Authentication flow wrapper that provides a clean chainable API
 for both login and logout operations.
 */
public final class AuthFlowWrapper {

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
        browserViewController: BrowserViewController
    ) {
        self.type = type
        self.authFlow = AuthFlow(
            authProvider: authProvider,
            browserViewController: browserViewController
        )
    }

    // MARK: - Public Chainable API

    /// Sets callback for when native Auth0 authentication completes
    /// - Parameter callback: Closure called when Auth0 authentication finishes
    /// - Returns: Self for chaining
    @discardableResult
    public func onNativeAuthCompleted(_ callback: @escaping () -> Void) -> AuthFlowWrapper {
        onNativeAuthCompletedCallback = callback
        return self
    }

    /// Sets callback for when the complete authentication flow finishes
    /// - Parameter callback: Closure called with success status when entire flow completes
    /// - Returns: Self for chaining
    @discardableResult
    public func onAuthFlowCompleted(_ callback: @escaping (Bool) -> Void) -> AuthFlowWrapper {
        onAuthFlowCompletedCallback = callback
        return self
    }

    /// Sets callback for when an error occurs during the authentication flow
    /// - Parameter callback: Closure called with the error when authentication fails
    /// - Returns: Self for chaining
    @discardableResult
    public func onError(_ callback: @escaping (AuthError) -> Void) -> AuthFlowWrapper {
        onErrorCallback = callback
        return self
    }

    /// Sets the delay before firing the onNativeAuthCompleted callback
    /// - Parameter delay: Delay in seconds before calling onNativeAuthCompleted
    /// - Returns: Self for chaining
    @discardableResult
    public func withDelayedCompletion(_ delay: TimeInterval) -> AuthFlowWrapper {
        delayedCompletionTime = delay
        return self
    }

    /// Starts the authentication process after configuration
    /// - Returns: Self for chaining
    @discardableResult
    public func startAuthentication() -> AuthFlowWrapper {
        Task {
            switch type {
            case .login:
                await performLogin()
            case .logout:
                await performLogout()
            }
        }
        return self
    }

    // MARK: - Private Implementation

    private func performLogin() async {
        // Use the lean AuthFlow for streamlined authentication
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
            // TODO: Error handling should be moved to EcosiaAuth to be handled with BrowserViewController
            // This will be implemented as part of the error states design work
        }
        }
    }

    private func performLogout() async {
        // Use the lean AuthFlow for streamlined authentication
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
            // TODO: Error handling should be moved to EcosiaAuth to be handled with BrowserViewController
            // This will be implemented as part of the error states design work
        }
    }
}
