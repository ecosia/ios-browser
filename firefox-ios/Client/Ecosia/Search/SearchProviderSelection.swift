// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

/// How AI entry points behave for the active default search provider.
enum SearchProviderAIBehavior: Equatable {
    /// Ecosia AI Chat, file upload, and chat modes.
    case ecosiaFullStack
    /// Google AI Mode / Gemini redirect — no Ecosia upload pipeline.
    case googleGemini
    /// No omnibox AI affordances (Bing, DuckDuckGo, Perplexity, etc.).
    case disabled
}

/// Keeps `User.shared.selectedSearchEngineID` in sync with the active default search engine.
/// Used by analytics, omnibox gating, and Ecosia-only settings visibility.
enum SearchProviderSelection {

    static let ecosiaEngineID = "ecosia"
    static let googleEngineID = "google"

    static var isEcosiaDefault: Bool {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return true }
        return User.shared.selectedSearchEngineID == ecosiaEngineID
    }

    static var aiBehavior: SearchProviderAIBehavior {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return .ecosiaFullStack }
        switch User.shared.selectedSearchEngineID {
        case ecosiaEngineID:
            return .ecosiaFullStack
        case googleEngineID:
            return .googleGemini
        default:
            return .disabled
        }
    }

    static var usesEcosiaAIBackend: Bool {
        aiBehavior == .ecosiaFullStack
    }

    /// Whether the NTP omnibox should show the + / upload control.
    static var showsOmniboxAIFeatures: Bool {
        switch aiBehavior {
        case .disabled:
            return false
        case .ecosiaFullStack:
            return FileUploadFeatureFlag.isEnabled || ChatModesFeatureFlag.isEnabled
        case .googleGemini:
            return true
        }
    }

    /// Whether the suggestions overlay should include an AI row.
    static var showsAIAutocompleteRow: Bool {
        aiBehavior != .disabled
    }

    /// Whether Ecosia-only rows in Settings → Search should be visible.
    static var showsEcosiaSearchSettings: Bool {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return true }
        return isEcosiaEngineID(User.shared.selectedSearchEngineID)
    }

    /// Keeps persisted provider state aligned with the active default engine before building
    /// the settings section. Resets to Ecosia when the feature flag is off.
    static func prepareSearchSettingsSection(defaultEngineID: String?) {
        guard CustomSearchProviderFeatureFlag.isEnabled else {
            syncSelectedEngineID(ecosiaEngineID)
            return
        }
        syncSelectedEngineID(defaultEngineID)
    }

    static func isEcosiaEngineID(_ engineID: String) -> Bool {
        engineID == ecosiaEngineID
    }

    static func syncSelectedEngineID(_ engineID: String?) {
        guard CustomSearchProviderFeatureFlag.isEnabled else {
            if User.shared.selectedSearchEngineID != ecosiaEngineID {
                User.shared.selectedSearchEngineID = ecosiaEngineID
            }
            return
        }

        let resolvedID = engineID ?? ecosiaEngineID
        guard User.shared.selectedSearchEngineID != resolvedID else { return }
        User.shared.selectedSearchEngineID = resolvedID
    }

    /// Records a Snowplow event when the user returns from the search provider picker
    /// with a different default engine than when they opened it.
    static func recordSearchProviderChangedIfNeeded(from previousEngineID: String, to newEngineID: String) {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return }
        guard previousEngineID != newEngineID else { return }
        Analytics.shared.searchProviderChanged(to: newEngineID)
    }
}
