// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Notification names for authentication state changes
extension Notification.Name {
    /// Posted when authentication state changes for any window
    /// UserInfo contains: windowUUID, authState, actionType
    public static let EcosiaAuthStateChanged = Notification.Name("EcosiaAuthStateChanged")
    
    /// Posted when user successfully logs in with session token (legacy compatibility)
    public static let EcosiaAuthDidLoginWithSessionToken = Notification.Name("EcosiaAuthDidLoginWithSessionToken")
    
    /// Posted when user logs out (legacy compatibility)
    public static let EcosiaAuthDidLogout = Notification.Name("EcosiaAuthDidLogout")
    
    /// Posted when auth state is ready and loaded (legacy compatibility)
    public static let EcosiaAuthStateReady = Notification.Name("EcosiaAuthStateReady")
    
    /// Posted when web logout should be triggered (legacy compatibility)
    public static let EcosiaAuthShouldLogoutFromWeb = Notification.Name("EcosiaAuthShouldLogoutFromWeb")
} 