// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

enum ClimateImpactInfo: Equatable {
    case personalCounter(value: Int, searches: Int)
    case invites(value: Int)
    case totalTrees(value: Int)
    case totalInvested(value: Int)
    
    var title: String {
        switch self {
        case .personalCounter(let value, _):
            return "\(value)"
        case .invites(let value):
            return "\(value)"
        case .totalTrees(let value):
            return NumberFormatter.ecosiaCurrency(withoutSymbol: true)
                .string(from: .init(integerLiteral: value)) ?? ""
        case .totalInvested(let value):
            return NumberFormatter.ecosiaCurrency()
                .string(from: .init(integerLiteral: value)) ?? ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .personalCounter(_, let searches):
            return .localizedPlural(.searches, num: searches)
        case .invites(let value):
            return .localizedPlural(.friendInvitesPlural, num: value)
        case .totalTrees:
            return .localized(.treesPlantedByTheCommunity)
        case .totalInvested:
            return .localized(.investedIntoClimateAction)
        }
    }
    
    var image: UIImage? {
        switch self {
        case .personalCounter:
            return .init(named: "yourImpact")
        case .invites:
            return .init(named: "groupYourImpact")
        case .totalTrees:
            return .init(named: "hand")
        case .totalInvested:
            return .init(named: "financialReports")
        }
    }
    
    var buttonTitle: String? {
        switch self {
        case .personalCounter:
            return .localized(.howItWorks)
        case .invites:
            return .localized(.inviteFriends)
        case .totalTrees, .totalInvested:
            return nil
        }
    }
    
    var progressIndicatorValue: Double? {
        switch self {
        case .personalCounter:
            return User.shared.progress
        case .invites, .totalInvested, .totalTrees:
            return nil
        }
    }
}
