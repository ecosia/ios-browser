// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private class DarkTableViewColor: TableViewColor {
    override var rowText: UIColor { return UIColor.Photon.Grey10 } // textPrimary
    override var disabledRowText: UIColor { return UIColor.Photon.Grey40 } // textDisabled
    // Ecosia: Re enabling legacy colo references
    override var accessoryViewTint: UIColor { return .Dark.Text.secondary }
    override var headerBackground: UIColor { .Dark.Background.primary }
    override var separator: UIColor { .Dark.Border.decorative }
    override var rowBackground: UIColor { return .Dark.Background.secondary }
}

class LegacyDarkTheme: LegacyNormalTheme {
    override var name: String { return BuiltinThemeName.dark.rawValue }
    override var tableView: TableViewColor { return DarkTableViewColor() }
}
