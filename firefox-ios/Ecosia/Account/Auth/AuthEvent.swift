// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// An auth state transition, emitted once per transition by `EcosiaAuthenticationService.authEvents`.
public enum AuthEvent: Equatable, Sendable {
    case loggedIn
    case loggedOut
    /// The launch-time stored-credentials check finished.
    case stateResolved(isLoggedIn: Bool)

    public var isLoggedIn: Bool {
        switch self {
        case .loggedIn:
            return true
        case .loggedOut:
            return false
        case .stateResolved(let isLoggedIn):
            return isLoggedIn
        }
    }

    init(actionType: EcosiaAuthActionType, isLoggedIn: Bool) {
        switch actionType {
        case .userLoggedIn:
            self = .loggedIn
        case .userLoggedOut:
            self = .loggedOut
        case .authStateLoaded:
            self = .stateResolved(isLoggedIn: isLoggedIn)
        }
    }
}
