// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Result of logout coordination operations
public enum LogoutResult {
    case success
    case failure(AuthError)
}

/// Callback types for logout flow events
public struct LogoutCallbacks {
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

/// Coordinates the complete logout authentication flow
/// Handles native Auth0 logout, web-side cleanup, and invisible tab management
public final class LogoutCoordinator: AuthStateObserver {
    
    // MARK: - Properties
    
    /// Dependencies
    private let authProvider: Ecosia.Auth
    private let tabLifecycleManager: TabLifecycleManaging
    private let authStateManager: AuthStateManager
    
    /// Configuration
    private let delayedCompletionTime: TimeInterval
    private let fallbackTimeout: TimeInterval
    
    /// Flow state
    private var isNativeAuthCompleted = false
    private var isFlowCompleted = false
    private var callbacks: LogoutCallbacks?
    private var createdTabs: [Client.Tab] = []
    private var fallbackTimer: DispatchWorkItem?
    
    // MARK: - Initialization
    
    /// Initializes the logout coordinator
    /// - Parameters:
    ///   - authProvider: Auth provider for authentication operations
    ///   - tabLifecycleManager: Manager for tab operations
    ///   - authStateManager: Manager for auth state coordination
    ///   - delayedCompletionTime: Optional delay before calling native auth completed callback
    ///   - fallbackTimeout: Timeout for fallback completion if tabs don't auto-close
    public init(
        authProvider: Ecosia.Auth,
        tabLifecycleManager: TabLifecycleManaging,
        authStateManager: AuthStateManager,
        delayedCompletionTime: TimeInterval = 0.0,
        fallbackTimeout: TimeInterval = 15.0
    ) {
        self.authProvider = authProvider
        self.tabLifecycleManager = tabLifecycleManager
        self.authStateManager = authStateManager
        self.delayedCompletionTime = delayedCompletionTime
        self.fallbackTimeout = fallbackTimeout
        
        // Register as observer for auth state changes
        authStateManager.addObserver(self)
        
        EcosiaLogger.auth.info("LogoutCoordinator initialized")
    }
    
    deinit {
        authStateManager.removeObserver(self)
        fallbackTimer?.cancel()
    }
    
    // MARK: - Public API
    
    /// Starts the logout flow with callbacks
    /// - Parameter callbacks: Callbacks for flow events
    public func startLogout(callbacks: LogoutCallbacks) async -> LogoutResult {
        self.callbacks = callbacks
        
        // Reset state
        isNativeAuthCompleted = false
        isFlowCompleted = false
        createdTabs.removeAll()
        fallbackTimer?.cancel()
        
        EcosiaLogger.auth.info("Starting logout flow")
        authStateManager.beginLogout()
        
        do {
            // Perform native Auth0 logout
            try await performNativeLogout()
            
            // Handle successful native logout
            await handleNativeLogoutSuccess()
            
            return .success
            
        } catch {
            let authError = mapToAuthError(error)
            await handleLogoutFailure(authError)
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
    
    private func performNativeLogout() async throws {
        EcosiaLogger.auth.info("Performing native Auth0 logout")
        try await authProvider.logout()
        EcosiaLogger.auth.info("Native Auth0 logout completed successfully")
    }
    
    @MainActor
    private func handleNativeLogoutSuccess() async {
        isNativeAuthCompleted = true
        
        // Call native auth completed callback with optional delay
        if delayedCompletionTime > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayedCompletionTime) { [weak self] in
                self?.callbacks?.onNativeAuthCompleted?()
            }
        } else {
            callbacks?.onNativeAuthCompleted?()
        }
        
        // Start web-side logout cleanup
        await performWebSideLogoutCleanup()
    }
    
    private func performWebSideLogoutCleanup() async {
        EcosiaLogger.auth.info("Starting web-side logout cleanup")
        
        // Clean up any existing invisible tabs first
        await cleanupExistingInvisibleTabs()
        
        // Create logout tabs for web-side cleanup
        await MainActor.run {
            createLogoutTabs()
        }
        
        // Set up fallback timeout
        setupFallbackTimeout()
    }
    
    private func cleanupExistingInvisibleTabs() async {
        let existingInvisibleTabs = tabLifecycleManager.getInvisibleTabs()
        
        if !existingInvisibleTabs.isEmpty {
            EcosiaLogger.invisibleTabs.info("Cleaning up \(existingInvisibleTabs.count) existing invisible tabs")
            
            let filter = TabFilter(
                tabUUIDs: existingInvisibleTabs.map { $0.tabUUID },
                isInvisible: true
            )
            
            tabLifecycleManager.cleanupTabs(matching: filter)
        }
    }
    
