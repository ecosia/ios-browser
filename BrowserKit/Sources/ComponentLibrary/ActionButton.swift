// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public class ActionButton: LegacyResizableButton {
    public var touchUpAction: ((UIButton) -> Void)? {
        didSet {
            setupButton()
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:)") }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    private func setupButton() {
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }

    @objc
    func touchUpInside(sender: UIButton) {
        touchUpAction?(sender)
    }
}
