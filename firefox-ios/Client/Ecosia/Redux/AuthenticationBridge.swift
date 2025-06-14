// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Ecosia

/// Bridge class to handle Redux dispatching for authentication state
/// This allows the Ecosia framework to dispatch authentication actions to the global store
public class AuthenticationBridge {

    /// Shared instance for global access
    public static let shared = AuthenticationBridge()

    private init() {
        // Listen for Redux dispatch notifications from Ecosia framework
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReduxDispatchNotification(_:)),
            name: .EcosiaAuthReduxDispatch,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Handles Redux dispatch notification from Ecosia framework
    @objc private func handleReduxDispatchNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let isLoggedIn = userInfo["isLoggedIn"] as? Bool,
              let actionTypeRawValue = userInfo["actionType"] as? String else {
            print("🔄 AuthenticationBridge - Invalid notification userInfo")
            return
        }

        // Convert Ecosia action type to Client action type
        let actionType: AuthenticationActionType
        switch actionTypeRawValue {
        case "authStateLoaded":
            actionType = .authStateLoaded
        case "userLoggedIn":
            actionType = .userLoggedIn
        case "userLoggedOut":
            actionType = .userLoggedOut
        default:
            print("🔄 AuthenticationBridge - Unknown action type: \(actionTypeRawValue)")
            return
        }

        dispatchAuthState(isLoggedIn: isLoggedIn, actionType: actionType)
    }

    /// Dispatches authentication state changes to Redux store
    public func dispatchAuthState(isLoggedIn: Bool, actionType: AuthenticationActionType) {
        // Get all unique window UUIDs from active screens, filtering out nil values
        let windowUUIDs = Set(store.state.activeScreens.screens.compactMap { $0.windowUUID })

        // Dispatch to each window
        for windowUUID in windowUUIDs {
            let action = AuthenticationAction(
                isLoggedIn: isLoggedIn,
                windowUUID: windowUUID,
                actionType: actionType
            )
            store.dispatch(action)
        }
        print("🔄 AuthenticationBridge - Dispatched \(actionType) to Redux store for \(windowUUIDs.count) windows")
    }
}
