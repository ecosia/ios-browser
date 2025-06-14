// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

// Authentication action for managing auth state in Redux
public class AuthenticationAction: Action {
    public let isLoggedIn: Bool?

    public init(isLoggedIn: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.isLoggedIn = isLoggedIn
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

// Authentication action types
public enum AuthenticationActionType: ActionType {
    case authStateLoaded
    case userLoggedIn
    case userLoggedOut
}
