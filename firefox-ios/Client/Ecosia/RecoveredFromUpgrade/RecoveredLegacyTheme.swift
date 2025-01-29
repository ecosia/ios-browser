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

protocol LegacyTheme {
    var name: String { get }
}

class LegacyNormalTheme: LegacyTheme {
    var name: String { return BuiltinThemeName.normal.rawValue }
}
