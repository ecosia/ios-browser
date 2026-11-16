// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import Ecosia

final class HomePageSettingViewController: SettingsTableViewController,
                                     FeatureFlaggable,
                                     UserFeaturePreferenceProvider {
    // MARK: - Variables
    /* variables for checkmark settings */
    let prefs: Prefs
    var currentNewTabChoice: NewTabPage?
    var currentStartAtHomeSetting: StartAtHomeSetting?
    var hasHomePage = false

    var isPocketSectionEnabled: Bool {
        return MerinoProvider.isLocaleSupported(Locale.current.identifier)
    }

    // MARK: - Initializers
    init(prefs: Prefs,
         settingsDelegate: SettingsDelegate? = nil,
         tabManager: TabManager) {
        self.prefs = prefs
        super.init(style: .grouped, windowUUID: tabManager.windowUUID)
        super.settingsDelegate = settingsDelegate
        self.tabManager = tabManager

        title = .SettingsHomePageSectionName
        typealias A11yId = AccessibilityIdentifiers.Settings.Homepage
        navigationController?.navigationBar.accessibilityIdentifier = A11yId.homePageNavigationBar

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: .AppSettingsDone,
            style: .plain,
            target: self,
            action: #selector(done))
        if #available(iOS 26.0, *) {
            let theme = currentTheme()
            navigationItem.rightBarButtonItem?.tintColor = theme.isNova
                ? theme.colors.actionPrimary
                : theme.colors.textPrimary
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func done() {
        settingsDelegate?.didFinish()
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }

    // MARK: - Methods
    override func generateSettings() -> [SettingSection] {
        let customizeFirefoxHomeSection = customizeFirefoxSettingSection()
        let startAtHomeSection = setupStartAtHomeSection()

        /* Ecosia: Remove the "Current Homepage" (custom URL) section — not applicable to Ecosia
        let customizeHomePageSection = customizeHomeSettingSection()
        return [startAtHomeSection, customizeFirefoxHomeSection, customizeHomePageSection]
         */
        return [startAtHomeSection, customizeFirefoxHomeSection]
    }

    private func customizeHomeSettingSection() -> SettingSection {
        // The Home button and the New Tab page can be set independently
        self.currentNewTabChoice = NewTabAccessors.getHomePage(self.prefs)
        self.hasHomePage = HomeButtonHomePageAccessors.getHomePage(self.prefs) != nil

        let onFinished = { [weak self] in
            guard let self, let currentNewTabChoice else { return }
            prefs.setString(currentNewTabChoice.rawValue, forKey: NewTabAccessors.HomePrefKey)
            tableView.reloadData()
        }

        let showTopSites = CheckmarkSetting(
            title: NSAttributedString(string: .SettingsNewTabTopSites),
            subtitle: nil,
            accessibilityIdentifier: "HomeAsFirefoxHome",
            isChecked: { [weak self] in return self?.currentNewTabChoice == NewTabPage.topSites },
            onChecked: { [weak self] in
                self?.currentNewTabChoice = NewTabPage.topSites
                onFinished()
            })

        let showWebPage = WebPageSetting(
            prefs: prefs,
            prefKey: PrefsKeys.HomeButtonHomePageURL,
            defaultValue: nil,
            placeholder: .CustomNewPageURL,
            accessibilityIdentifier: "HomeAsCustomURL",
            isChecked: { return !showTopSites.isChecked() },
            settingDidChange: { [weak self] (string) in
                self?.currentNewTabChoice = NewTabPage.homePage
                onFinished()
            })

        showWebPage.alignTextFieldToNatural()

        return SettingSection(
            title: NSAttributedString(string: .SettingsHomePageURLSectionTitle),
            footerTitle: NSAttributedString(string: .Settings.Homepage.Current.Description),
            children: [showTopSites, showWebPage]
        )
    }

    private func customizeFirefoxSettingSection() -> SettingSection {
        // Setup
        var sectionItems = [Setting]()

        // Section ordering
        sectionItems.append(TopSitesSettings(settings: self))

        // Ecosia: Climate Impact toggle to show/hide impact rows on the NTP
        sectionItems.append(ClimateImpactSettings(settings: self))

        /* Ecosia: Ecosia's NTP never shows the Jump Back In, Tracker Blocker or Bookmarks sections,
           so their settings toggles must never appear. Upstream dropped its own `shouldHideSections`
           feature-flag guard in 155.1 and now shows these unconditionally (the Tracker Blocker toggle
           behind `.homepageTrackerBlockerModule`, which is enabled on the developer channel), so the
           whole block stays removed here.
        if let profile {
            if featureFlagsProvider.isEnabled(.homepageTrackerBlockerModule) {
                let trackerBlockerModuleSetting = BoolSetting(
                    prefs: profile.prefs,
                    theme: currentTheme(),
                    prefKey: PrefsKeys.HomepageSettings.TrackerBlockerSection,
                    defaultValue: userPreferences.getPreferenceFor(.homepageTrackerBlockerModule),
                    titleText: .Settings.Homepage.CustomizeFirefoxHome.PrivacyReport
                ) { [windowUUID] value in
                    store.dispatch(
                        TrackerBlockerModuleAction(
                            isEnabled: value,
                            windowUUID: windowUUID,
                            actionType: TrackerBlockerModuleActionType.toggleShowSectionSetting
                        )
                    )
                }
                sectionItems.append(trackerBlockerModuleSetting)
            }

            let jumpBackInSetting = BoolSetting(
                prefs: profile.prefs,
                theme: currentTheme(),
                prefKey: PrefsKeys.HomepageSettings.JumpBackInSection,
                defaultValue: userPreferences.getPreferenceFor(.homepageJumpBackinSectionDefault),
                titleText: .Settings.Homepage.CustomizeFirefoxHome.JumpBackIn
            ) { [windowUUID] value in
                store.dispatch(
                    JumpBackInAction(
                        isEnabled: value,
                        windowUUID: windowUUID,
                        actionType: JumpBackInActionType.toggleShowSectionSetting
                    )
                )
            }
            sectionItems.append(jumpBackInSetting)

            let bookmarksSetting = BoolSetting(
                prefs: profile.prefs,
                theme: currentTheme(),
                prefKey: PrefsKeys.HomepageSettings.BookmarksSection,
                defaultValue: userPreferences.getPreferenceFor(.homepageBookmarksSectionDefault),
                titleText: .Settings.Homepage.CustomizeFirefoxHome.Bookmarks
            ) { [windowUUID] value in
                store.dispatch(
                    BookmarksAction(
                        isEnabled: value,
                        windowUUID: windowUUID,
                        actionType: BookmarksActionType.toggleShowSectionSetting
                    )
                )
            }
            sectionItems.append(bookmarksSetting)
        }
        */

        // TODO: FXIOS-12980: Replace "Stories" title with "Top Stories" string once it is translated in v143
        if isPocketSectionEnabled, let profile {
            let pocketSetting = BoolSetting(
                prefs: profile.prefs,
                theme: currentTheme(),
                prefKey: PrefsKeys.UserFeatureFlagPrefs.ASPocketStories,
                defaultValue: true,
                titleText: .Settings.Homepage.CustomizeFirefoxHome.Stories
            ) { [windowUUID] value in
                store.dispatch(
                    MerinoAction(
                        isEnabled: value,
                        windowUUID: windowUUID,
                        actionType: MerinoActionType.toggleShowSectionSetting
                    )
                )
            }
            sectionItems.append(pocketSetting)
        }

        return SettingSection(
            title: NSAttributedString(
                string: .Settings.Homepage.CustomizeFirefoxHome.Title
            ),
            footerTitle: NSAttributedString(string: .Settings.Homepage.CustomizeFirefoxHome.Description),
            children: sectionItems
        )
    }

    private func setupStartAtHomeSection() -> SettingSection {
        let pref = userPreferences.startAtHomeSetting
        currentStartAtHomeSetting = StartAtHomeSetting(rawValue: pref.rawValue) ?? .disabled

        typealias a11y = AccessibilityIdentifiers.Settings.Homepage.StartAtHome

        let onOptionSelected: (
            Bool,
            StartAtHomeSetting,
            StartAtHomeSetting?
        ) -> Void = { [weak self] state, newOption, previousOption in
            self?.prefs.setString(newOption.rawValue, forKey: PrefsKeys.FeatureFlags.StartAtHome)
            self?.tableView.reloadData()

            SettingsTelemetry().changedSetting(
                PrefsKeys.FeatureFlags.StartAtHome,
                to: newOption.rawValue,
                from: previousOption?.rawValue ?? SettingsTelemetry.Placeholders.missingValue
            )
        }

        let afterFourHoursOption = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Homepage.StartAtHome.AfterFourHours),
            subtitle: nil,
            accessibilityIdentifier: a11y.afterFourHours,
            isChecked: { [weak self] in return self?.currentStartAtHomeSetting == .afterFourHours },
            onChecked: { [weak self] in
                let previousOption = self?.currentStartAtHomeSetting
                self?.currentStartAtHomeSetting = .afterFourHours
                onOptionSelected(true, .afterFourHours, previousOption)
            })

        let alwaysOption = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Homepage.StartAtHome.Always),
            subtitle: nil,
            accessibilityIdentifier: a11y.always,
            isChecked: { [weak self] in return self?.currentStartAtHomeSetting == .always },
            onChecked: { [weak self] in
                let previousOption = self?.currentStartAtHomeSetting
                self?.currentStartAtHomeSetting = .always
                onOptionSelected(true, .always, previousOption)
            })

        let neverOption = CheckmarkSetting(
            title: NSAttributedString(string: .Settings.Homepage.StartAtHome.Never),
            subtitle: nil,
            accessibilityIdentifier: a11y.disabled,
            isChecked: { [weak self] in return self?.currentStartAtHomeSetting == .disabled },
            onChecked: { [weak self] in
                let previousOption = self?.currentStartAtHomeSetting
                self?.currentStartAtHomeSetting = .disabled
                onOptionSelected(false, .disabled, previousOption)
            })

        let section = SettingSection(
            title: NSAttributedString(string: .Settings.Homepage.StartAtHome.SectionTitle),
            footerTitle: NSAttributedString(
                string: .Settings.Homepage.StartAtHome.SectionDescription
            ),
            children: [alwaysOption, neverOption, afterFourHoursOption]
        )

        return section
    }
}

