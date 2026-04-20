// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Ecosia

enum ClimateImpactInfo: Equatable {
    case totalTrees(value: Int)
    case totalInvested(value: Int)

    var title: String {
        switch self {
        case .totalTrees(let value):
            return NumberFormatter.ecosiaCurrency(withoutEuroSymbol: true)
                .string(from: .init(integerLiteral: value)) ?? ""
        case .totalInvested(let value):
            return NumberFormatter.ecosiaCurrency()
                .string(from: .init(integerLiteral: value)) ?? ""
        }
    }

    var subtitle: String {
        switch self {
        case .totalTrees:
            return .localized(.treesPlantedByEcosia)
        case .totalInvested:
            return .localized(.dedicatedToClimateAction)
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .totalTrees(let value):
            return value.spelledOutString + " " + .localized(.treesPlantedByEcosia)
        case .totalInvested(let value):
            return value.spelledOutString + " " + .localized(.dedicatedToClimateAction)
        }
    }

    var accessibilityIdentifier: String? {
        switch self {
        case .totalTrees:
            EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.totalTreesCount
        case .totalInvested:
            EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.totalInvestedCount
        }
    }

    var image: UIImage? {
        switch self {
        case .totalTrees:
            return .ecosia(named: "tree")?.withRenderingMode(.alwaysTemplate)
        case .totalInvested:
            return .ecosia(named: "banknote")?.withRenderingMode(.alwaysTemplate)
        }
    }

    /// Deep-link destination for tapping this counter tile.
    /// Opens in the current tab (not a new tab) per the design spec.
    var destinationURL: URL? {
        let urlProvider = EcosiaEnvironment.current.urlProvider
        switch self {
        case .totalTrees:
            return urlProvider.trees
        case .totalInvested:
            return urlProvider.financialReports
        }
    }

    var imageAccessibilityIdentifier: String? {
        switch self {
        case .totalTrees:
            EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.totalTreesImage
        case .totalInvested:
            EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.totalInvestedImage
        }
    }

    /// Created to be used for comparison without taking the associated types arguments into consideration.
    var rawValue: Int {
        switch self {
        case .totalTrees:
            return 0
        case .totalInvested:
            return 1
        }
    }
}

extension Int {
    fileprivate var spelledOutString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter.string(from: .init(integerLiteral: self)) ?? ""
    }
}
