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
}
