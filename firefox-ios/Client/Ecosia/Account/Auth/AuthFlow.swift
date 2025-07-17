// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Result of authentication flow operations
public enum AuthFlowResult {
    case success(user: AuthUser?)
    case failure(error: AuthError)
}

/// Orchestrates complete authentication flows with invisible tab sessions
/// Single responsibility: coordinate auth provider + session transfer
final class AuthFlow {

    // MARK: - Properties

    private let authProvider: Ecosia.Auth
    private let authStateManager: AuthStateManager
    private weak var browserViewController: BrowserViewController?
    
    // Active session (retained until completion)
    private var activeSession: InvisibleTabSession?

    // MARK: - Initialization

    /// Initializes the auth flow coordinator
    /// - Parameters:
    ///   - authProvider: Auth provider for authentication operations
    ///   - authStateManager: Manager for auth state coordination
    ///   - browserViewController: Browser view controller for tab operations
    init(
        authProvider: Ecosia.Auth,
        authStateManager: AuthStateManager,
        browserViewController: BrowserViewController
    ) {
        self.authProvider = authProvider
        self.authStateManager = authStateManager
        self.browserViewController = browserViewController
        
        EcosiaLogger.auth.info("AuthFlow initialized")
    }

    // MARK: - Login Flow

    /// Performs complete login flow
    /// - Parameters:
    ///   - delayedCompletion: Optional delay for native auth callback
    ///   - onNativeAuthCompleted: Called when native Auth0 completes
    ///   - onFlowCompleted: Called when entire flow completes
    ///   - onError: Called if flow fails
    func startLogin(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> AuthFlowResult {
        
        EcosiaLogger.auth.info("Starting login flow")
        authStateManager.beginAuthentication()

        do {
            // Step 1: Native Auth0 authentication
            try await performNativeAuthentication()
            
            let user = AuthUser(
                idToken: authProvider.idToken,
                accessToken: authProvider.accessToken
            )

            // Step 2: Handle native auth completion callback
            await handleNativeAuthCompleted(
                delayedCompletion: delayedCompletion,
                onNativeAuthCompleted: onNativeAuthCompleted
            )

            // Step 3: Session transfer and invisible tab flow
            try await performSessionTransfer(
                user: user,
                onFlowCompleted: onFlowCompleted
            )

            return .success(user: user)
            
        } catch {
            let authError = mapToAuthError(error)
            await handleAuthFailure(authError, onError: onError)
            return .failure(error: authError)
        }
    }

    // MARK: - Logout Flow

    /// Performs complete logout flow
    /// - Parameters:
    ///   - delayedCompletion: Optional delay for native auth callback
    ///   - onNativeAuthCompleted: Called when native logout completes
    ///   - onFlowCompleted: Called when entire flow completes
    ///   - onError: Called if flow fails
    func startLogout(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> AuthFlowResult {
        
        EcosiaLogger.auth.info("Starting logout flow")
        authStateManager.beginLogout()

        do {
            // Step 1: Native Auth0 logout
            try await performNativeLogout()

            // Step 2: Handle native logout completion callback
            await handleNativeAuthCompleted(
                delayedCompletion: delayedCompletion,
                onNativeAuthCompleted: onNativeAuthCompleted
            )

            // Step 3: Session cleanup and invisible tab flow
            try await performSessionCleanup(onFlowCompleted: onFlowCompleted)

            return .success(user: nil)
            
        } catch {
            let authError = mapToAuthError(error)
            await handleAuthFailure(authError, onError: onError)
            return .failure(error: authError)
        }
    }

    // MARK: - Private Implementation

    private func performNativeAuthentication() async throws {
        EcosiaLogger.auth.info("Performing native Auth0 authentication")
        try await authProvider.login()
        EcosiaLogger.auth.info("Native Auth0 authentication completed")
    }

    private func performNativeLogout() async throws {
        EcosiaLogger.auth.info("Performing native Auth0 logout")
        try await authProvider.logout()
        EcosiaLogger.auth.info("Native Auth0 logout completed")
    }

    @MainActor
    private func handleNativeAuthCompleted(
        delayedCompletion: TimeInterval,
        onNativeAuthCompleted: (() -> Void)?
    ) async {
        if delayedCompletion > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayedCompletion) {
                onNativeAuthCompleted?()
            }
        } else {
            onNativeAuthCompleted?()
        }
    }

    private func performSessionTransfer(
        user: AuthUser,
        onFlowCompleted: ((Bool) -> Void)?
    ) async throws {
        
        guard let browserViewController = browserViewController else {
            throw AuthError.authFlowConfigurationError("BrowserViewController not available")
        }

        // Get session transfer URL
        let signUpURL = URL(string: "\(Environment.current.urlProvider.root)/accounts/sign-up")
        guard let signUpURL = signUpURL else {
            throw AuthError.authFlowConfigurationError("No session management URL available")
        }

        EcosiaLogger.session.info("Retrieving session transfer token for SSO")
        await Auth.shared.getSessionTransferToken()

        // Create invisible tab session (must be on main thread for UI operations)
        EcosiaLogger.invisibleTabs.info("Creating invisible tab session for login")
        let session = try await MainActor.run {
            try InvisibleTabSession(
                url: signUpURL,
                browserViewController: browserViewController,
                timeout: 10.0
            )
        }
        
        // Retain session until completion
        activeSession = session

        // Set up session cookies
        session.setupSessionCookies()

        // Complete authentication state (triggers notifications)
        authStateManager.completeAuthentication(with: user)

        // Wait for session completion
        await withCheckedContinuation { continuation in
            session.waitForCompletion { [weak self] success in
                self?.activeSession = nil // Release session
                EcosiaLogger.auth.info("🔐 [AUTH] Ecosia auth flow completed: \(success)")
                onFlowCompleted?(success)
                continuation.resume()
            }
        }
    }

    private func performSessionCleanup(
        onFlowCompleted: ((Bool) -> Void)?
    ) async throws {
        
        guard let browserViewController = browserViewController else {
            throw AuthError.authFlowConfigurationError("BrowserViewController not available")
        }

        // Get logout URL
        let logoutURL = URL(string: "\(Environment.current.urlProvider.root)/accounts/sign-out")
        guard let logoutURL = logoutURL else {
            throw AuthError.authFlowConfigurationError("No logout URL available")
        }

        // Create invisible tab session for logout (must be on main thread for UI operations)
        EcosiaLogger.invisibleTabs.info("Creating invisible tab session for logout")
        let session = try await MainActor.run {
            try InvisibleTabSession(
                url: logoutURL,
                browserViewController: browserViewController,
                timeout: 10.0
            )
        }
        
        // Retain session until completion
        activeSession = session

        // Complete logout state
        authStateManager.completeLogout()

        // Wait for session completion
        await withCheckedContinuation { continuation in
            session.waitForCompletion { [weak self] success in
                self?.activeSession = nil // Release session
                EcosiaLogger.auth.info("🔐 [AUTH] Ecosia logout flow completed: \(success)")
                onFlowCompleted?(success)
                continuation.resume()
            }
        }
    }

    @MainActor
    private func handleAuthFailure(
        _ error: AuthError,
        onError: ((AuthError) -> Void)?
    ) async {
        // Clean up any active session
        activeSession = nil
        
        authStateManager.updateAuthState(.idle)
        
        EcosiaLogger.auth.error("Auth flow failed: \(error)")
        onError?(error)
    }

    private func mapToAuthError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        return .unknown(error.localizedDescription)
    }

    // MARK: - Cleanup

    deinit {
        activeSession = nil
        EcosiaLogger.auth.debug("AuthFlow deallocated")
    }
} 
