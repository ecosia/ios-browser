// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@testable import Client

/// A Nimbus layer that reports every feature flag as on.
struct AllFlagsOnNimbusLayer: NimbusFeatureFlagLayerProviding {
    func checkNimbusConfigFor(_ featureID: FeatureFlagID, with prefs: Prefs) -> Bool { true }
    func checkStartAtHomeConfiguration() -> StartAtHome { .afterFourHours }
}

/// A device set to English (US), the only language on-device summaries support without the
/// language expansion flag.
struct EnglishLocaleProvider: LocaleProvider {
    var current: Locale { Locale(identifier: "en_US") }
    var preferredLanguages: [String] { ["en-US"] }
    func languageCode() -> String? { "en" }
    func regionCode(fallback: String?) -> String { "US" }
}

extension DefaultSummarizerNimbusUtils {
    /// Summarizer utilities for a device that can (or cannot) summarize on-device, in English.
    static func make(profile: Profile, appleIntelligenceAvailable: Bool) -> DefaultSummarizerNimbusUtils {
        let userDefaults = MockUserDefaults()
        userDefaults.set(appleIntelligenceAvailable, forKey: PrefsKeys.appleIntelligenceAvailable)
        return DefaultSummarizerNimbusUtils(
            profile: profile,
            localeProvider: EnglishLocaleProvider(),
            appleIntelligenceUtil: AppleIntelligenceUtil(userDefaults: userDefaults)
        )
    }
}
