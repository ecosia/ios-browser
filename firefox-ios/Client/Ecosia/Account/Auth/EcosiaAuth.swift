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
 ecosiaAuth
     .onNativeAuthCompleted {
         // Called when Auth0 authentication completes
     }
     .onAuthFlowCompleted { success in
         // Called when entire flow completes
     }
     .onError { error in
         // Called when authentication fails
     }
     .login() // Starts login authentication
 ```

 ## Architecture

 - **EcosiaAuth**: Main entry point with chainable API
 - **AuthFlow**: Core authentication orchestration
 - **InvisibleTabSession**: Web session management
 - **TabAutoCloseManager**: Automatic tab cleanup
 */
final class EcosiaAuth {

    // MARK: - Dependencies

    private let authProvider: Ecosia.Auth
    private weak var browserViewController: BrowserViewController?

    // MARK: - Chainable API Properties

    private var onNativeAuthCompletedCallback: (() -> Void)?
    private var onAuthFlowCompletedCallback: ((Bool) -> Void)?
    private var onErrorCallback: ((AuthError) -> Void)?
    private var delayedCompletionTime: TimeInterval = 0.0

    // MARK: - Initialization

    /// Initializes EcosiaAuth with required dependencies
    /// - Parameters:
    ///   - browserViewController: The browser view controller for tab operations
    ///   - authProvider: The auth provider for authentication operations (defaults to Ecosia.Auth.shared)
    init(browserViewController: BrowserViewController,
         authProvider: Ecosia.Auth = Ecosia.Auth.shared) {
        self.authProvider = authProvider
        self.browserViewController = browserViewController

        EcosiaLogger.auth.info("EcosiaAuth initialized")
    }

    // MARK: - Chainable API

    /// Sets callback for when native Auth0 authentication completes
    /// - Parameter callback: Closure called when Auth0 authentication finishes
    /// - Returns: Self for chaining
    @discardableResult
    func onNativeAuthCompleted(_ callback: @escaping () -> Void) -> EcosiaAuth {
        onNativeAuthCompletedCallback = callback
        return self
    }

    /// Sets callback for when the complete authentication flow finishes
    /// - Parameter callback: Closure called with success status when entire flow completes
    /// - Returns: Self for chaining
    @discardableResult
    func onAuthFlowCompleted(_ callback: @escaping (Bool) -> Void) -> EcosiaAuth {
        onAuthFlowCompletedCallback = callback
        return self
    }

    /// Sets callback for when an error occurs during the authentication flow
    /// - Parameter callback: Closure called with the error when authentication fails
    /// - Returns: Self for chaining
    @discardableResult
    func onError(_ callback: @escaping (AuthError) -> Void) -> EcosiaAuth {
        onErrorCallback = callback
        return self
    }

    /// Sets the delay before firing the onNativeAuthCompleted callback
    /// - Parameter delay: Delay in seconds before calling onNativeAuthCompleted
    /// - Returns: Self for chaining
    @discardableResult
    func withDelayedCompletion(_ delay: TimeInterval) -> EcosiaAuth {
        delayedCompletionTime = delay
        return self
    }

    /// Starts the login authentication flow
    func login() {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }

        let flow = AuthFlow(
            type: .login,
            authProvider: authProvider,
            browserViewController: browserViewController
        )

        // Start the authentication process
        Task {
            await performLogin(flow)
        }
    }

    /// Starts the logout authentication flow
    func logout() {
        guard let browserViewController = browserViewController else {
            fatalError("BrowserViewController not available for auth flow")
        }

        let flow = AuthFlow(
            type: .logout,
            authProvider: authProvider,
            browserViewController: browserViewController
        )

        // Start the authentication process
        Task {
            await performLogout(flow)
        }
    }

    // MARK: - Private Implementation

    private func performLogin(_ flow: AuthFlow) async {
        let result = await flow.startLogin(
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

    private func performLogout(_ flow: AuthFlow) async {
        let result = await flow.startLogout(
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

    // MARK: - State Queries

    var isLoggedIn: Bool {
        if let windowUUID = browserViewController?.windowUUID,
           let authState = Ecosia.AuthStateManager.shared.getAuthState(for: windowUUID) {
            return authState.isLoggedIn
        }

        let allStates = Ecosia.AuthStateManager.shared.getAllAuthStates()
        return allStates.values.contains { $0.isLoggedIn }
    }

    var idToken: String? {
        return authProvider.idToken
    }

    var accessToken: String? {
        return authProvider.accessToken
    }
}
