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
    
    static var variantName: String {
        Unleash.getVariant(.climateImpactCTA).name
    }
    
    static var actionText: String {
        switch variantName {
        case "copy1":
            return .localized(.climateImpactCTAExperimentText1)
        case "copy2":
            return .localized(.climateImpactCTAExperimentText2)
        default:
            return .localized(.climateImpactCTAExperimentText1)
        }
    }
    
    static var analyticsProperty: String {
        switch variantName {
        case "copy1":
            return "first_copy"
        case "copy2":
            return "second_copy"
        default:
            return "unknown_copy"
        }
    }
    
    static let trackExperimentImpressionKey = "climateImpactCTAExperimentImpressionKey"
    /// Send `climateImpactCTA` Analytics view event, but just the first time it's called.
    static func trackExperimentImpression() {
        guard !UserDefaults.standard.bool(forKey: Self.trackExperimentImpressionKey) else {
            return
        }
        Analytics.shared.ntpClimateImpactCTAExperiment(.view)
        UserDefaults.standard.setValue(true, forKey: Self.trackExperimentImpressionKey)
    }
}