    @MainActor
    private func createLogoutTabs() {
        // Create logout URLs for web-side cleanup
        let logoutURLs = createLogoutURLs()
        
        guard !logoutURLs.isEmpty else {
            EcosiaLogger.auth.notice("No logout URLs available, completing logout flow")
            handleLogoutCompletion(success: true)
            return
        }
        
        EcosiaLogger.invisibleTabs.info("Creating \(logoutURLs.count) logout tabs for web-side cleanup")
        
        let config = TabConfig(
            urls: logoutURLs,
            isPrivate: false,
            autoClose: true,
            autoCloseTimeout: 10.0
        )
        
        let result = tabLifecycleManager.createInvisibleTabs(config: config) { [weak self] tabs in
            EcosiaLogger.invisibleTabs.info("Created \(tabs.count) logout tabs")
            self?.createdTabs = tabs
        }
        
        switch result {
        case .success(let tabs):
            createdTabs = tabs
            EcosiaLogger.invisibleTabs.info("Successfully created \(tabs.count) logout tabs")
            
        case .partialSuccess(let tabs, let warnings):
            createdTabs = tabs
            for warning in warnings {
                EcosiaLogger.invisibleTabs.notice("Logout tab creation warning: \(warning)")
            }
            
        case .failure:
            EcosiaLogger.auth.notice("Failed to create logout tabs, completing logout anyway")
            handleLogoutCompletion(success: true)
        }
    }
    
    private func createLogoutURLs() -> [URL] {
        var urls: [URL] = []
        
        // Add Ecosia logout URL
        if let logoutURL = URL(string: "\(Environment.current.urlProvider.root)/logout") {
            urls.append(logoutURL)
        }
        
        // Add other logout URLs as needed for different services
        // This can be expanded based on requirements
        
        return urls
    }
    
    private func setupFallbackTimeout() {
        fallbackTimer?.cancel()
        
        let fallbackWorkItem = DispatchWorkItem { [weak self] in
            EcosiaLogger.auth.info("Logout fallback timeout reached")
            self?.handleLogoutTimeout()
        }
        
        fallbackTimer = fallbackWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + fallbackTimeout, execute: fallbackWorkItem)
        
        EcosiaLogger.auth.info("Setup logout fallback timeout of \(fallbackTimeout) seconds")
    }
    
    @MainActor
    private func handleAuthStateChange(_ state: AuthState, previousState: AuthState) async {
        // Check for logout completion based on auth state changes
        if case .loggedOut = state,
           previousState != state,
           isNativeAuthCompleted && !isFlowCompleted {
            
            checkForLogoutCompletion()
        }
    }
    
    private func checkForLogoutCompletion() {
        let invisibleTabs = tabLifecycleManager.getInvisibleTabs()
        let ourRemainingTabs = invisibleTabs.filter { tab in
            createdTabs.contains { $0.tabUUID == tab.tabUUID }
        }
        
        if ourRemainingTabs.isEmpty {
            handleLogoutCompletion(success: true)
        }
    }
    
    private func handleLogoutTimeout() {
        // Cancel auto-close for any remaining logout tabs
        let tabUUIDs = createdTabs.map { $0.tabUUID }
        tabLifecycleManager.cancelAutoClose(for: tabUUIDs)
        
        // Force cleanup remaining tabs
        let filter = TabFilter(tabUUIDs: tabUUIDs, isInvisible: true)
        tabLifecycleManager.cleanupTabs(matching: filter)
        
        EcosiaLogger.auth.info("Logout completed after fallback timeout")
        handleLogoutCompletion(success: true)
    }
    
    private func handleLogoutCompletion(success: Bool) {
        guard !isFlowCompleted else { return }
        
        isFlowCompleted = true
        fallbackTimer?.cancel()
        
        // Update auth state
        authStateManager.completeLogout()
        
        EcosiaLogger.auth.info("Logout flow completed with success: \(success)")
        callbacks?.onFlowCompleted?(success)
    }
    
    @MainActor
    private func handleLogoutFailure(_ error: AuthError) async {
        guard !isFlowCompleted else { return }
        
        isFlowCompleted = true
        fallbackTimer?.cancel()
        
        // Even if native logout fails, we should still try to clear local state
        authStateManager.completeLogout()
        
        EcosiaLogger.auth.error("Logout flow failed with error: \(error)")
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