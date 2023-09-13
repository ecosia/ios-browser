// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

enum AboutEcosiaSection: Int, CaseIterable {
    case
    financialReports,
    trees,
    privacy,
    faq
    
    var title: String {
        switch self {
        case .financialReports:
            return .localized(.financialReports)
        case .trees:
            return .localized(.treesUpdate)
        case .privacy:
            return .localized(.privacy)
        case .faq:
            return .localized(.faqs)
        }
    }
    
    var subtitle: String {
        switch self {
        case .financialReports:
            return .localized(.seeHowMuchMoney)
        case .trees:
            return .localized(.discoverWhereWe)
        case .privacy:
            return .localized(.learnHowWe)
        case .faq:
            return .localized(.findAnswersTo)
        }
    }

    var image: String {
        switch self {
        case .financialReports:
            return "financialReports"
        case .trees:
            return "treesUpdate"
        case .privacy:
            return "privacy"
        case .faq:
            return "faqs"
        }
    }

    var url: URL {
        switch self {
        case .financialReports:
            return Environment.current.urlProvider.financialReports
        case .trees:
            return Environment.current.urlProvider.trees
        case .privacy:
            return Environment.current.urlProvider.privacy
        case .faq:
            return Environment.current.urlProvider.faq
        }
    }

    var label: Analytics.Label.Navigation {
        switch self {
        case .financialReports:
            return .financialReports
        case .trees:
            return .projects
        case .privacy:
            return .privacy
        case .faq:
            return .faq
        }
    }
}
