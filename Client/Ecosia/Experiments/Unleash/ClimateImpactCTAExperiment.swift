// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct ClimateImpactCTAExperiment {
    
    private init() {}

    static var toggleName: String {
        Unleash.Toggle.Name.climateImpactCTA.rawValue
    }

    static var isEnabled: Bool {
        Unleash.isEnabled(.climateImpactCTA)
    }
    
    static let trackExperimentImpressionKey = "climateImpactCTAExperimentImpressionKey"
    /// Send `climateImpactCTA` Analytics view event, but just the first time it's called.
    static func trackExperimentImpression() {
        guard !UserDefaults.standard.bool(forKey: Self.trackExperimentImpressionKey) else {
            return
        }
        Analytics.shared.ntp(.view, label: .climateImpactCTA)
        UserDefaults.standard.setValue(true, forKey: Self.trackExperimentImpressionKey)
    }
}
