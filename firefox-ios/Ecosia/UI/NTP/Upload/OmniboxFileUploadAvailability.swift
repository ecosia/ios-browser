// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Whether the NTP omnibox upload control and in-app Camera/Photos/Files tiles are
/// available for the selected provider and the chat-threads opt-out claim on the Auth0 ID token.
public enum OmniboxFileUploadAvailability {

    /// Chat-threads opt-out and provider selection, read at omnibox, drawer, and picker entry points.
    public struct UploadInputs: Equatable, Sendable {
        public let hasOptedOutOfChatThreads: Bool
        public let usesEcosiaAIBackend: Bool

        public init(hasOptedOutOfChatThreads: Bool, usesEcosiaAIBackend: Bool) {
            self.hasOptedOutOfChatThreads = hasOptedOutOfChatThreads
            self.usesEcosiaAIBackend = usesEcosiaAIBackend
        }

        public var blocksEcosiaUploadDueToChatHistoryOptOut: Bool {
            OmniboxFileUploadAvailability.blocksEcosiaUploadDueToChatHistoryOptOut(
                hasOptedOutOfChatThreads: hasOptedOutOfChatThreads,
                usesEcosiaAIBackend: usesEcosiaAIBackend
            )
        }

        public func areInAppSourcesEnabled(isAuthenticated: Bool) -> Bool {
            OmniboxFileUploadAvailability.areSourcesEnabled(
                usesEcosiaAIBackend: usesEcosiaAIBackend,
                isAuthenticated: isAuthenticated,
                hasOptedOutOfChatThreads: hasOptedOutOfChatThreads
            )
        }
    }

    /// Whether Ecosia's in-app upload sources (Camera/Photos/Files) can be used.
    /// Third-party providers keep their redirect flow; they are not affected by this claim.
    public static func areSourcesEnabled(
        usesEcosiaAIBackend: Bool,
        isAuthenticated: Bool,
        hasOptedOutOfChatThreads: Bool
    ) -> Bool {
        guard usesEcosiaAIBackend else { return true }
        return isAuthenticated && !hasOptedOutOfChatThreads
    }

    /// Whether Ecosia file upload is blocked because chat history / threads are off.
    public static func blocksEcosiaUploadDueToChatHistoryOptOut(
        hasOptedOutOfChatThreads: Bool,
        usesEcosiaAIBackend: Bool
    ) -> Bool {
        usesEcosiaAIBackend && hasOptedOutOfChatThreads
    }
}
