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
///
/// Dependent settings are only greyed out in Settings. Their values are carried
/// unchanged and web applies the exclusion where they are used.
///
/// It also replaces Firefox's AI controls hub: `blocksBrowserAI` switches off
/// page summaries and translations.
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

    /// Whether the browser's own AI features (page summaries, translations) are
    /// switched off. Only while the toggle is offered: a value set before the user
    /// picked another provider must not hide features they can no longer switch
    /// back on from here.
    public static var blocksBrowserAI: Bool {
        isAvailable && User.shared.aiFreeSearching == true
    }

    /// Writes the preference (`true` / `false` from Settings, or `nil` to unset).
    public static func setEnabled(_ enabled: Bool?) {
        User.shared.aiFreeSearching = enabled
    }
}
