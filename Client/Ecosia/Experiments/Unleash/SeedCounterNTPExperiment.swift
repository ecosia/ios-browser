// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct SeedCounterNTPExperiment {
    private enum Variant: String {
        case control
        case test
    }
    
    private init() {}
    
    static var isEnabled: Bool {
        Unleash.isEnabled(.seedCounterNTP) && variant != .control
    }
    
    static private var variant: Variant {
        Variant(rawValue: Unleash.getVariant(.seedCounterNTP).name) ?? .control
    }
    
    // MARK: Analytics

    /// Send onboarding card view analytics event, but just the first time it's called.
    static func trackExperimentImpression() {
        let trackExperimentImpressionKey = "seedCounterNTPExperimentImpression"
        guard !UserDefaults.standard.bool(forKey: trackExperimentImpressionKey) else {
            return
        }
        Analytics.shared.ntpSeedCounterExperiment(.view)
        UserDefaults.standard.setValue(true, forKey: trackExperimentImpressionKey)
    }
}
