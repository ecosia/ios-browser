// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Core

final class ShortcutsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    required init?(coder aDecoder: NSCoder) { nil }
    init() {
        super.init(style: .insetGrouped)
        self.title = .localized(.shortcuts)
        print(Core.User.shared.topSites)
    }

    override func generateSettings() -> [SettingSection] {
        [.init(children: [
            BoolSetting(prefs: nil,
                        defaultValue: Core.User.shared.topSites,
                        attributedTitleText: .init(string: .localized(.shortcuts))) {
                            print(Core.User.shared.topSites)
                            Core.User.shared.topSites = $0
                        }
        ])]
    }
}
