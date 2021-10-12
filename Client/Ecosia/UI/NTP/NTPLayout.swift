/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class NTPLayout: UICollectionViewFlowLayout {

    private var totalHeight: CGFloat = 0

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attr = super.layoutAttributesForElements(in: rect) else { return nil}

        var searchMaxY: CGFloat = 0
        var impactMaxY: CGFloat = 0

        // find search cell
        if let search = attr.first(where: { $0.representedElementCategory == .cell && $0.indexPath.section == FirefoxHomeViewController.Section.search.rawValue  }) {
            searchMaxY = search.frame.maxY
        }

        // find impact cell
        if let impact = attr.first(where: { $0.representedElementCategory == .cell && $0.indexPath.section == FirefoxHomeViewController.Section.impact.rawValue  }) {
            impactMaxY = impact.frame.maxY
        }

        // find and update empty cell
        if let emptyIndex = attr.firstIndex(where: { $0.representedElementCategory == .cell && $0.indexPath.section == FirefoxHomeViewController.Section.emptySpace.rawValue  }) {

            let frameHeight = collectionView?.frame.height ?? 0
            var height = frameHeight - impactMaxY + searchMaxY - FirefoxHomeUX.ScrollSearchBarOffset
            height = max(0, height)

            // update frame
            let element = attr[emptyIndex]
            totalHeight = element.frame.origin.y + height
        }
        return attr
    }

    override var collectionViewContentSize: CGSize {
        let size = super.collectionViewContentSize
        return .init(width: size.width, height: totalHeight)
    }
}
