// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class EcosiaPrimaryButton: UIButton {
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            update()
        }
    }

    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            update()
        }
    }

    private func update() {
        backgroundColor = (isSelected || isHighlighted) ? .legacyTheme.ecosia.primaryButtonActive : .legacyTheme.ecosia.primaryButton
    }
}
