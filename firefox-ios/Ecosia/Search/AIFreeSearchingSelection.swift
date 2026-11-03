// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Notification.Name {
    /// Posted when AI-free searching turns on or off, from Settings or from the web (`ECNOAI`).
    public static let aiFreeSearchingChanged = Notification.Name("aiFreeSearchingChanged")
}

/// Central gating hook for AI-free searching.
///
/// `isActive` is true only when the Unleash flag is on **and** the user has
/// enabled the Settings toggle. Omnibox AI surfaces (upload/+, AI Chat
/// suggestion row, chat modes, attachment-to-chat routing) must consult
/// `allowsOmniboxAI`.
///
/// Dependent settings are only greyed out in Settings. Their values are carried
/// unchanged and web applies the exclusion where they are used.
///
/// It also takes the place of Firefox's AI controls hub: turning it on switches
/// page summaries and translations off, and `showsBrowserAISettings` lists their
/// settings under the toggle so the user can turn either back on.
public enum AIFreeSearchingSelection {

    /// Flag on AND user toggle on (`User.shared.aiFreeSearching == true`).
    public static var isActive: Bool {
        AIFreeSearchingFeatureFlag.isEnabled && User.shared.aiFreeSearching == true
    }

    /// Inverse of `isActive`. Gate omnibox AI surfaces (upload/+, AI Chat
    /// suggestion row, chat modes, attachment-to-chat routing) on this.
    public static var allowsOmniboxAI: Bool { !isActive }

    /// Whether Settings offers the toggle: flag on, and Ecosia is the search
    /// provider (with a custom provider, AI-free searching does not apply).
    public static var isAvailable: Bool {
        AIFreeSearchingFeatureFlag.isEnabled
            && !(CustomSearchProviderFeatureFlag.isEnabled && !User.shared.isEcosiaSearchProvider)
    }

    /// Whether Settings lists page summaries and translations under the toggle
    /// (offered and on). Otherwise they are in General settings, as in Firefox.
    public static var showsBrowserAISettings: Bool {
        isAvailable && User.shared.aiFreeSearching == true
    }

    /// Writes the preference (`true` / `false` from Settings or the `ECNOAI` cookie, or `nil` to
    /// unset) and posts `aiFreeSearchingChanged` when that turns AI-free searching on or off.
    public static func setEnabled(_ enabled: Bool?) {
        let wasOn = User.shared.aiFreeSearching == true
        User.shared.aiFreeSearching = enabled
        guard wasOn != (enabled == true) else { return }
        NotificationCenter.default.post(name: .aiFreeSearchingChanged, object: nil)
    }
}
