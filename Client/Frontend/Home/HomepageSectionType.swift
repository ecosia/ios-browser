// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum HomepageSectionType: Int, CaseIterable {
    case logoHeader
    //case messageCard
    case topSites
    case libraryShortcuts
    case impact
    case emptySpace
    /* Ecosia
    case jumpBackIn
    case recentlySaved
    case historyHighlights
    case pocket
    case customizeHome
     */
    var title: String? {
        switch self {
        case .topSites: return .ASShortcutsTitle
        default: return nil
        }
    }

    var cellIdentifier: String {
        switch self {
        case .logoHeader: return LogoCell.cellIdentifier
        case .topSites: return "" // Top sites has more than 1 cell type, dequeuing is done through FxHomeSectionHandler protocol
        case .libraryShortcuts: return ASLibraryCell.cellIdentifier
        case .impact: return TreesCell.cellIdentifier
        case .emptySpace: return TreesCell.cellIdentifier


         }
    }

    static var cellTypes: [ReusableCell.Type] {
        return [LogoCell.self,
                TopSiteItemCell.self,
                EmptyTopSiteCell.self,
                ASLibraryCell.self,
                TreesCell.self,
        ]
    }

    init(_ section: Int) {
        self.init(rawValue: section)!
    }
}
