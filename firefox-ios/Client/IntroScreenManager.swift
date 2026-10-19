// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import OnboardingKit
import Ecosia

protocol IntroScreenManagerProtocol {
    var shouldShowIntroScreen: Bool { get }
    var isModernOnboardingEnabled: Bool { get }
    var shouldShowVideoIntro: Bool { get }
    var onboardingVariant: OnboardingVariant { get }
    var onboardingKitVariant: OnboardingKit.OnboardingVariant { get }
    func didSeeIntroScreen()
}

struct IntroScreenManager: FeatureFlaggable, IntroScreenManagerProtocol {
    var prefs: Prefs

    var shouldShowIntroScreen: Bool {
        /* Ecosia: Prevent welcome screen re-appearing for users upgrading from main.
         On main, welcomeDidFinish did not call didSeeIntroScreen(), so IntroSeen was
         never written. firstTime=false (set by handleFirstTimeUserActions on first
         browser load) is the reliable signal that a user has already been through the
         app — treat them as having seen the intro.
        prefs.intForKey(PrefsKeys.IntroSeen) == nil
        */
        prefs.intForKey(PrefsKeys.IntroSeen) == nil && User.shared.firstTime
    }

    func didSeeIntroScreen() {
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        // Ecosia: Keep firstTime in sync with IntroSeen so first-time-only logic (e.g. handleFirstTimeUserActions) is consistent.
        User.shared.firstTime = false
    }

    var isModernOnboardingEnabled: Bool {
        featureFlagsProvider.isEnabled(.modernOnboardingUI)
    }

    var shouldShowVideoIntro: Bool {
        featureFlagsProvider.isEnabled(.videoIntroOnboarding)
    }

    var shouldUseBrandRefreshConfiguration: Bool {
        featureFlagsProvider.isEnabled(.shouldUseBrandRefreshConfiguration)
    }

    var shouldUseJapanConfiguration: Bool {
        featureFlagsProvider.isEnabled(.shouldUseJapanConfiguration)
    }

    /// Determines the onboarding variant based on feature flags.
    ///
    /// Priority order (if multiple flags are enabled):
    /// 1. Japan configuration (highest priority)
    /// 2. Brand refresh configuration
    /// 3. Onboarding (default fallback)
    ///
    /// Note: If both `shouldUseJapanConfiguration` and `shouldUseBrandRefreshConfiguration`
    /// are enabled, Japan configuration takes precedence.
    var onboardingVariant: OnboardingVariant {
        if isModernOnboardingEnabled && shouldUseJapanConfiguration {
            return .japan
        } else if isModernOnboardingEnabled && shouldUseBrandRefreshConfiguration {
            return .brandRefresh
        } else {
            // `.modern` is the Nimbus `uiVariant` / Glean `onboarding_variant` wire value and
            // stays as-is; the OnboardingKit-side identifier is `.base` (FXIOS-16008).
            return .modern
        }
    }

    /// Returns the OnboardingKit variant corresponding to the onboarding variant.
    /// This avoids duplication of conversion logic across the codebase.
    var onboardingKitVariant: OnboardingKit.OnboardingVariant {
        return OnboardingKit.OnboardingVariant(rawValue: onboardingVariant.rawValue) ?? .base
    }
}
