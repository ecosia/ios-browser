// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

enum CustomizableNTPSettingConfig: CaseIterable {
    case topSites
    case climateImpact

    var localizedTitleKey: String.Key {
        switch self {
        case .topSites: return .topSites
        case .climateImpact: return .climateImpact
        }
    }

    var persistedFlag: Bool {
        get {
            switch self {
            case .topSites: return User.shared.showTopSites
            case .climateImpact: return User.shared.showClimateImpact
            }
        }
        set {
            switch self {
            case .topSites: User.shared.showTopSites = newValue
            case .climateImpact: User.shared.showClimateImpact = newValue
            }
        }
    }

    var analyticsLabel: Analytics.Label.NTP {
        switch self {
        case .topSites: return .topSites
        case .climateImpact: return .impact
        }
    }

    var accessibilityIdentifierPrefix: String {
        switch self {
        case .topSites: "top_sites"
        case .climateImpact: "climate_impact"
        }
    }
}
