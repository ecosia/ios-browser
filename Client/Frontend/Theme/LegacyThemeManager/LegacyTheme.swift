// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

protocol PrivateModeUI {
    func applyUIMode(isPrivate: Bool, theme: Theme)
}

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
    var separator: UIColor { .Light.border }
}

class BrowserColor {
    var background: UIColor { return UIColor.Photon.Grey10 } // layer1
}

class TabTrayColor {
    var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.extraLight }
    // Ecosia: Add legacy color references from 9.1.0 App Version
    var cellBackground: UIColor { return UIColor.white }
    var screenshotBackground: UIColor { return UIColor.white }
    var background: UIColor { return UIColor.Photon.Grey10 }
    var tabTitleText: UIColor { return UIColor.black }
}

protocol LegacyTheme {
    var name: String { get }
    var tableView: TableViewColor { get }
    var browser: BrowserColor { get }
    var tabTray: TabTrayColor { get }
    // Ecosia: Adapt theme
    var ecosia: EcosiaTheme { get }
}

class LegacyNormalTheme: LegacyTheme {
    var name: String { return BuiltinThemeName.normal.rawValue }
    var tableView: TableViewColor { return TableViewColor() }
    var browser: BrowserColor { return BrowserColor() }
    var tabTray: TabTrayColor { return TabTrayColor() }
    // Ecosia: Adapt theme
    var ecosia: EcosiaTheme { return EcosiaTheme() }
}
