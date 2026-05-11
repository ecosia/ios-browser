// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import UIKit

final class PrivateModeButton: ToggleButton, PrivateModeUI {
    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = .TabsTray.TabTrayToggleAccessibilityLabel
        /* Ecosia: Use Ecosia incognito icon instead of Firefox private mode mask
        let maskImage = UIImage(named: StandardImageIdentifiers.Large.privateMode)?
            .withRenderingMode(.alwaysTemplate)
         */
        let maskImage = UIImage(named: "incognito", in: .ecosia, with: nil)?
            .withRenderingMode(.alwaysTemplate)
        setImage(maskImage, for: [])
        showsLargeContentViewer = true
        largeContentTitle = .TabsTray.TabTrayToggleAccessibilityLabel
        largeContentImage = maskImage
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyUIMode(isPrivate: Bool, theme: Theme) {
        let colors = theme.colors
        isSelected = isPrivate

        /* Ecosia: Use iconPrimary (Ecosia's own token) for both states. Firefox's iconOnColor
           falls back to LightGrey05 (#fbfbfe), which is near-white and invisible against
           the light-mode toolbar background when private mode is active.
        tintColor = isPrivate ? colors.iconOnColor : colors.iconPrimary
        imageView?.tintColor = tintColor
         */
        tintColor = colors.iconPrimary
        imageView?.tintColor = tintColor

        if isSelected {
            accessibilityValue = .TabsTray.TabTrayToggleAccessibilityValueOn
        } else {
            accessibilityValue = .TabsTray.TabTrayToggleAccessibilityValueOff
        }
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        /* Ecosia: Use iconPrimary (Ecosia's own token) rather than iconOnColor — see applyUIMode.
        tintColor = isSelected ? colors.iconOnColor : colors.iconPrimary
        imageView?.tintColor = tintColor
         */
        tintColor = theme.colors.iconPrimary
        imageView?.tintColor = tintColor
    }
}
