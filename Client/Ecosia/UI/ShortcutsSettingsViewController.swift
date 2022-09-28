// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

final class ShortcutsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    required init?(coder aDecoder: NSCoder) { nil }
    init() {
        super.init(style: .insetGrouped)
        self.title = .localized(.shortcuts)
    }

    override func generateSettings() -> [SettingSection] {
        var sectionItems = [SettingSection]()

        let inactiveTabsSetting = BoolSetting(with: .inactiveTabs,
                                              titleText: NSAttributedString(string: .Settings.Tabs.InactiveTabs))

        let tabGroupsSetting = BoolSetting(with: .tabTrayGroups,
                                           titleText: NSAttributedString(string: .Settings.Tabs.TabGroups))

        if featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly) {
            sectionItems.append(SettingSection(title: NSAttributedString(string: .Settings.Tabs.TabsSectionTitle),
                                               footerTitle: NSAttributedString(string: .Settings.Tabs.InactiveTabsDescription),
                                               children: [inactiveTabsSetting]))
        }

        if featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly) {
            sectionItems.append(SettingSection(children: [tabGroupsSetting]))
        }

        return sectionItems
    }
}
