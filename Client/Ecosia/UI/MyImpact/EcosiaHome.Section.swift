/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core

extension EcosiaHome {
    enum Section: Int, CaseIterable {
        case impact, legacyImpact, multiply, news, explore

        var cell: AnyClass {
            switch self {
            case .impact: return MyImpactCell.self
            case .legacyImpact: return TreesCell.self
            case .multiply: return MultiplyImpactCell.self
            case .explore: return EcosiaExploreCell.self
            case .news: return NewsCell.self
            }
        }

        var sectionTitle: String? {
            switch self {
            case .multiply:
                return .localized(.groupYourImpact)
            case .news:
                return .localized(.stories)
            case .explore:
                return .localized(.exploreEcosia)
            default:
                return nil
            }
        }
        
        enum Explore: Int, CaseIterable {
            case info, finance, trees, faq, shop, privacy

            var title: String {
                switch self {
                case .info:
                    return .localized(.howEcosiaWorks)
                case .finance:
                    return .localized(.financialReports)
                case .trees:
                    return .localized(.trees)
                case .faq:
                    return .localized(.faq)
                case .shop:
                    return .localized(.shop)
                case .privacy:
                    return .localized(.privacy)
                }
            }

            var image: String {
                switch self {
                case .info:
                    return "networkTree"
                case .finance:
                    return "reports"
                case .trees:
                    return "treesIcon"
                case .faq:
                    return "faqIcon"
                case .shop:
                    return "shopIcon"
                case .privacy:
                    return "tigerIncognito"
                }
            }

            var url: URL {
                switch self {
                case .info:
                    return Environment.current.howEcosiaWorks
                case .finance:
                    return Environment.current.financialReports
                case .trees:
                    return Environment.current.trees
                case .faq:
                    return Environment.current.faq
                case .shop:
                    return Environment.current.shop
                case .privacy:
                    return Environment.current.privacy
                }
            }

            var label: Analytics.Label.Navigation {
                switch self {
                case .info:
                    return .howEcosiaWorks
                case .finance:
                    return .financialReports
                case .trees:
                    return .projects
                case .faq:
                    return .faq
                case .shop:
                    return .shop
                case .privacy:
                    return .privacy
                }
            }
            
            var radius: String {
                switch self {
                case .info:
                    return .localized(.howEcosiaWorks)
                case .finance:
                    return .localized(.financialReports)
                case .trees:
                    return .localized(.trees)
                case .faq:
                    return .localized(.faq)
                case .shop:
                    return .localized(.shop)
                case .privacy:
                    return .localized(.privacy)
                }
            }
        }
    }
}
