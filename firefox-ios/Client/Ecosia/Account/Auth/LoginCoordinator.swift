// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Result of login coordination operations
public enum LoginResult {
    case success(AuthUser)
    case failure(AuthError)
}

/// Callback types for login flow events
public struct LoginCallbacks {
    public let onNativeAuthCompleted: (() -> Void)?
    public let onFlowCompleted: ((Bool) -> Void)?
    public let onError: ((AuthError) -> Void)?
    
    public init(
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) {
        self.onNativeAuthCompleted = onNativeAuthCompleted
        self.onFlowCompleted = onFlowCompleted
        self.onError = onError
    }
}

/// Coordinates the complete login authentication flow
/// Handles native Auth0 authentication, session transfer, and invisible tab management
public final class LoginCoordinator: AuthStateObserver {
    
    // MARK: - Properties
    
    /// Dependencies
    private let authProvider: Ecosia.Auth
    private let tabLifecycleManager: TabLifecycleManaging
    private let authStateManager: AuthStateManager
    
    /// Configuration
    private let delayedCompletionTime: TimeInterval
    
    /// Flow state
    private var isNativeAuthCompleted = false
    private var isFlowCompleted = false
    private var callbacks: LoginCallbacks?
    private var createdTabs: [Client.Tab] = []
    
    // MARK: - Initialization
    
    /// Initializes the login coordinator
    /// - Parameters:
    ///   - authProvider: Auth provider for authentication operations
    ///   - tabLifecycleManager: Manager for tab operations
    ///   - authStateManager: Manager for auth state coordination
    ///   - delayedCompletionTime: Optional delay before calling native auth completed callback
    public init(
        authProvider: Ecosia.Auth,
        tabLifecycleManager: TabLifecycleManaging,
        authStateManager: AuthStateManager,
        delayedCompletionTime: TimeInterval = 0.0
    ) {
        self.authProvider = authProvider
        self.tabLifecycleManager = tabLifecycleManager
        self.authStateManager = authStateManager
        self.delayedCompletionTime = delayedCompletionTime
        
        // Register as observer for auth state changes
        authStateManager.addObserver(self)
        
        EcosiaLogger.auth.info("LoginCoordinator initialized")
    }
    
    deinit {
        authStateManager.removeObserver(self)
    }
    
    // MARK: - Public API
    
    /// Starts the login flow with callbacks
    /// - Parameter callbacks: Callbacks for flow events
    public func startLogin(callbacks: LoginCallbacks) async -> LoginResult {
        self.callbacks = callbacks
        
        // Reset state
        isNativeAuthCompleted = false
        isFlowCompleted = false
        createdTabs.removeAll()
        
        EcosiaLogger.auth.info("Starting login flow")
        authStateManager.beginAuthentication()
        
        do {
            // Perform native Auth0 authentication
            try await performNativeAuthentication()
            
            // Handle successful native auth
            let user = createAuthUser()
            await handleNativeAuthSuccess(user: user)
            
            return .success(user)
            
        } catch {
            let authError = mapToAuthError(error)
            await handleAuthenticationFailure(authError)
            return .failure(authError)
        }
    }
    
    // MARK: - AuthStateObserver
    
    public func authStateDidChange(_ state: AuthState, previousState: AuthState) {
        Task { @MainActor in
            await handleAuthStateChange(state, previousState: previousState)
        }
    }
    
    // MARK: - Private Implementation
    
    private func performNativeAuthentication() async throws {
        EcosiaLogger.auth.info("Performing native Auth0 authentication")
        try await authProvider.login()
        EcosiaLogger.auth.info("Native Auth0 authentication completed successfully")
    }
    
    private func createAuthUser() -> AuthUser {
        return AuthUser(
            idToken: authProvider.idToken,
            accessToken: authProvider.accessToken
        )
    }
    
