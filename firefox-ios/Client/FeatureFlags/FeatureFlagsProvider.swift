// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
// Ecosia: AI-free searching switches translations off.
import Ecosia

/// Protocol for checking whether a feature is enabled via Nimbus remote config.
protocol FeatureFlagProviding: Sendable {
    func isEnabled(_ flag: FeatureFlagID) -> Bool
    func setDebugOverride(_ flag: FeatureFlagID, to value: Bool)
}

/// Wraps NimbusFeatureFlagLayer with debug override support for beta/dev builds.
/// Registered in AppContainer; accessed via `FeatureFlagProviding` protocol.
final class FeatureFlagsProvider: FeatureFlagProviding, @unchecked Sendable {
    private let prefs: Prefs
    private let backendLayer: NimbusFeatureFlagLayerProviding

    init(
        prefs: Prefs,
        backendLayer: NimbusFeatureFlagLayerProviding = NimbusManager.shared.featureFlagLayer
    ) {
        self.prefs = prefs
        self.backendLayer = backendLayer
    }

    /// Used for checking the status of a feature flag from the feature flag backend
    func isEnabled(_ flag: FeatureFlagID) -> Bool {
        // Ecosia: Ecosia's AI-free searching toggle replaces Firefox's AI controls hub and also
        // switches translations off. Every translations gate (toolbar icon, menu, middleware,
        // contextual hint, model download at launch) checks `.translation` here.
        if flag == .translation, AIFreeSearchingSelection.blocksBrowserAI {
            return false
        }
        return backendLayer.checkNimbusConfigFor(flag, with: prefs)
    }

    /// Used specifically for overriding the status of a feature flag from the backend.
    func setDebugOverride(_ flag: FeatureFlagID, to value: Bool) {
        guard let debugKey = flag.debugKey else { return }
        prefs.setBool(value, forKey: debugKey)
    }
}

// MARK: - DI Access Protocol

/// Adopt this protocol to access Nimbus feature flags via AppContainer.
/// Replaces FeatureFlaggable for Nimbus checks.
protocol FeatureFlaggable {
    var featureFlagsProvider: FeatureFlagProviding { get }
}

extension FeatureFlaggable {
    var featureFlagsProvider: FeatureFlagProviding {
        AppContainer.shared.resolve()
    }
}
