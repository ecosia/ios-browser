/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Core

enum AppSettingsDeeplinkOption {
    case contentBlocker
    case customizeHomepage
}

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController, FeatureFlagsProtocol {
    var deeplinkTo: AppSettingsDeeplinkOption?

    // Ecosia make inset grouped
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let variables = Experiments.shared.getVariables(featureId: .nimbusValidation)
        let title = variables.getText("settings-title") ?? .AppSettingsTitle
        let suffix = variables.getString("settings-title-punctuation") ?? ""

        navigationItem.title = "\(title)\(suffix)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: .AppSettingsDone,
            style: .done,
            target: navigationController, action: #selector((navigationController as! ThemedNavigationController).done))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "AppSettingsTableViewController.navigationItem.leftBarButtonItem"

        tableView.accessibilityIdentifier = "AppSettingsTableViewController.tableView"

        // Refresh the user's FxA profile upon viewing settings. This will update their avatar,
        // display name, etc.
        ////profile.rustAccount.refreshProfile()

        checkForDeeplinkSetting()
    }

    private func checkForDeeplinkSetting() {
        guard let deeplink = deeplinkTo else { return }
        var viewController: SettingsTableViewController

        switch deeplink {
        case .contentBlocker:
            viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
            viewController.tabManager = tabManager

        case .customizeHomepage:
            viewController = HomePageSettingViewController(prefs: profile.prefs)
        }

        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: false)
        // Add a done button from this view
        viewController.navigationItem.rightBarButtonItem = navigationItem.rightBarButtonItem
    }

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let prefs = profile.prefs
        var generalSettings: [Setting] = [
            OpenWithSetting(settings: self),
            ThemeSetting(settings: self),
            SiriPageSetting(settings: self),
            BoolSetting(prefs: prefs, prefKey: PrefsKeys.KeyBlockPopups, defaultValue: true,
                        titleText: .AppSettingsBlockPopups),
            BoolSetting(prefs: prefs, prefKey: "", defaultValue: Core.User.shared.topSites ?? true, titleText: .localized(.showTopSites)) {
                Core.User.shared.topSites = $0
            }
           ]

        /* Ecosia: deactivate china settings
        let accountChinaSyncSetting: [Setting]
        if !AppInfo.isChinaEdition {
            accountChinaSyncSetting = []
        } else {
            accountChinaSyncSetting = [
                // Show China sync service setting:
                ChinaSyncServiceSetting(settings: self)
            ]
        }
        */
        // There is nothing to show in the Customize section if we don't include the compact tab layout
        // setting on iPad. When more options are added that work on both device types, this logic can
        // be changed.
        
        generalSettings += [
            BoolSetting(prefs: prefs, prefKey: "showClipboardBar", defaultValue: false,
                        titleText: Strings.SettingsOfferClipboardBarTitle,
                        statusText: Strings.SettingsOfferClipboardBarStatus),
            BoolSetting(prefs: prefs, prefKey: PrefsKeys.ContextMenuShowLinkPreviews, defaultValue: true,
                        titleText: Strings.SettingsShowLinkPreviewsTitle,
                        statusText: Strings.SettingsShowLinkPreviewsStatus)
        ]


        if #available(iOS 14.0, *) {
            settings += [
                SettingSection(footerTitle: .init(string: .localized(.linksFromWebsites)), children: [DefaultBrowserSetting()])
            ]
        }
        /* Ecosia: Deactivate account settings
        let accountSectionTitle = NSAttributedString(string: Strings.FxAFirefoxAccount)

        let footerText = !profile.hasAccount() ? NSAttributedString(string: Strings.FxASyncUsageDetails) : nil
        settings += [
            SettingSection(title: accountSectionTitle, footerTitle: footerText, children: [
                // Without a Firefox Account:
                ConnectSetting(settings: self),
                AdvancedAccountSetting(settings: self),
                // With a Firefox Account:
                AccountStatusSetting(settings: self),
                SyncNowSetting(settings: self)
            ] + accountChinaSyncSetting )]
         */

        let searchSettings: [Setting] = [
            SearchAreaSetting(settings: self),
            SafeSearchSettings(settings: self),
            AutoCompleteSettings(prefs: prefs),
            PersonalSearchSettings(prefs: prefs)
        ]
        
        settings += [ SettingSection(title: NSAttributedString(string: .localized(.search)), footerTitle: nil, children: searchSettings)]

        settings += [ SettingSection(title: NSAttributedString(string: Strings.SettingsGeneralSectionTitle), children: generalSettings)]

        var privacySettings = [Setting]()
        privacySettings.append(LoginsSetting(settings: self, delegate: settingsDelegate))
        privacySettings.append(TouchIDPasscodeSetting(settings: self))

        privacySettings.append(ClearPrivateDataSetting(settings: self))

        privacySettings += [
            BoolSetting(prefs: prefs,
                prefKey: "settings.closePrivateTabs",
                defaultValue: false,
                titleText: .AppSettingsClosePrivateTabsTitle,
                statusText: .AppSettingsClosePrivateTabsDescription)
        ]

        privacySettings.append(ContentBlockerSetting(settings: self))

        privacySettings += [
            EcosiaPrivacyPolicySetting(),
            EcosiaTermsSetting()
        ]

        settings += [
            SettingSection(title: NSAttributedString(string: .AppSettingsPrivacyTitle), children: privacySettings),
            SettingSection(title: NSAttributedString(string: .AppSettingsSupport), children: [
                // Ecosia: ShowIntroductionSetting(settings: self),
                EcosiaSendFeedbackSetting(),
                // Ecosia: SendAnonymousUsageDataSetting(prefs: prefs, delegate: settingsDelegate)
                // Ecosia: StudiesToggleSetting(prefs: prefs, delegate: settingsDelegate),
                // Ecosia: OpenSupportPageSetting(delegate: settingsDelegate),
            ]),
            SettingSection(title: NSAttributedString(string: .AppSettingsAbout), children: [
                VersionSetting(settings: self),
                LicenseAndAcknowledgementsSetting(),
                /* Ecosia: deactivate MOZ debug settings
				YourRightsSetting(),
                ExportBrowserDataSetting(settings: self),
                ExportLogDataSetting(settings: self),
                DeleteExportedDataSetting(settings: self),
                ForceCrashSetting(settings: self),
                SlowTheDatabase(settings: self),
                ForgetSyncAuthStateDebugSetting(settings: self),
                SentryIDSetting(settings: self),
                ChangeToChinaSetting(settings: self),
                ShowEtpCoverSheet(settings: self),
                ToggleChronTabs(settings: self),
                TogglePullToRefresh(settings: self),
                ToggleInactiveTabs(settings: self),
                ResetJumpBackInContextualHint(settings: self),
                ExperimentsSettings(settings: self)
 */
                PushBackInstallation(settings: self),
                ToggleBrandRefreshIntro(settings: self),
                ToggleCounterIntro(settings: self),
                ShowTour(settings: self),
                ToggleReferrals(settings: self),
                CreateReferralCode(settings: self),
                AddReferral(settings: self),
                AddClaim(settings: self),
                CreateMigrationData(settings: self),
                AutofocusSearchbar(prefs: prefs)
            ])]

        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(tableView, viewForHeaderInSection: section) as! ThemedTableSectionHeaderFooterView
        return headerView
    }
}
