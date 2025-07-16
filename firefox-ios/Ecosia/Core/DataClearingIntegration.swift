// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Utility for integrating native authentication with browser data clearing operations
/// Ensures authentication state remains consistent when user data is cleared
public enum DataClearingIntegration {
    
    /// Handles native logout when cookies are cleared through browser settings
    /// Should be called whenever cookies are cleared to maintain auth state consistency
    public static func handleCookieClearing() async {
        guard Auth.shared.isLoggedIn else {
            EcosiaLogger.auth("User not logged in - skipping logout on cookie clearing")
            return
        }
        
        EcosiaLogger.auth("Triggering native logout due to cookie clearing")
        
        do {
            // Perform logout without triggering web logout since cookies are already being cleared
            try await Auth.shared.logout(triggerWebLogout: false)
            EcosiaLogger.auth("Native logout completed successfully during cookie clearing")
        } catch {
            EcosiaLogger.auth("Failed to perform native logout during cookie clearing: \(error)", level: .error)
        }
    }
} 