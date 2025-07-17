// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Represents the current authentication state
public enum AuthState: Equatable {
    case idle
    case authenticating
    case authenticated(user: AuthUser)
    case authenticationFailed(error: AuthError)
    case loggingOut
    case loggedOut
}

/// User information after successful authentication
public struct AuthUser: Equatable {
    public let idToken: String?
    public let accessToken: String?
    
    public init(idToken: String?, accessToken: String?) {
        self.idToken = idToken
        self.accessToken = accessToken
    }
}

/// Authentication error types
public enum AuthError: Error, Equatable {
    case authFlowConfigurationError(String)
    case authFlowInvisibleTabCreationFailed
    case networkError(String)
    case userCancelled
    case unknown(String)
}

/// Observer protocol for authentication state changes
public protocol AuthStateObserver: AnyObject {
    func authStateDidChange(_ state: AuthState, previousState: AuthState)
}

/// Centralized manager for authentication state coordination
/// Replaces scattered notification-based communication with clean observer pattern
public final class AuthStateManager {
    
    // MARK: - Properties
    
    /// Current authentication state
    private(set) var currentState: AuthState = .idle {
        didSet {
            notifyObservers(previousState: oldValue)
        }
    }
    
    /// Registered state observers
    private var observers: [WeakObserver] = []
    
    /// Queue for thread-safe observer management
    private let observerQueue = DispatchQueue(label: "com.ecosia.authStateManager", attributes: .concurrent)
    
    /// Notification center for legacy compatibility
    private let notificationCenter: NotificationCenter
    
    // MARK: - Initialization
    
    /// Initializes the auth state manager
    /// - Parameter notificationCenter: Notification center for legacy compatibility
    public init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        EcosiaLogger.auth.info("AuthStateManager initialized")
    }
    
    // MARK: - Observer Management
    
    /// Adds an observer for authentication state changes
    /// - Parameter observer: Observer to add
    public func addObserver(_ observer: AuthStateObserver) {
        observerQueue.async(flags: .barrier) { [weak self] in
            self?.observers.append(WeakObserver(observer))
            self?.cleanupDeallocatedObservers()
        }
        
        EcosiaLogger.auth.debug("Added auth state observer")
    }
    
    /// Removes an observer from authentication state changes
    /// - Parameter observer: Observer to remove
    public func removeObserver(_ observer: AuthStateObserver) {
        observerQueue.async(flags: .barrier) { [weak self] in
            self?.observers.removeAll { $0.observer === observer }
        }
        
        EcosiaLogger.auth.debug("Removed auth state observer")
    }
    
    // MARK: - State Transitions
    
    /// Transitions to authenticating state
    public func beginAuthentication() {
        updateState(.authenticating)
    }
    
    /// Transitions to authenticated state with user data
    /// - Parameter user: Authenticated user information
    public func completeAuthentication(with user: AuthUser) {
        updateState(.authenticated(user: user))
    }
    
    /// Transitions to authentication failed state
    /// - Parameter error: Authentication error
    public func failAuthentication(with error: AuthError) {
        updateState(.authenticationFailed(error: error))
    }
    
    /// Transitions to logging out state
    public func beginLogout() {
        updateState(.loggingOut)
    }
    
    /// Transitions to logged out state
    public func completeLogout() {
        updateState(.loggedOut)
    }
    
    /// Resets to idle state
    public func reset() {
        updateState(.idle)
    }
    
    // MARK: - State Queries
    
    /// Whether currently authenticated
    public var isAuthenticated: Bool {
        if case .authenticated = currentState {
            return true
        }
        return false
    }
    
    /// Whether authentication is in progress
    public var isAuthenticating: Bool {
        return currentState == .authenticating
    }
    
    /// Whether logout is in progress
    public var isLoggingOut: Bool {
        return currentState == .loggingOut
    }
    
    /// Current authenticated user, if any
    public var currentUser: AuthUser? {
        if case .authenticated(let user) = currentState {
            return user
        }
        return nil
    }
    
    // MARK: - Private Implementation
    
    private func updateState(_ newState: AuthState) {
        let previousState = currentState
        currentState = newState
        
        EcosiaLogger.auth.info("Auth state changed: \(previousState) -> \(newState)")
        
        // Post legacy notification for backward compatibility
        postLegacyNotification(for: newState)
    }
    
    private func notifyObservers(previousState: AuthState) {
        observerQueue.async { [weak self] in
            guard let self = self else { return }
            
            let currentObservers = self.observers.compactMap { $0.observer }
            
            DispatchQueue.main.async {
                for observer in currentObservers {
                    observer.authStateDidChange(self.currentState, previousState: previousState)
                }
            }
        }
    }
    
    private func cleanupDeallocatedObservers() {
        observers.removeAll { $0.observer == nil }
    }
    
    /// Posts legacy notifications for backward compatibility during transition period
    private func postLegacyNotification(for state: AuthState) {
        let notificationName: Notification.Name = .EcosiaAuthStateChanged
        var userInfo: [String: Any] = [:]
        
        switch state {
        case .authenticating:
            userInfo[EcosiaAuthConstants.Keys.actionType] = EcosiaAuthConstants.State.authenticationStarted.rawValue
        case .authenticated:
            userInfo[EcosiaAuthConstants.Keys.actionType] = EcosiaAuthConstants.State.userLoggedIn.rawValue
        case .authenticationFailed:
            userInfo[EcosiaAuthConstants.Keys.actionType] = EcosiaAuthConstants.State.authenticationFailed.rawValue
        case .loggedOut:
            userInfo[EcosiaAuthConstants.Keys.actionType] = EcosiaAuthConstants.State.userLoggedOut.rawValue
        default:
            return // Don't post notifications for other states
        }
        
        notificationCenter.post(name: notificationName, object: self, userInfo: userInfo)
    }
}

// MARK: - WeakObserver

/// Weak reference wrapper for observers to prevent retain cycles
private class WeakObserver {
    weak var observer: AuthStateObserver?
    
    init(_ observer: AuthStateObserver) {
        self.observer = observer
    }
} 