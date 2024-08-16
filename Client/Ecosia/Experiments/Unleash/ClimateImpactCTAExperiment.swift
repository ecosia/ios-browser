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
    
    static var shouldShow: Bool {
        isEnabled && Unleash.getVariant(.climateImpactCTA).name != "control"
    }

    static var actionText: String {
        switch Unleash.getVariant(.climateImpactCTA).name {
        case "test1":
            return "See where our money goes"
        case "test2":
            return "Check out our monthly updates"
        default:
            return "See where our money goes"
        }
    }
}
