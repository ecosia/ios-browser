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

    /// Whether Ecosia file upload is blocked because chat history / threads are off.
    public static func blocksEcosiaUploadDueToChatHistoryOptOut(
        hasOptedOutOfChatThreads: Bool,
        usesEcosiaAIBackend: Bool
    ) -> Bool {
        usesEcosiaAIBackend && hasOptedOutOfChatThreads
    }

    /// Dims the NTP + / paperclip while keeping it tappable so we can show the opt-out error.
    public static func shouldDimOmniboxUploadControlForChatHistoryOptOut(
        hasOptedOutOfChatThreads: Bool,
        usesEcosiaAIBackend: Bool
    ) -> Bool {
        blocksEcosiaUploadDueToChatHistoryOptOut(
            hasOptedOutOfChatThreads: hasOptedOutOfChatThreads,
            usesEcosiaAIBackend: usesEcosiaAIBackend
        )
    }

    /// Whether tapping the control should show the chat-history opt-out error instead of upload UI.
    public static func shouldPresentChatHistoryOptOutErrorOnUploadTap(
        hasOptedOutOfChatThreads: Bool,
        usesEcosiaAIBackend: Bool
    ) -> Bool {
        blocksEcosiaUploadDueToChatHistoryOptOut(
            hasOptedOutOfChatThreads: hasOptedOutOfChatThreads,
            usesEcosiaAIBackend: usesEcosiaAIBackend
        )
    }
}
