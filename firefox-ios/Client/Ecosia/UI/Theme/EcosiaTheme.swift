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
    var autocompleteBackground: UIColor { .Light.Background.primary }
    var welcomeBackground: UIColor { .Light.Background.tertiary }
    var welcomeElementBackground: UIColor { .Light.Background.primary }

    var homePanelBackground: UIColor { return .Light.Background.tertiary }
    var peach: UIColor { .init(rgb: 0xFFE6BF) }
}

final class DarkEcosiaTheme: EcosiaTheme {
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
