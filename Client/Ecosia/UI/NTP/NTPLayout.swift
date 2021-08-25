/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class NTPLayout: UICollectionViewFlowLayout {

    private var emptyHeight: CGFloat = 0
    private var totalHeight: CGFloat = 0

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attr = super.layoutAttributesForElements(in: rect) else { return nil}

        var libMinY: CGFloat = 0
        var impactMaxY: CGFloat = 0

        // find lib cell
        if let impact = attr.first(where: { $0.representedElementCategory == .cell && $0.indexPath.section == FirefoxHomeViewController.Section.libraryShortcuts.rawValue  }) {

            libMinY = impact.frame.minY
            debugPrint("libMinY: \(libMinY)")
        }

        // find impact cell
        if let impact = attr.first(where: { $0.representedElementCategory == .cell && $0.indexPath.section == FirefoxHomeViewController.Section.impact.rawValue  }) {

            impactMaxY = impact.frame.maxY
            debugPrint("impactMaxY: \(impactMaxY)")
        }

        // find empty cell
        if let emptyIndex = attr.firstIndex(where: { $0.representedElementCategory == .cell && $0.indexPath.section == FirefoxHomeViewController.Section.emptySpace.rawValue  }) {

            let frameHeight = collectionView?.frame.height ?? 0
            let height = frameHeight - impactMaxY + libMinY - FirefoxHomeUX.ScrollSearchBarOffset
            emptyHeight = max(0, height)
            debugPrint("Empty Height: \(height)")

            let element = attr[emptyIndex]
            element.frame = .init(origin: element.frame.origin, size: .init(width: element.frame.width, height: height))
            totalHeight = element.frame.maxY
        }
        return attr
    }

    override var collectionViewContentSize: CGSize {
        let size = super.collectionViewContentSize
        return .init(width: size.width, height: totalHeight)
    }
}
