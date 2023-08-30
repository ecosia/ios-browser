// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

enum CustomizableNTPSettingConfig: CaseIterable {
    case topSites
    case climateImpact
    case ecosiaNews

    var localizedTitleKey: String.Key {
        switch self {
        case .topSites: return .topSites
        case .climateImpact: return .climateImpact
        case .ecosiaNews: return .ecosiaNews
        }
    }
    
    var persistedFlag: Bool {
        get {
            switch self {
            case .topSites: return User.shared.showTopSites
            case .climateImpact: return User.shared.showClimateImpact
            case .ecosiaNews: return User.shared.showEcosiaNews
            }
        }
        set {
            switch self {
            case .topSites: User.shared.showTopSites = newValue
            case .climateImpact: return User.shared.showClimateImpact = newValue
            case .ecosiaNews: return User.shared.showEcosiaNews = newValue
            }
        }
    }
}
