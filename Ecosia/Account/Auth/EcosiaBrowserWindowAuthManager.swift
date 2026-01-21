// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Main authentication state manager that provides Redux-like state management
/// This system manages authentication state for multiple browser windows independently
/// Swift Concurrency-safe actor replacing DispatchQueue with actor isolation
public actor EcosiaBrowserWindowAuthManager {

    /// Shared instance for global access
    public static let shared = EcosiaBrowserWindowAuthManager()

    /// Actor-isolated storage for window-specific authentication states
    private var windowStates: [WindowUUID: AuthWindowState] = [:]

    /// Notification center for broadcasting state changes
    private let notificationCenter = NotificationCenter.default

    private init() {
        EcosiaLogger.auth.info("EcosiaBrowserWindowAuthManager initialized")
    }

    // MARK: - State Management

    /// Get current authentication state for a specific window
    /// - Parameter windowUUID: The window UUID to get state for
    /// - Returns: AuthWindowState if available, nil otherwise
    public func getAuthState(for windowUUID: WindowUUID) -> AuthWindowState? {
        return windowStates[windowUUID]
    }

    /// Get authentication states for all windows
    /// - Returns: Dictionary of window UUIDs to their auth states
    public func getAllAuthStates() -> [WindowUUID: AuthWindowState] {
        return windowStates
    }

    /// Dispatch an authentication action for a specific window
    /// - Parameters:
    ///   - action: The authentication action to dispatch
    ///   - windowUUID: The window UUID to dispatch the action for
    public func dispatch(action: AuthStateAction, for windowUUID: WindowUUID) {
        let currentState = windowStates[windowUUID]
        let newState = reduce(currentState: currentState, action: action)

        windowStates[windowUUID] = newState

        // Broadcast state change on main thread
        Task { @MainActor in
            notificationCenter.post(
                name: .EcosiaAuthStateChanged,
                object: self,
                userInfo: [
                    "windowUUID": windowUUID,
                    "authState": newState,
                    "actionType": action.type
                ]
            )
        }

        EcosiaLogger.auth.debug("Dispatched \(action.type.rawValue) for window \(windowUUID)")
    }

    /// Dispatch authentication state changes to all registered windows
    /// - Parameters:
    ///   - isLoggedIn: Current login status
    ///   - actionType: Type of authentication action
    public func dispatchAuthState(isLoggedIn: Bool, actionType: EcosiaAuthActionType) async {
        let windowUUIDs = await EcosiaAuthWindowRegistry.shared.registeredWindows

        for windowUUID in windowUUIDs {
            let action = AuthStateAction(
                type: actionType,
                windowUUID: windowUUID,
                isLoggedIn: isLoggedIn
            )
            dispatch(action: action, for: windowUUID)
        }

        EcosiaLogger.auth.debug("Dispatched \(actionType.rawValue) to \(windowUUIDs.count) windows")
    }

    // MARK: - State Reduction

    /// Reduce current state with an action to produce new state
    /// - Parameters:
    ///   - currentState: Current authentication state (can be nil)
    ///   - action: Action to apply to the state
    /// - Returns: New authentication state
    private func reduce(currentState: AuthWindowState?, action: AuthStateAction) -> AuthWindowState {
        let existingState = currentState ?? AuthWindowState(
            windowUUID: action.windowUUID,
            isLoggedIn: false,
            authStateLoaded: false
        )

        switch action.type {
        case .authStateLoaded:
            return AuthWindowState(
                windowUUID: action.windowUUID,
                isLoggedIn: action.isLoggedIn ?? false,
                authStateLoaded: true,
                lastUpdated: action.timestamp
            )

        case .userLoggedIn:
            return AuthWindowState(
                windowUUID: action.windowUUID,
                isLoggedIn: true,
                authStateLoaded: existingState.authStateLoaded,
                lastUpdated: action.timestamp
            )

        case .userLoggedOut:
            return AuthWindowState(
                windowUUID: action.windowUUID,
                isLoggedIn: false,
                authStateLoaded: existingState.authStateLoaded,
                lastUpdated: action.timestamp
            )
        }
    }

    // MARK: - State Subscription

    /// Subscribe to authentication state changes
    /// - Parameters:
    ///   - observer: Object that will observe the changes
    ///   - selector: Selector method to call on state change
    public func subscribe(observer: AnyObject, selector: Selector) {
        Task { @MainActor in
            notificationCenter.addObserver(
                observer,
                selector: selector,
                name: .EcosiaAuthStateChanged,
                object: self
            )
        }
    }

    /// Unsubscribe from authentication state changes
    /// - Parameter observer: Object to remove from observations
    public func unsubscribe(observer: AnyObject) {
        Task { @MainActor in
            notificationCenter.removeObserver(observer, name: .EcosiaAuthStateChanged, object: self)
        }
    }

    // MARK: - Cleanup

    /// Remove state for a specific window
    /// - Parameter windowUUID: Window UUID to remove state for
    public func removeWindowState(for windowUUID: WindowUUID) {
        windowStates.removeValue(forKey: windowUUID)
        EcosiaLogger.auth.debug("Removed state for window \(windowUUID)")
    }

    /// Clear all window states (for testing/cleanup)
    public func clearAllStates() {
        windowStates.removeAll()
        EcosiaLogger.auth.debug("Cleared all states")
    }
}
