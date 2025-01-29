// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

// TODO Ecosia Upgrade: Can we also get rid of this now that Firefox has? [MOB-3152]
extension UIColor {
    static var legacyTheme: LegacyTheme {
        return LegacyThemeManager.instance.current
    }
}

enum BuiltinThemeName: String {
    case normal
    case dark
}

class TableViewColor {
    var rowText: UIColor { return UIColor.Photon.Grey90 } // textPrimary
    var disabledRowText: UIColor { return UIColor.Photon.Grey40 } // textDisabled
    // Ecosia: Re enabling legacy colo references
    var accessoryViewTint: UIColor { return .Light.Text.secondary }
    var headerBackground: UIColor { .Light.Background.tertiary }
    var separator: UIColor { .Light.Border.decorative }
    var rowBackground: UIColor { return .Light.Background.primary }
}

protocol LegacyTheme {
    var name: String { get }
    var tableView: TableViewColor { get }
}

class LegacyNormalTheme: LegacyTheme {
    var name: String { return BuiltinThemeName.normal.rawValue }
    var tableView: TableViewColor { return TableViewColor() }
}
