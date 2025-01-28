// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

extension LegacyTheme {
    var isDark: Bool {
        return type(of: self) == DarkTheme.self
    }
}

class EcosiaTheme {
    var segmentSelectedText: UIColor { .Light.Text.primary }
    var segmentBackground: UIColor { .Light.Background.secondary }

    var warning: UIColor { .Light.State.error }
    var information: UIColor { .Light.State.information }
    var disabled: UIColor { .Light.State.disabled }

    var tabBackground: UIColor { .Light.Background.primary }
    var tabSelectedBackground: UIColor { .Light.Button.backgroundPrimary }
    var tabSelectedPrivateBackground: UIColor { .Dark.Background.secondary }

    var toastImageTint: UIColor { .init(red: 0.847, green: 1, blue: 0.502, alpha: 1) }
    var autocompleteBackground: UIColor { .Light.Background.primary }
    var welcomeBackground: UIColor { .Light.Background.tertiary }
    var welcomeElementBackground: UIColor { .Light.Background.primary }

    var homePanelBackground: UIColor { return .Light.Background.tertiary }
    var peach: UIColor { .init(rgb: 0xFFE6BF) }
}

final class DarkEcosiaTheme: EcosiaTheme {
    override var segmentSelectedText: UIColor { UIColor.Photon.Grey90 }
    override var segmentBackground: UIColor { .Dark.Background.tertiary }

    override var warning: UIColor { .Dark.State.error }
    override var information: UIColor { .Dark.State.information }
    override var disabled: UIColor { .Dark.State.disabled }

    override var tabBackground: UIColor { .Dark.Background.tertiary }
    override var tabSelectedBackground: UIColor { .Dark.Button.backgroundPrimary }
    override var tabSelectedPrivateBackground: UIColor { .white}

    override var toastImageTint: UIColor { .init(red: 0.153, green: 0.322, blue: 0.263, alpha: 1) }
    override var autocompleteBackground: UIColor { .Dark.Background.secondary }
    override var welcomeBackground: UIColor { .Dark.Background.secondary }
    override var welcomeElementBackground: UIColor { .Dark.Background.secondary }

    override var homePanelBackground: UIColor { return .Dark.Background.secondary }
    override var peach: UIColor { .init(rgb: 0xCC7722) }
}

extension UIImage {
    convenience init?(themed name: String) {
        let suffix = LegacyThemeManager.instance.current.isDark ? "Dark" : ""
        self.init(named: name + suffix)
    }
}
