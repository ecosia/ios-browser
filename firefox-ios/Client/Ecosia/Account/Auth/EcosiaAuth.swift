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
 EcosiaAuth.shared.login()
     .onNativeAuthCompleted { 
         // Called when Auth0 authentication completes (equivalent to onClose)
     }
     .onAuthFlowCompleted { success in
         // Called when entire flow completes (after invisible tabs auto-close)
     }
 ```
 */
public class EcosiaAuth {

    // MARK: - Singleton

    public static let shared = EcosiaAuth()

    // MARK: - Dependencies

    private let authProvider: Ecosia.Auth
    private let invisibleTabAPI: InvisibleTabAPI
    private let notificationCenter: NotificationCenter

    // MARK: - Flow State

    private var currentLoginFlow: AuthenticationFlow?
    private var currentLogoutFlow: AuthenticationFlow?

    private init(authProvider: Ecosia.Auth = Ecosia.Auth.shared,
                 invisibleTabAPI: InvisibleTabAPI = InvisibleTabAPI.shared,
                 notificationCenter: NotificationCenter = .default) {
        self.authProvider = authProvider
        self.invisibleTabAPI = invisibleTabAPI
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

    // MARK: - Internal Access

    internal func performLogin() async throws {
        try await authProvider.login()
    }

    internal func performLogout() async throws {
        try await authProvider.logout()
    }

    /// Access to underlying auth state
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
 */
public class AuthenticationFlow {

    public enum FlowType {
        case login
        case logout
    }

    // MARK: - Properties

    private let type: FlowType
    private let ecosiaAuth: EcosiaAuth
    private let invisibleTabAPI: InvisibleTabAPI
    private let notificationCenter: NotificationCenter

    // MARK: - Callbacks

    private var onNativeAuthCompletedCallback: (() -> Void)?
    private var onAuthFlowCompletedCallback: ((Bool) -> Void)?

    // MARK: - Flow State

    private var isNativeAuthCompleted = false
    private var isFlowCompleted = false
    private var invisibleTabs: [Tab] = []
    private var authStateObserver: NSObjectProtocol?

    // MARK: - Initialization

    internal init(type: FlowType,
                  ecosiaAuth: EcosiaAuth,
                  invisibleTabAPI: InvisibleTabAPI,
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
                handleFlowCompletion(success: false)
            }
        }
    }

    private func handleNativeAuthCompletion() {
        EcosiaLogger.auth("Native Auth0 authentication completed")

        // TODO: [MOB-3538] Inject session transfer token cookie into invisible tabs webviews
        // Based on POC: Auth.shared.getSessionTokenCookie() should be injected into 
        // webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        // This enables seamless SSO between native auth and web authentication

        isNativeAuthCompleted = true
        onNativeAuthCompletedCallback?()

        // For logout, we're done - no invisible tabs needed
        guard type == .login else {
            handleFlowCompletion(success: true)
            return
        }

        // For login, create invisible tabs for session management
        createInvisibleTabsForSessionManagement()
    }

    private func createInvisibleTabsForSessionManagement() {

        let signUpURL = URL(string: "\(Environment.current.urlProvider.root)/accounts/sign-up")

        // If no session management needed, complete immediately
        guard let signUpURL else {
            handleFlowCompletion(success: true)
            return
        }

        EcosiaLogger.invisibleTabs("Creating invisible tabs for session management")

        // TODO: [MOB-3538] Inject session transfer token into webview configurations before creating tabs
        // Pattern: Get session cookie from Auth.shared.getSessionTokenCookie() and inject into configuration
        // Example:
        // if let sessionCookie = ecosiaAuth.getSessionTokenCookie() {
        //     let config = LegacyTabManager.makeWebViewConfig(isPrivate: false, prefs: nil)
        //     config.websiteDataStore.httpCookieStore.setCookie(sessionCookie)
        //     // Pass custom config to tab creation
        // }
        // This ensures seamless SSO between native auth and web authentication

        // Create invisible tabs using instance method consistently
        invisibleTabs = invisibleTabAPI.createInvisibleTabs(
            for: [signUpURL],
        ) { [weak self] (tabs: [Tab]) in
            EcosiaLogger.invisibleTabs("Created \(tabs.count) invisible tabs for session management")
        }

        // Setup monitoring for when all invisible tabs are closed
        setupInvisibleTabMonitoring()
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

    deinit {
        if let observer = authStateObserver {
            notificationCenter.removeObserver(observer)
        }
    }
}
