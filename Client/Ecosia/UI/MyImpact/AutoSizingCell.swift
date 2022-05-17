/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol AutoSizingCell: UICollectionViewCell {
    var widthConstraint: NSLayoutConstraint! { get }
    
    func setWidth(_ width: CGFloat, insets: UIEdgeInsets)
}

extension AutoSizingCell {
    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let margin = max(max(16, insets.left), insets.right)
        widthConstraint.constant = width - 2 * margin
    }
}