// MARK: - TopSitesSettings
extension HomePageSettingViewController {
    final class TopSitesSettings: Setting {
        var profile: Profile?
        let windowUUID: WindowUUID

        override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }
        override var accessibilityIdentifier: String? {
            return AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage
        }
        override var style: UITableViewCell.CellStyle { return .value1 }

        override var status: NSAttributedString? {
            guard let profile else { return nil }
            let areShortcutsOn = profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.TopSiteSection) ?? true
            typealias Shortcuts = String.Settings.Homepage.Shortcuts
            let status: String = areShortcutsOn ? Shortcuts.ToggleOn : Shortcuts.ToggleOff
            return NSAttributedString(string: String(format: status))
        }

        init(settings: SettingsTableViewController) {
            self.profile = settings.profile
            self.windowUUID = settings.windowUUID
            super.init(title: NSAttributedString(string: .Settings.Homepage.Shortcuts.ShortcutsPageTitle))
        }

        override func onClick(_ navigationController: UINavigationController?) {
            let topSitesVC = TopSitesSettingsViewController(windowUUID: windowUUID)
            topSitesVC.profile = profile
            navigationController?.pushViewController(topSitesVC, animated: true)
        }
    }
}

// MARK: - Ecosia: ClimateImpactSettings
extension HomePageSettingViewController {
    class ClimateImpactSettings: BoolSetting {
        private static let prefKey = "ecosia.showClimateImpact"

        init(settings: SettingsTableViewController) {
            let prefs = settings.profile?.prefs
            super.init(
                prefs: prefs,
                prefKey: ClimateImpactSettings.prefKey,
                defaultValue: User.shared.showClimateImpact,
                attributedTitleText: NSAttributedString(string: .localized(.climateImpact))
            )
            // Sync User's persisted value into prefs so the base class's
            // displayBool reads the correct state on every launch.
            prefs?.setBool(User.shared.showClimateImpact, forKey: ClimateImpactSettings.prefKey)
        }

        override func writeBool(_ control: UISwitch) {
            User.shared.showClimateImpact = control.isOn
            // Keep prefs in sync so displayBool (base class) shows the right state.
            prefs?.setBool(control.isOn, forKey: ClimateImpactSettings.prefKey)
            Analytics.shared.ntpCustomisation(
                control.isOn ? .enable : .disable,
                label: .impact
            )
        }
    }
}
