// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Result of authentication flow operations
public enum AuthFlowResult {
    case success
    case failure(error: AuthError)
}

/// Orchestrates complete authentication flows with invisible tab sessions
/// Single responsibility: coordinate auth provider + session transfer
final class AuthFlow {

    // MARK: - Properties

    private let authProvider: Ecosia.Auth
    private weak var browserViewController: BrowserViewController?

    // Active session (retained until completion)
    private var activeSession: InvisibleTabSession?

    // MARK: - Initialization

    /// Initializes the auth flow coordinator
    /// - Parameters:
    ///   - authProvider: Auth provider for authentication operations
    ///   - browserViewController: Browser view controller for tab operations
    init(
        authProvider: Ecosia.Auth,
        browserViewController: BrowserViewController
    ) {
        self.authProvider = authProvider
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

        do {
            // Step 1: Native Auth0 authentication
            try await performNativeAuthentication()

            // Step 2: Handle native auth completion callback
            await handleNativeAuthCompleted(
                delayedCompletion: delayedCompletion,
                onNativeAuthCompleted: onNativeAuthCompleted
            )

            // Step 3: Session transfer and invisible tab flow
            try await performSessionTransfer(onFlowCompleted: onFlowCompleted)

            return .success
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

            return .success
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
        onFlowCompleted: ((Bool) -> Void)?
    ) async throws {

        guard let browserViewController = browserViewController else {
            throw AuthError.authFlowConfigurationError("BrowserViewController not available")
        }

        // Get session transfer URL
        let signUpURL = Environment.current.urlProvider.loginURL

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

        // Wait for session completion
        await withCheckedContinuation { continuation in
            session.waitForCompletion { [weak self] success in
                self?.activeSession = nil // Release session
                EcosiaLogger.auth.info("Ecosia auth flow completed: \(success)")
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
        let logoutURL = Environment.current.urlProvider.logoutURL

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

        // Wait for session completion
        await withCheckedContinuation { continuation in
            session.waitForCompletion { [weak self] success in
                self?.activeSession = nil // Release session
                EcosiaLogger.auth.info("Ecosia logout flow completed: \(success)")
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
        activeSession = nil

        EcosiaLogger.auth.error("Auth flow failed: \(error)")
        onError?(error)
    }

    private func mapToAuthError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        return .authFlowConfigurationError(error.localizedDescription)
    }

    // MARK: - Cleanup

    deinit {
        activeSession = nil
        EcosiaLogger.auth.debug("AuthFlow deallocated")
    }
}
