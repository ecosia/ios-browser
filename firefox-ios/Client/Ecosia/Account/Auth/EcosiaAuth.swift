// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

// MARK: - Constants

/// Constants for authentication flow notifications and userInfo keys
public enum EcosiaAuthConstants {

    enum Keys {
        /// Notification userInfo keys
        public static let windowUUID = "windowUUID"
        public static let authState = "authState"
        public static let actionType = "actionType"
    }

    enum State: String, CaseIterable {
        case userLoggedIn
        case userLoggedOut
        case authenticationStarted
        case authenticationFailed
    }
}

/**
 EcosiaAuth provides a high-level integration layer that orchestrates the complete authentication flow.
 
 This class bridges Auth0's onClose callback to invisible tab creation and provides a chainable API
 that handles the complete authentication sequence including session management.
 
 ## Usage
 
 ```swift 
 ecosiaAuthInstance.login()
     .onNativeAuthCompleted {
         // Called when Auth0 authentication completes (equivalent to onClose)
     }
     .onAuthFlowCompleted { success in
         // Called when entire flow completes (after invisible tabs auto-close)
     }
     .onError { error in
         // Called when authentication or flow fails with error details
     }
 ```
 */
public final class EcosiaAuth {

    // MARK: - Dependencies

    private let authProvider: Ecosia.Auth
    private let invisibleTabAPI: InvisibleTabAPIProtocol
    private let notificationCenter: NotificationCenter

    // MARK: - Flow State

    private var currentLoginFlow: AuthenticationFlow?
    private var currentLogoutFlow: AuthenticationFlow?

    /// Initializes EcosiaAuth with required dependencies
    /// - Parameters:
    ///   - invisibleTabAPI: The invisible tab API instance for tab management
    ///   - authProvider: The auth provider for authentication operations (defaults to Ecosia.Auth.shared)
    ///   - notificationCenter: The notification center for auth state changes (defaults to .default)
    init(invisibleTabAPI: InvisibleTabAPIProtocol,
         authProvider: Ecosia.Auth = Ecosia.Auth.shared,
         notificationCenter: NotificationCenter = .default) {
        self.invisibleTabAPI = invisibleTabAPI
        self.authProvider = authProvider
        self.notificationCenter = notificationCenter
    }

    // MARK: - Public API

    /// Starts the login authentication flow
    /// - Returns: AuthenticationFlow for chaining callbacks
    public func login() -> AuthenticationFlow {
        let flow = AuthenticationFlow(
            type: .login,
            ecosiaAuth: self,
            invisibleTabAPI: invisibleTabAPI,
            notificationCenter: notificationCenter
        )
        currentLoginFlow = flow
        return flow
    }

    /// Starts the logout authentication flow
    /// - Returns: AuthenticationFlow for chaining callbacks  
    public func logout() -> AuthenticationFlow {
        let flow = AuthenticationFlow(
            type: .logout,
            ecosiaAuth: self,
            invisibleTabAPI: invisibleTabAPI,
            notificationCenter: notificationCenter
        )
        currentLogoutFlow = flow
        return flow
    }

    fileprivate func performLogin() async throws {
        try await authProvider.login()
    }

    fileprivate func performLogout() async throws {
        try await authProvider.logout()
    }

    public var isLoggedIn: Bool {
        return authProvider.isLoggedIn
    }

    public var idToken: String? {
        return authProvider.idToken
    }

    public var accessToken: String? {
        return authProvider.accessToken
    }
}

// MARK: - AuthenticationFlow

/**
 Represents a chainable authentication flow that handles both native auth completion 
 and full flow completion with invisible tab management.
 
 Provides three callback types:
 - `onNativeAuthCompleted`: Called when Auth0 authentication finishes successfully
 - `onAuthFlowCompleted`: Called when the entire flow completes (including invisible tabs)
 - `onError`: Called when any error occurs during authentication or flow execution
 */
public final class AuthenticationFlow {

    public enum FlowType {
        case login
        case logout
    }

    // MARK: - Properties

    internal let type: FlowType
    private let ecosiaAuth: EcosiaAuth
    private let invisibleTabAPI: InvisibleTabAPIProtocol
    private let notificationCenter: NotificationCenter

    // MARK: - Callbacks

