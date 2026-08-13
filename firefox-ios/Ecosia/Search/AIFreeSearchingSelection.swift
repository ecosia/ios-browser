// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Central gating hook for AI-free searching.
///
/// `isActive` is true only when the Unleash flag is on **and** the user has
/// enabled the Settings toggle. Omnibox AI surfaces (upload/+, AI Chat
/// suggestion row, chat modes, attachment-to-chat routing) must consult
/// `allowsOmniboxAI`.
public enum AIFreeSearchingSelection {

    /// Flag on AND user toggle on (`User.shared.aiFreeSearching == true`).
    public static var isActive: Bool {
        AIFreeSearchingFeatureFlag.isEnabled && User.shared.aiFreeSearching == true
    }

    /// Inverse of `isActive`. Gate omnibox AI surfaces (upload/+, AI Chat
    /// suggestion row, chat modes, attachment-to-chat routing) on this.
    public static var allowsOmniboxAI: Bool { !isActive }

    /// Writes the preference (`true` / `false` from Settings, or `nil` to unset)
    /// and forces Overviews off when enabling while the flag is on.
    public static func setEnabled(_ enabled: Bool?) {
        var user = User.shared
        user.aiFreeSearching = enabled
        if enabled == true, AIFreeSearchingFeatureFlag.isEnabled {
            user.aiOverviews = false
        }
        User.shared = user
    }

    /// If AI-free is active, force Overviews off so `ECAIO=false` is written.
    public static func enforceOverviewsExclusionIfNeeded() {
        guard isActive, User.shared.aiOverviews else { return }
        User.shared.aiOverviews = false
    }
}
