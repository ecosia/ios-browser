/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import Shared
import Common

var ecosiaDisclosureIndicator: UIImageView {
    let config = UIImage.SymbolConfiguration(pointSize: 16)
    let disclosureIndicator = UIImageView(image: .init(systemName: "chevron.right", withConfiguration: config))
    disclosureIndicator.contentMode = .center
    disclosureIndicator.tintColor = UIColor.legacyTheme.tableView.accessoryViewTint
    disclosureIndicator.sizeToFit()
    return disclosureIndicator
}

final class SearchAreaSetting: Setting {
    override var accessoryView: UIImageView? { return ecosiaDisclosureIndicator }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: Markets.current ?? "") }

    override var accessibilityIdentifier: String? { return .localized(.searchRegion) }

    init(settings: SettingsTableViewController) {
        super.init(title: NSAttributedString(string: .localized(.searchRegion), attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(MarketsController(style: .insetGrouped), animated: true)
    }
    
    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.minimumScaleFactor = 0.8
        cell.detailTextLabel?.allowsDefaultTighteningForTruncation = true
        cell.textLabel?.numberOfLines = 2
    }
}

final class SafeSearchSettings: Setting {
    override var accessoryView: UIImageView? { return ecosiaDisclosureIndicator }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: FilterController.current ?? "") }

    override var accessibilityIdentifier: String? { return .localized(.searchRegion) }

    init(settings: SettingsTableViewController) {
        super.init(title: NSAttributedString(string: .localized(.safeSearch), attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(FilterController(), animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.detailTextLabel?.numberOfLines = 2
        cell.textLabel?.numberOfLines = 2
    }
}

final class AutoCompleteSettings: BoolSetting {
    convenience init(prefs: Prefs, theme: Theme) {
        self.init(prefs: prefs, theme: theme, prefKey: "", defaultValue: true,
                titleText: .localized(.autocomplete),
                statusText: .localized(.shownUnderSearchField), settingDidChange: { value in

                    User.shared.autoComplete = value

                })
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = User.shared.autoComplete
    }

    override func writeBool(_ control: UISwitch) {
        User.shared.autoComplete = control.isOn
    }
}

final class PersonalSearchSettings: BoolSetting {
    convenience init(prefs: Prefs, theme: Theme) {
        self.init(prefs: prefs, theme: theme, prefKey: "", defaultValue: false,
                titleText: .localized(.personalizedResults),
                statusText: .localized(.relevantResults), settingDidChange: { value in
                    User.shared.personalized = value
                })
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = User.shared.personalized
    }

    override func writeBool(_ control: UISwitch) {
        User.shared.personalized = control.isOn
    }
}

final class EcosiaPrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .localized(.privacy), attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var url: URL? {
        return Environment.current.urlProvider.privacy
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
        Analytics.shared.navigation(.open, label: .privacy)
    }
}

final class EcosiaSendFeedbackSetting: Setting {
    private var device: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private var mailURL: String {
        """
        mailto:iosapp@ecosia.org?subject=\
        iOS%20App%20Feedback%20-\
        %20Version_\(Bundle.version)\
        %20iOS_\(UIDevice.current.systemVersion)\
        %20\(device)
        """
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .localized(.sendFeedback), attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        _ = URL(string: mailURL).map {
            UIApplication.shared.open($0, options: [:], completionHandler: nil)
        }
        Analytics.shared.navigation(.open, label: .sendFeedback)
    }
}

final class EcosiaTermsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .localized(.terms), attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var url: URL? {
        return Environment.current.urlProvider.terms
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
        Analytics.shared.navigation(.open, label: .terms)
    }
}

final class EcosiaSendAnonymousUsageDataSetting: BoolSetting {
    convenience init(prefs: Prefs, theme: Theme) {
        self.init(prefs: prefs, theme: theme,
                  prefKey: "",
                  defaultValue: true,
                  titleText: .localized(.sendUsageDataSettingsTitle),
                  statusText: .localized(.sendUsageDataSettingsDescription),
                  settingDidChange: { value in
            User.shared.sendAnonymousUsageData = value
            Analytics.shared.sendAnonymousUsageDataSetting(enabled: value)
        })
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = User.shared.sendAnonymousUsageData
    }

    override func writeBool(_ control: UISwitch) {
        User.shared.sendAnonymousUsageData = control.isOn
    }
}

final class HomepageSettings: Setting {
    private var profile: Profile

    override var accessoryView: UIImageView? { ecosiaDisclosureIndicator }

    init(settings: SettingsTableViewController, settingsDelegate: SettingsDelegate?) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .localized(.homepage)))
        self.delegate = settingsDelegate
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let customizationViewController = NTPCustomizationSettingsViewController()
        customizationViewController.profile = profile
        customizationViewController.settingsDelegate = delegate
        navigationController?.pushViewController(customizationViewController, animated: true)
    }
}

// Ecosia: Quick Search Shortcuts Experiment
// Opens the quick search settings panel
final class QuickSearchSearchSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return ecosiaDisclosureIndicator }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var accessibilityIdentifier: String? { return .localized(.quickSearch) }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .localized(.quickSearch), attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Analytics.shared.accessQuickSearchSettingsScreen()
        let viewController = SearchSettingsTableViewController(profile: profile)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

final class CompanySetting: Setting {
    let settings: SettingsTableViewController
    
    init(settings: SettingsTableViewController) {
        self.settings = settings
        let companyName = User.shared.company?.name ?? ""
        super.init(title: NSAttributedString(string: "Connected to \(companyName)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText]))
    }
    
    override var status: NSAttributedString? {
        return NSAttributedString(string: "Click to disconnect", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(title: "Disconnect from company", message: "Do you want to disconnect this iPhone from your company?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "No", style: .cancel)
        let ok = UIAlertAction(title: "Yes", style: .destructive) { _ in
            User.shared.company = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                // this will trigger a settings reload
                self.settings.applyTheme()
                NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
            }
            // this will trigger the NTP to reload
        }
        alert.addAction(cancel)
        alert.addAction(ok)
        settings.present(alert, animated: true)
    }
    
}

final class AboutEcosiaForCompaniesSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "About Ecosia for Companies", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var url: URL? {
        return URL(string: "https://companies.ecosia.org")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

extension Setting {
    // Helper method to set up and push a SettingsContentViewController
    func setUpAndPushSettingsContentViewController(_ navigationController: UINavigationController?, _ url: URL? = nil) {
        if let url = self.url {
            let viewController = SettingsContentViewController()
            viewController.settingsTitle = self.title
            viewController.url = url
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
