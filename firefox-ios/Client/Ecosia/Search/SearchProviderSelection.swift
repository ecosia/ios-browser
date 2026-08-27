// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

/// How the AI entry points behave for the active default search provider.
enum SearchProviderAIBehavior: Equatable {
    /// No AI entry point, either because the configuration hides it or because AI-free
    /// searching is on.
    case hidden
    /// Ecosia AI Chat, with file upload and backend chat modes.
    case ecosiaFullStack
    /// Third-party provider with prompt-enhanced chat modes and an upload redirect.
    case providerAI(SearchProvider)
    /// The entry point goes straight to the provider's AI, Ecosia included.
    case redirect(SearchProvider)
}

extension SearchProviderAIBehavior {
    /// The provider the entry point acts on, or `nil` when there is no entry point.
    var provider: SearchProvider? {
        switch self {
        case .hidden: return nil
        case .ecosiaFullStack: return .ecosia
        case .providerAI(let provider), .redirect(let provider): return provider
        }
    }
}

/// Keeps `User.shared.selectedSearchEngineID` in sync with the active default search engine.
/// Used by analytics, omnibox gating, and Ecosia-only settings visibility.
enum SearchProviderSelection {

    static let ecosiaEngineID = SearchProvider.ecosia.rawValue

    /// Active provider. Ecosia when the router is off; `User.selectedProvider` handles an
    /// identifier we no longer offer.
    static var selectedProvider: SearchProvider {
        guard CustomSearchProviderFeatureFlag.isEnabled else { return .ecosia }
        return User.shared.selectedProvider
    }

    static var isEcosiaDefault: Bool {
        selectedProvider == .ecosia
    }

    static var aiBehavior: SearchProviderAIBehavior {
        let provider = selectedProvider

        // AI-free searching is Ecosia-scoped: its settings row is hidden for other
        // providers, so it must not disable an entry point the user cannot restore.
        if provider == .ecosia, !AIFreeSearchingSelection.allowsOmniboxAI { return .hidden }

        switch CustomSearchProviderFeatureFlag.config.aiMode {
        case .hidden:
            return .hidden
        case .redirect:
            return .redirect(provider)
        case .full:
            return provider == .ecosia ? .ecosiaFullStack : .providerAI(provider)
        }
    }

    static var usesEcosiaAIBackend: Bool {
        aiBehavior == .ecosiaFullStack
    }

    /// Whether the NTP omnibox should show the + / upload control.
    static var showsOmniboxAIFeatures: Bool {
        switch aiBehavior {
        case .hidden:
            return false
        case .ecosiaFullStack:
            return FileUploadFeatureFlag.isEnabled || ChatModesFeatureFlag.isEnabled
        case .providerAI:
            // Same two flags decide whether the drawer would have any content.
            return FileUploadFeatureFlag.isEnabled || ChatModesFeatureFlag.isEnabled
        case .redirect:
            return true
        }
    }

    /// Whether a chat mode can be selected. The redirect entry point skips the drawer, so
    /// no mode can be picked and any leftover selection must be cleared.
    static var allowsChatModes: Bool {
        switch aiBehavior {
        case .hidden, .redirect:
            return false
        case .ecosiaFullStack, .providerAI:
            return ChatModesFeatureFlag.isEnabled
        }
    }

    /// Whether the suggestions overlay should include an AI row. Providers whose results
    /// page is already a conversation get no separate row.
    static var showsAIAutocompleteRow: Bool {
        switch aiBehavior {
        case .hidden:
            return false
        case .ecosiaFullStack:
            return true
        case .providerAI(let provider), .redirect(let provider):
            return !provider.isAINative
        }
    }

    /// Whether Ecosia-only rows in Settings → Search should be visible.
    static var showsEcosiaSearchSettings: Bool {
        isEcosiaDefault
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
