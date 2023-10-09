// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ResizableButton: UIButton {

    var edgeSpacing: CGFloat = 8 {
        didSet {
            contentEdgeInsets = UIEdgeInsets(top: 0,
                                             left: edgeSpacing,
                                             bottom: 0,
                                             right: edgeSpacing)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        titleLabel?.numberOfLines = 0
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.lineBreakMode = .byWordWrapping
        contentEdgeInsets = UIEdgeInsets(top: 0,
                                         left: edgeSpacing,
                                         bottom: 0,
                                         right: edgeSpacing)
    }

    override var intrinsicContentSize: CGSize {
        guard let title = titleLabel else {
            return super.intrinsicContentSize
        }
        let size = title.intrinsicContentSize
        return CGSize(width: size.width + contentEdgeInsets.left + contentEdgeInsets.right, height: size.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let title = titleLabel else { return }

        titleLabel?.preferredMaxLayoutWidth = title.frame.size.width
    }
}
