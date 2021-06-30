/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class AddNewTabButton: ToolbarButton {
    enum Style {
        case plain, circle
    }

    let circle = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    convenience init(style: Style) {
        self.init(frame: .zero)
        self.circle.isHidden = style != .circle
    }

    private func setup() {
        circle.isUserInteractionEnabled = false
        addSubview(circle)
        sendSubviewToBack(circle)
        applyTheme()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let height = bounds.height - 8
        circle.bounds = .init(size: .init(width: height, height: height))
        circle.layer.cornerRadius = circle.bounds.height / 2
        circle.center = .init(x: bounds.width/2, y: bounds.height/2)
    }

    override func applyTheme() {
        super.applyTheme()
        circle.backgroundColor = UIColor.theme.ecosia.personalCounterSelection
    }
}