    private var onNativeAuthCompletedCallback: (() -> Void)?
    private var onAuthFlowCompletedCallback: ((Bool) -> Void)?
    private var onErrorCallback: ((Error) -> Void)?

    // MARK: - Flow State

    private var isNativeAuthCompleted = false
    private var isFlowCompleted = false
    private var invisibleTabs: [Client.Tab] = []
    private var authStateObserver: NSObjectProtocol?
    private var delayedCompletionTime: TimeInterval = 0.0

    // MARK: - Initialization

    internal init(type: FlowType,
                  ecosiaAuth: EcosiaAuth,
                  invisibleTabAPI: InvisibleTabAPIProtocol,
                  notificationCenter: NotificationCenter) {
        self.type = type
        self.ecosiaAuth = ecosiaAuth
        self.invisibleTabAPI = invisibleTabAPI
        self.notificationCenter = notificationCenter

        // Start the authentication process
        startAuthentication()
    }

    // MARK: - Public Chainable API

    /// Sets callback for when native Auth0 authentication completes (equivalent to onClose)
    /// - Parameter callback: Closure called when Auth0 authentication finishes
    /// - Returns: Self for chaining
    @discardableResult
    public func onNativeAuthCompleted(_ callback: @escaping () -> Void) -> AuthenticationFlow {
        onNativeAuthCompletedCallback = callback

        // If auth already completed, call immediately
        if isNativeAuthCompleted {
            callback()
        }

        return self
    }

    /// Sets callback for when the complete authentication flow finishes (including invisible tabs)
    /// - Parameter callback: Closure called with success status when entire flow completes
    /// - Returns: Self for chaining
    @discardableResult
    public func onAuthFlowCompleted(_ callback: @escaping (Bool) -> Void) -> AuthenticationFlow {
        onAuthFlowCompletedCallback = callback

        // If flow already completed, call immediately
        if isFlowCompleted {
            callback(true) // If we got this far, it was successful
        }

        return self
    }

    /// Sets callback for when an error occurs during the authentication flow
    /// - Parameter callback: Closure called with the error when authentication fails
    /// - Returns: Self for chaining
    @discardableResult
    public func onError(_ callback: @escaping (Error) -> Void) -> AuthenticationFlow {
        onErrorCallback = callback
        return self
    }
    
    /// Sets the delay before firing the onNativeAuthCompleted callback
    /// - Parameter delay: Delay in seconds before calling onNativeAuthCompleted
    /// - Returns: Self for chaining
    @discardableResult
    public func withDelayedCompletion(_ delay: TimeInterval) -> AuthenticationFlow {
        delayedCompletionTime = delay
        return self
    }

    // MARK: - Private Implementation

    private func startAuthentication() {
        Task {
            do {
                // Perform the native Auth0 authentication
                switch type {
                case .login:
                    try await ecosiaAuth.performLogin()
                case .logout:
                    try await ecosiaAuth.performLogout()
                }

                // Native auth completed successfully
                    handleNativeAuthCompletion()
            } catch {
                EcosiaLogger.auth("Authentication failed: \(error)", level: .error)
                handleFlowError(error)
            }
        }
    }

