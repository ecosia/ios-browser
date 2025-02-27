/*
 Ecosia: This file replaces the one contained in Client/Frontend/Home
 It is done so that we will have minimum conflicts when major updates are needed
 */

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

enum HomepageSectionType: Int, CaseIterable {
    case accountLogin
    case climateImpactCounter
    case homepageHeader
    case libraryShortcuts
    case topSites
    case impact
    case news
    case aboutEcosia
    case ntpCustomization

    var cellIdentifier: String {
        switch self {
        case .accountLogin: return  NTPAccountLoginCell.cellIdentifier
        case .climateImpactCounter: return NTPSeedCounterCell.cellIdentifier
        case .homepageHeader: return NTPLogoCell.cellIdentifier
        case .libraryShortcuts: return NTPLibraryCell.cellIdentifier
        case .topSites: return "" // Top sites has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .impact: return NTPImpactCell.cellIdentifier
        case .news: return NTPNewsCell.cellIdentifier
        case .aboutEcosia: return NTPAboutEcosiaCell.cellIdentifier
        case .ntpCustomization: return NTPCustomizationCell.cellIdentifier
        }
    }

    static var cellTypes: [ReusableCell.Type] {
        return [
            NTPAccountLoginCell.self,
            NTPSeedCounterCell.self,
            NTPLogoCell.self,
            TopSiteItemCell.self,
            EmptyTopSiteCell.self,
            NTPLibraryCell.self,
            NTPImpactCell.self,
            NTPNewsCell.self,
            NTPAboutEcosiaCell.self,
            NTPCustomizationCell.self
        ]
    }

    init(_ section: Int) {
        self.init(rawValue: section)!
    }
}

// Ecosia
private let MinimumInsets: CGFloat = 16
extension HomepageSectionType {
    var customizableConfig: CustomizableNTPSettingConfig? {
        switch self {
        case .homepageHeader, .libraryShortcuts, .ntpCustomization, .climateImpactCounter, .accountLogin: return nil
        case .topSites: return .topSites
        case .impact: return .climateImpact
        case .aboutEcosia: return .aboutEcosia
        case .news: return .ecosiaNews
        }
    }

    func sectionInsets(_ traits: UITraitCollection,
                       topSpacing: CGFloat = 0,
                       bottomSpacing: CGFloat = 32) -> NSDirectionalEdgeInsets {
        switch self {
        case .libraryShortcuts, .topSites, .impact, .news, .aboutEcosia, .ntpCustomization, .accountLogin:
            guard let window = UIApplication.shared.windows.first(where: \.isKeyWindow) else {
                return NSDirectionalEdgeInsets(top: 0,
                                               leading: MinimumInsets,
                                               bottom: bottomSpacing,
                                               trailing: MinimumInsets)
            }
            var horizontal: CGFloat = traits.horizontalSizeClass == .regular ? 100 : 0
            let safeAreaInsets = window.safeAreaInsets.left
            horizontal += MinimumInsets + safeAreaInsets

            let orientation: UIInterfaceOrientation = window.windowScene?.interfaceOrientation ?? .portrait

            /* Ecosia: center layout in iphone landscape or regular size class */
            if traits.horizontalSizeClass == .regular || (orientation.isLandscape && traits.userInterfaceIdiom == .phone) {
                horizontal = window.bounds.width / 4
            }
            return NSDirectionalEdgeInsets(top: topSpacing,
                                           leading: horizontal,
                                           bottom: bottomSpacing,
                                           trailing: horizontal)
        case .homepageHeader, .climateImpactCounter:
            return .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
    }
}