    @MainActor
    private func handleNativeAuthSuccess(user: AuthUser) async {
        isNativeAuthCompleted = true
        
        // Update auth state
        authStateManager.completeAuthentication(with: user)
        
        // Call native auth completed callback with optional delay
        if delayedCompletionTime > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayedCompletionTime) { [weak self] in
                self?.callbacks?.onNativeAuthCompleted?()
            }
        } else {
            callbacks?.onNativeAuthCompleted?()
        }
        
        // Prepare session transfer and create invisible tabs
        await prepareSessionTransferAndCreateTabs()
    }
    
    private func prepareSessionTransferAndCreateTabs() async {
        EcosiaLogger.auth.info("Preparing session transfer and creating tabs")
        
        // Get session transfer token
        await Auth.shared.getSessionTransferToken()
        
        // Create invisible tabs for session management
        await MainActor.run {
            createSessionManagementTabs()
        }
    }
    
    @MainActor
    private func createSessionManagementTabs() {
        guard let signUpURL = URL(string: "\(Environment.current.urlProvider.root)/accounts/sign-up") else {
            let error = AuthError.authFlowConfigurationError("No session management URL available")
            Task {
                await handleTabCreationFailure(error)
            }
            return
        }
        
        EcosiaLogger.invisibleTabs.info("Creating invisible tabs for session management")
        
        let config = TabConfig(
            urls: [signUpURL],
            isPrivate: false,
            autoClose: true,
            autoCloseTimeout: 10.0
        )
        
        let result = tabLifecycleManager.createInvisibleTabs(config: config) { [weak self] tabs in
            self?.setupSessionCookiesForTabs(tabs)
        }
        
        switch result {
        case .success(let tabs):
            createdTabs = tabs
            EcosiaLogger.invisibleTabs.info("Successfully created \(tabs.count) session management tabs")
            
        case .partialSuccess(let tabs, let warnings):
            createdTabs = tabs
            for warning in warnings {
                EcosiaLogger.invisibleTabs.notice("Tab creation warning: \(warning)")
            }
            
        case .failure(let error):
            Task {
                await handleTabCreationFailure(AuthError.authFlowInvisibleTabCreationFailed)
            }
        }
    }
    
    private func setupSessionCookiesForTabs(_ tabs: [Client.Tab]) {
        guard let sessionCookie = Auth.shared.getSessionTokenCookie() else {
            return
        }
        
        for tab in tabs {
            tab.webView?.configuration.websiteDataStore.httpCookieStore.setCookie(sessionCookie)
        }
        
        EcosiaLogger.invisibleTabs.info("Session cookies configured for \(tabs.count) tabs")
    }
    
    @MainActor
    private func handleAuthStateChange(_ state: AuthState, previousState: AuthState) async {
        // Check for login completion based on auth state changes
        if case .authenticated = state, 
           previousState != state,
           isNativeAuthCompleted && !isFlowCompleted {
            
            // Check if our invisible tabs are closed (indicating session setup completion)
            checkForLoginCompletion()
        }
    }
    
    private func checkForLoginCompletion() {
        let invisibleTabs = tabLifecycleManager.getInvisibleTabs()
        let ourRemainingTabs = invisibleTabs.filter { tab in
            createdTabs.contains { $0.tabUUID == tab.tabUUID }
        }
        
        if ourRemainingTabs.isEmpty {
            handleLoginCompletion(success: true)
        }
    }
    
    private func handleLoginCompletion(success: Bool) {
        guard !isFlowCompleted else { return }
        
        isFlowCompleted = true
        
        EcosiaLogger.auth.info("Login flow completed with success: \(success)")
        callbacks?.onFlowCompleted?(success)
    }
    
    private func handleTabCreationFailure(_ error: AuthError) async {
        EcosiaLogger.auth.error("Tab creation failed, cleaning up credentials")
        
        // Clean up credentials since login partially succeeded but flow failed
        await cleanupCredentialsOnError()
        await handleAuthenticationFailure(error)
    }
    
    private func cleanupCredentialsOnError() async {
        EcosiaLogger.auth.notice("Cleaning up credentials due to login flow error")
        
        do {
            try await authProvider.logout()
            authStateManager.completeLogout()
            EcosiaLogger.auth.info("Successfully cleaned up credentials after login error")
        } catch {
            EcosiaLogger.auth.error("Failed to clean up credentials after login error: \(error)")
        }
    }
    
    @MainActor
    private func handleAuthenticationFailure(_ error: AuthError) async {
        guard !isFlowCompleted else { return }
        
        isFlowCompleted = true
        
        authStateManager.failAuthentication(with: error)
        
        EcosiaLogger.auth.error("Login flow failed with error: \(error)")
        callbacks?.onError?(error)
    }
    
    private func mapToAuthError(_ error: Error) -> AuthError {
        // Map different error types to AuthError
        if let authError = error as? AuthError {
            return authError
        }
        
        // Map other known error types
        return .unknown(error.localizedDescription)
    }
} 