    private func handleNativeAuthCompletion() {
        EcosiaLogger.auth("Native Auth0 authentication completed")

        isNativeAuthCompleted = true
        
        // Apply delayed completion if specified
        if delayedCompletionTime > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayedCompletionTime) { [weak self] in
                self?.onNativeAuthCompletedCallback?()
            }
        } else {
            onNativeAuthCompletedCallback?()
        }

        // Handle different flows
        switch type {
        case .login:
            // For login, get session transfer token and create invisible tabs
            Task {
                await prepareSessionTransferAndCreateTabs()
            }
        case .logout:
            // For logout, clean up web-side session state
            Task {
                await performWebSideLogoutCleanup()
            }
        }
    }

    private func prepareSessionTransferAndCreateTabs() async {
        await Auth.shared.getSessionTransferToken()
        await MainActor.run {
            createInvisibleTabsForSessionManagement()
        }
    }

    private func performWebSideLogoutCleanup() async {
        EcosiaLogger.auth("Starting web-side logout cleanup")
        await cleanupExistingInvisibleTabs()
        await createLogoutTabs()
    }

    private func createInvisibleTabsForSessionManagement() {
        let signUpURL = URL(string: "\(Environment.current.urlProvider.root)/accounts/sign-up")

        // If no session management needed, this is a configuration error for login
        guard let signUpURL else {
            let error = AuthError.authFlowConfigurationError("No session management URL available")
            EcosiaLogger.auth("No session management URL available, cleaning up credentials", level: .error)

            // Clean up credentials since login partially succeeded but flow failed
            Task {
                await cleanupLoginCredentialsOnError()
                handleFlowError(error)
            }
            return
        }

        EcosiaLogger.invisibleTabs("Creating invisible tabs for session management")

        // Create invisible tabs for session management
        // Note: Session transfer token is already available in Auth.shared.ssoCredentials
        // Cookie injection will be handled by the webview when loading authentication URLs
        EcosiaLogger.invisibleTabs("Creating invisible tabs for session management with SSO support")

        invisibleTabs = invisibleTabAPI.createInvisibleTabs(
            for: [signUpURL],
            isPrivate: false,
            autoClose: true
        ) { (tabs: [Client.Tab]) in
            EcosiaLogger.invisibleTabs("Created \(tabs.count) invisible tabs for session management")
             if let sessionCookie = Auth.shared.getSessionTokenCookie() {
                 tabs.forEach { tab in
                     tab.webView?.configuration.websiteDataStore.httpCookieStore.setCookie(sessionCookie)
                 }
             }
        }

        // Check if tab creation failed
        guard !invisibleTabs.isEmpty else {
            let error = AuthError.authFlowInvisibleTabCreationFailed
            EcosiaLogger.auth("Invisible tab creation failed, cleaning up credentials", level: .error)
            Task {
                await cleanupLoginCredentialsOnError()
                handleFlowError(error)
            }
            return
        }


    }

    private func setupInvisibleTabMonitoring() {
        // Listen for auth state changes that indicate invisible tabs have closed
        authStateObserver = notificationCenter.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAuthStateChange(notification)
        }

        EcosiaLogger.tabAutoClose("Monitoring invisible tab completion")
    }

    private func handleAuthStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let actionType = userInfo[EcosiaAuthConstants.Keys.actionType] as? String else {
            return
        }

        // We're looking for the state change that indicates login is fully complete
        // This happens when invisible tabs auto-close after session setup
        let expectedActionType: EcosiaAuthConstants.State = type == .login ? .userLoggedIn : .userLoggedOut

        if actionType == expectedActionType.rawValue {
            // Check if all our invisible tabs are closed
            checkForFlowCompletion()
        }
    }



    private func checkForFlowCompletion() {
        let remainingInvisibleTabs = invisibleTabAPI.getInvisibleTabs().filter { tab in
            invisibleTabs.contains { $0.tabUUID == tab.tabUUID }
        }

        if remainingInvisibleTabs.isEmpty {
            handleFlowCompletion(success: true)
        }
    }

    private func cleanupExistingInvisibleTabs() async {
        let existingTabs = invisibleTabAPI.getInvisibleTabs()

        guard !existingTabs.isEmpty else {
            EcosiaLogger.invisibleTabs("No existing invisible tabs to clean up")
            return
        }

        // Log unexpected leftover tabs - this should rarely happen if auto-close works properly
        EcosiaLogger.auth("⚠️ Found \(existingTabs.count) leftover invisible tabs during logout - investigating auto-close behavior")

        // Log details about leftover tabs for debugging
        for (index, tab) in existingTabs.enumerated() {
            EcosiaLogger.invisibleTabs("Leftover tab \(index + 1): \(tab.tabUUID) - URL: \(tab.url?.absoluteString ?? "nil")")
        }

        // Check if TabAutoCloseManager is still tracking any of these tabs
        let trackedCount = invisibleTabAPI.getTrackedTabCount()
        EcosiaLogger.invisibleTabs("TabAutoCloseManager currently tracking \(trackedCount) tabs")

        EcosiaLogger.invisibleTabs("Starting cleanup of \(existingTabs.count) existing invisible tabs")

        // Remove session cookies from existing tabs
        if let sessionCookie = Auth.shared.getSessionTokenCookie() {
            for tab in existingTabs {
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        tab.webView?.configuration.websiteDataStore.httpCookieStore.delete(sessionCookie) {
                            EcosiaLogger.cookies("Removed session cookie from tab \(tab.tabUUID)")
                            continuation.resume()
                        }
                    }
                }
            }
        }

        // Cancel auto-close tracking for old login tabs to avoid conflicts with logout flow
        let tabUUIDs = existingTabs.map { $0.tabUUID }
        invisibleTabAPI.cancelAutoCloseForTabs(tabUUIDs)

        EcosiaLogger.invisibleTabs("Completed cleanup of existing invisible tabs")
    }

    private func createLogoutTabs() async {
        let logoutURL = URL(string: "\(Environment.current.urlProvider.root)/accounts/sign-out")

        guard let logoutURL else {
            let error = AuthError.authFlowConfigurationError("No logout URL available")
            EcosiaLogger.auth("No logout URL available, skipping logout tabs")
            handleFlowError(error)
            return
        }

        EcosiaLogger.invisibleTabs("Creating logout tabs with auto-close integration")

        // Create logout tabs that will auto-close via TabAutoCloseManager
        invisibleTabs = invisibleTabAPI.createInvisibleTabs(
            for: [logoutURL],
            isPrivate: false,
            autoClose: true
        ) { (tabs: [Client.Tab]) in
            EcosiaLogger.invisibleTabs("Created \(tabs.count) logout tabs with auto-close tracking")

            // Setup custom notification observer for logout completion
            Task { [weak self] in
                await self?.setupLogoutCompletionObserver()
            }
        }
    }

    private func setupLogoutCompletionObserver() async {
        // Listen for logout page completion or TabAutoCloseManager auto-close
        // The TabAutoCloseManager will automatically close tabs on .EcosiaAuthStateChanged

        // Set up an observer for when all invisible tabs are closed (logout complete)
        let observer = notificationCenter.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Check if this is a logout completion
            if let userInfo = notification.userInfo,
               let authState = userInfo[EcosiaAuthConstants.Keys.authState] as? String,
               authState == EcosiaAuthConstants.State.userLoggedOut.rawValue {

                EcosiaLogger.auth("Logout state change detected - completing logout flow")
                self?.handleLogoutCompletion()
            }
        }

        // Store observer for cleanup
        authStateObserver = observer

        // Also setup a fallback timeout (longer than TabAutoCloseManager's timeout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            self?.handleLogoutTimeout()
        }

        EcosiaLogger.tabAutoClose("Setup logout completion observer with TabAutoCloseManager integration")
    }

    private func handleLogoutCompletion() {
        EcosiaLogger.auth("Logout completed successfully via notification")
        handleFlowCompletion(success: true)
    }

    private func handleLogoutTimeout() {
        // Cancel auto-close tracking for any remaining logout tabs
        let tabUUIDs = invisibleTabs.map { $0.tabUUID }
        invisibleTabAPI.cancelAutoCloseForTabs(tabUUIDs)

        EcosiaLogger.auth("Logout completed after fallback timeout")
        handleFlowCompletion(success: true)
    }

    /// Cleans up stored credentials and session when login flow fails after Auth0 authentication succeeds
    private func cleanupLoginCredentialsOnError() async {
        EcosiaLogger.auth("Cleaning up credentials due to login flow error", level: .warning)

        do {
            // Clear both session and credentials to restore clean state
            try await ecosiaAuth.performLogout()
            EcosiaLogger.auth("Successfully cleaned up credentials after login error")
        } catch {
            EcosiaLogger.auth("Failed to clean up credentials after login error: \(error)", level: .error)
            // Even if cleanup fails, we still want to report the original error
        }
    }

    private func handleFlowCompletion(success: Bool) {
        guard !isFlowCompleted else { return }

        isFlowCompleted = true

        // Clean up observers
        if let observer = authStateObserver {
            notificationCenter.removeObserver(observer)
            authStateObserver = nil
        }

        EcosiaLogger.auth("Authentication flow completed with success: \(success)")
        onAuthFlowCompletedCallback?(success)
    }

    private func handleFlowError(_ error: Error) {
        guard !isFlowCompleted else { return }

        isFlowCompleted = true

        // Clean up observers
        if let observer = authStateObserver {
            notificationCenter.removeObserver(observer)
            authStateObserver = nil
        }

        EcosiaLogger.auth("Authentication flow failed with error: \(error)", level: .error)
        onErrorCallback?(error)
    }

    deinit {
        if let observer = authStateObserver {
            notificationCenter.removeObserver(observer)
        }
    }
}
