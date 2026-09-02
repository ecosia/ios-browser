// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Gates the NTP omnibox file-upload control and the Camera/Photos/Files tiles
/// from the chat-threads opt-out claim on the Auth0 ID token.
public enum OmniboxFileUploadAvailability {

    /// Whether Ecosia's in-app upload sources (Camera/Photos/Files) can be used.
    /// Other providers keep their redirect flow; they are not gated by this claim.
    public static func areSourcesEnabled(
        isEcosiaProvider: Bool,
        isAuthenticated: Bool,
        hasOptedOutOfChatThreads: Bool
    ) -> Bool {
        guard isEcosiaProvider else { return true }
        return isAuthenticated && !hasOptedOutOfChatThreads
    }

    /// Whether the NTP + / paperclip control itself stays tappable.
    /// Chat modes keeps the plus button available so modes can still be picked.
    /// Third-party upload is a site redirect, not Ecosia chat history.
    public static func isOmniboxControlEnabled(
        hasOptedOutOfChatThreads: Bool,
        isChatModesEnabled: Bool,
        usesEcosiaAIBackend: Bool
    ) -> Bool {
        if isChatModesEnabled || !usesEcosiaAIBackend { return true }
        return !hasOptedOutOfChatThreads
    }
}
