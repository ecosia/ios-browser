/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol AutoSizingCell: UICollectionViewCell {
    func setWidth(_ width: CGFloat, insets: UIEdgeInsets)
}

class EcosiaHomeLayout: UICollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let widthChanged = newBounds.width != collectionView?.bounds.width

        if widthChanged {
            let cells = collectionView?.visibleCells.compactMap({ $0 as? AutoSizingCell })
            cells?.forEach({ cell in
                cell.setWidth(newBounds.width, insets: collectionView?.safeAreaInsets ?? .zero)
                cell.setNeedsLayout()
            })
        }
        return widthChanged
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)?.map { $0.copy() } as? [UICollectionViewLayoutAttributes]
        attributes?.reduce([CGFloat: (CGFloat, [UICollectionViewLayoutAttributes])]()) {
            guard $1.representedElementCategory == .cell else { return $0 }
            return $0.merging([ceil($1.center.y): ($1.frame.origin.y, [$1])]) {
                ($0.0 < $1.0 ? $0.0 : $1.0, $0.1 + $1.1)
            }
        }
        .values.forEach { minY, line in
            line.forEach {
                $0.frame = $0.frame.offsetBy(
                    dx: 0,
                    dy: minY - $0.frame.origin.y
                )
            }
        }
        return attributes
    }
}
