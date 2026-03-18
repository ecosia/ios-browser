// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Glean
import Ecosia // Ecosia

import struct MozillaAppServices.VisitObservation

// MARK: - Settings Flow Delegate Protocol

/// Supports decision making from VC to parent coordinator
protocol SettingsFlowDelegate: AnyObject,
                               GeneralSettingsDelegate,
                               PrivacySettingsDelegate,
                               AccountSettingsDelegate,
                               AboutSettingsDelegate,
                               SupportSettingsDelegate {
    @MainActor
    func showDevicePassCode()

    @MainActor
    func showCreditCardSettings()

    @MainActor
    func showExperiments()

    @MainActor
    func showFirefoxSuggest()

    @MainActor
    func openDebugTestTabs(count: Int)

    @MainActor
    func showDebugFeatureFlags()

    @MainActor
    func showPasswordManager(shouldShowOnboarding: Bool)

    @MainActor
    func didFinishShowingSettings()
}

// MARK: - App Settings Screen Protocol

protocol AppSettingsScreen: UIViewController {
    @MainActor
    var settingsDelegate: SettingsDelegate? { get set }
    @MainActor
    var parentCoordinator: SettingsFlowDelegate? { get set }
    @MainActor
    func handle(route: Route.SettingsSection)
}

// MARK: - App Settings Table View Controller

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController,
                                      AppSettingsScreen,
                                      FeatureFlaggable,
                                      DebugSettingsDelegate,
                                      SearchBarLocationProvider,
                                      SharedSettingsDelegate {
    // MARK: - Properties
    private var showDebugSettings = false
    private var debugSettingsClickCount = 0
    private var appAuthenticator: AppAuthenticationProtocol
    private var applicationHelper: ApplicationHelper
    private let logger: Logger
    private let gleanUsageReportingMetricsService: GleanUsageReportingMetricsService
    private var hasAppearedBefore = false
    private let searchEnginesManager: SearchEnginesManagerProvider
    private let summarizerNimbusUtils: SummarizerNimbusUtils

    weak var parentCoordinator: SettingsFlowDelegate?

    // MARK: - Data Settings
    private var sendTechnicalDataSetting: SendDataSetting?
    private var sendCrashReportsSetting: SendDataSetting?
    private var sendDailyUsagePingSetting: SendDataSetting?
    private var studiesToggleSetting: SendDataSetting?
    private var rolloutsToggleSetting: SendDataSetting?

    // MARK: - Initializers
    init(
        with profile: Profile,
        and tabManager: TabManager,
        settingsDelegate: SettingsDelegate,
        parentCoordinator: SettingsFlowDelegate,
        gleanUsageReportingMetricsService: GleanUsageReportingMetricsService,
        appAuthenticator: AppAuthenticationProtocol = AppAuthenticator(),
        applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
        summarizerNimbusUtils: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        logger: Logger = DefaultLogger.shared,
        searchEnginesManager: SearchEnginesManager = AppContainer.shared.resolve()
    ) {
        self.summarizerNimbusUtils = summarizerNimbusUtils
        self.appAuthenticator = appAuthenticator
        self.applicationHelper = applicationHelper
        self.logger = logger
        self.gleanUsageReportingMetricsService = gleanUsageReportingMetricsService
        self.searchEnginesManager = searchEnginesManager

        super.init(windowUUID: tabManager.windowUUID)
        self.profile = profile
        self.tabManager = tabManager
        self.settingsDelegate = settingsDelegate
        self.parentCoordinator = parentCoordinator
        setupNavigationBar()
        setupDataSettings()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(cellType: ThemedLearnMoreTableViewCell.self)
        setupNavigationBar()
        configureAccessibilityIdentifiers()

        // Ecosia: Register Nudge Card if needed
        if User.shared.shouldShowDefaultBrowserSettingNudgeCard {
            tableView.register(DefaultBrowserSettingsNudgeCardHeaderView.self,
                               forHeaderFooterViewReuseIdentifier: DefaultBrowserSettingsNudgeCardHeaderView.cellIdentifier)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if hasAppearedBefore {
            // Only reload if we're returning from a child view
            askedToReload()
        }

        hasAppearedBefore = true
    }

    // MARK: - Actions

    @objc
    private func done() {
        settingsDelegate?.didFinish()
    }

    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        navigationItem.title = String.AppSettingsTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: .AppSettingsDone,
            style: .plain,
            target: self,
            action: #selector(done))
    }

    // MARK: - Accessibility Identifiers
    func configureAccessibilityIdentifiers() {
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Settings.navigationBarItem
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings.tableViewController
    }

    // MARK: - Route Handling

    func handle(route: Route.SettingsSection) {
        switch route {
        case .password:
            handlePasswordFlow(route: route)
        case .creditCard:
            authenticateUserFor(route: route)
        case .rateApp:
            RatingPromptManager.goToAppStoreReview()
        default:
            break
        }
    }

    private func handlePasswordFlow(route: Route.SettingsSection) {
        // Show password onboarding before we authenticate
        if LoginOnboarding.shouldShow() {
            parentCoordinator?.showPasswordManager(shouldShowOnboarding: true)
            LoginOnboarding.setShown()
        } else {
            authenticateUserFor(route: route)
        }
    }

    // MARK: - User Authentication

    // Authenticates the user prior to allowing access to sensitive sections
    private func authenticateUserFor(route: Route.SettingsSection) {
        appAuthenticator.getAuthenticationState { state in
            switch state {
            case .deviceOwnerAuthenticated:
                self.openDeferredRouteAfterAuthentication(route: route)
            case .deviceOwnerFailed:
                break // Keep showing the main settings page
            case .passCodeRequired:
                self.parentCoordinator?.showDevicePassCode()
            }
        }
    }

    // Called after the user has been prompted to authenticate to access a sensitive section
    private func openDeferredRouteAfterAuthentication(route: Route.SettingsSection) {
        switch route {
        case .creditCard:
            self.parentCoordinator?.showCreditCardSettings()
        case .password:
            self.parentCoordinator?.showPasswordManager(shouldShowOnboarding: false)
        default:
            break
        }
    }

    // MARK: Data settings setup

    private func setupDataSettings() {
        guard let profile else { return }

        let studiesSetting = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefStudiesToggle,
            defaultValue: true,
            titleText: .StudiesSettingTitleV3,
            subtitleText: String(format: .StudiesSettingMessageV3, AppName.shortName.rawValue),
            learnMoreText: .StudiesSettingLinkV3,
            learnMoreURL: SupportUtils.URLForTopic("ios-studies"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.studiesTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.studiesLearnMoreButton,
            settingsDelegate: parentCoordinator,
            isStudiesCase: true
        )
        studiesSetting.settingDidChange = {
            Experiments.setStudiesSetting($0)
        }

        // Initialize rollouts participation on startup (rollouts are independent of telemetry)
        // Get the value from Nimbus SDK to respect any DB migration that may have occurred
        let rolloutsEnabled = Experiments.shared.rolloutParticipation
        // Sync prefs with SDK value so UI toggle shows correct state after DB migration
        if profile.prefs.boolForKey(AppConstants.prefRolloutsToggle) == nil {
            profile.prefs.setBool(rolloutsEnabled, forKey: AppConstants.prefRolloutsToggle)
        }
        Experiments.setRolloutsSetting(rolloutsEnabled)

        let rolloutsSetting = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefRolloutsToggle,
            defaultValue: true,
            titleText: .RolloutsSettingTitle,
            subtitleText: String(format: .RolloutsSettingMessage, AppName.shortName.rawValue),
            learnMoreText: .RolloutsSettingLink,
            learnMoreURL: SupportUtils.URLForTopic("remote-improvements"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.rolloutsTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.rolloutsLearnMoreButton,
            settingsDelegate: parentCoordinator
        )
        rolloutsSetting.settingDidChange = {
            Experiments.setRolloutsSetting($0)
        }

        let sendTechnicalDataSettings = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefSendUsageData,
            defaultValue: true,
            titleText: .SendTechnicalDataSettingTitleV2,
            subtitleText: String(format: .SendTechnicalDataSettingMessageV2, AppName.shortName.rawValue),
            learnMoreText: .SendTechnicalDataSettingLinkV2,
            learnMoreURL: SupportUtils.URLForTopic("mobile-technical-and-interaction-data"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.sendTechnicalDataTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.sendTechnicalDataLearnMoreButton,
            settingsDelegate: parentCoordinator
        )

        sendTechnicalDataSettings.settingDidChange = { [weak self] value in
            guard let self else { return }
            DefaultGleanWrapper().setUpload(isEnabled: value)
            Experiments.setTelemetrySetting(value)
            studiesSetting.updateSetting(for: value)
            self.tableView.reloadData()
        }
        sendTechnicalDataSetting = sendTechnicalDataSettings

        let sendDailyUsagePingSettings = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefSendDailyUsagePing,
            defaultValue: true,
            titleText: .SendDailyUsagePingSettingTitle,
            subtitleText: String(format: .SendDailyUsagePingSettingMessage, MozillaName.shortName.rawValue),
            learnMoreText: .SendDailyUsagePingSettingLinkV2,
            learnMoreURL: SupportUtils.URLForTopic("usage-ping-settings-mobile"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.sendDailyUsagePingTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.sendDailyUsagePingLearnMoreButton,
            settingsDelegate: parentCoordinator
        )
        sendDailyUsagePingSettings.settingDidChange = { [weak self] value in
            if value {
                self?.gleanUsageReportingMetricsService.start()
            } else {
                self?.gleanUsageReportingMetricsService.stop()
            }
        }
        sendDailyUsagePingSetting = sendDailyUsagePingSettings

        let sendCrashReportsSettings = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefSendCrashReports,
            defaultValue: true,
            titleText: .SendCrashReportsSettingTitle,
            subtitleText: String(format: .SendCrashReportsSettingMessageV2, MozillaName.shortName.rawValue),
            learnMoreText: .SendCrashReportsSettingLinkV2,
            learnMoreURL: SupportUtils.URLForTopic("ios-crash-reports"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.sendCrashReportsTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.sendCrashReportsLearnMoreButton,
            settingsDelegate: parentCoordinator
        )
        self.sendCrashReportsSetting = sendCrashReportsSettings

        studiesToggleSetting = studiesSetting
        rolloutsToggleSetting = rolloutsSetting
    }

    // MARK: - Generate Settings

    override func generateSettings() -> [SettingSection] {
        // Ecosia: removed setupDataSettings() — Ecosia does not use Firefox data-collection settings
        var settings = [SettingSection]()

        // Ecosia: conditionally show default browser nudge card
        if User.shared.shouldShowDefaultBrowserSettingNudgeCard {
            settings += getDefaultBrowserSetting()
        }

        // Ecosia: removed getAccountSetting() — no sign-in / accounts feature
        settings += getSearchSection()          // Ecosia: search settings section
        settings += getCustomizationSection()   // Ecosia: customization section
        settings += getGeneralSettings()
        settings += getPrivacySettings()
        settings += getSupportSettings()
        settings += getAboutSettings()

        if showDebugSettings {
            // Ecosia: use Ecosia-specific debug sections
            settings.append(getEcosiaDebugSupportSection())
            settings.append(getEcosiaDebugUnleashSection())
            settings.append(getEcosiaDebugAccountsSection())
        }

        return settings
    }

    private func getDefaultBrowserSetting() -> [SettingSection] {
        // Ecosia: hidden placeholder section for the nudge card header.
        // The nudge card header view is displayed via viewForHeaderInSection.
        // The placeholder Setting carries the accessibility identifier used by isDefaultBrowserCell()
        // but is hidden so no row is rendered — only the nudge card header is visible.
        let placeholder = EcosiaDefaultBrowserNudgeCardPlaceholder()
        return [SettingSection(children: [placeholder])]
    }

    private func getAccountSetting() -> [SettingSection] {
        let accountSectionTitle = NSAttributedString(string: .FxAFirefoxAccount)

        let attributedString = NSAttributedString(string: .Settings.Sync.ButtonDescription)
        let accountFooterText = !(profile?.hasAccount() ?? false) ? attributedString : nil

        var settings = [
            // Without a Firefox Account:
            ConnectSetting(settings: self, settingsDelegate: parentCoordinator),
            AdvancedAccountSetting(settings: self, isHidden: showDebugSettings, settingsDelegate: parentCoordinator),
            // With a Firefox Account:
            AccountStatusSetting(settings: self, settingsDelegate: parentCoordinator),
            SyncNowSetting(settings: self, settingsDelegate: parentCoordinator)
        ]
        if AppInfo.isChinaEdition, let profile {
            settings.append(ChinaSyncServiceSetting(profile: profile, settingsDelegate: self))
        }
        return [
            SettingSection(title: accountSectionTitle, footerTitle: accountFooterText, children: settings)
        ]
    }

    private func getGeneralSettings() -> [SettingSection] {
        // Ecosia: replaced Firefox general items (Browsing, Search, NewTab, Home, AppIcon,
        // Summarize, Translation, SearchBar) with Ecosia-specific general settings.
        // Items moved to Search section or Customization section are handled there.
        guard let profile else {
            return [SettingSection(title: NSAttributedString(string: .SettingsGeneralSectionTitle),
                                   children: [
                                    ThemeSetting(settings: self, settingsDelegate: parentCoordinator),
                                    SiriPageSetting(settings: self, settingsDelegate: parentCoordinator)
                                   ])]
        }
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let generalSettings: [Setting] = [
            OpenWithSetting(settings: self, settingsDelegate: nil), // Ecosia: BrowsingSettingsDelegate not available here
            ThemeSetting(settings: self, settingsDelegate: parentCoordinator),
            SiriPageSetting(settings: self, settingsDelegate: parentCoordinator),
            BlockPopupSetting(prefs: profile.prefs),
            NoImageModeSetting(profile: profile),
            BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: "showClipboardBar",
                defaultValue: false,
                titleText: .SettingsOfferClipboardBarTitle,
                statusText: String(format: .SettingsOfferClipboardBarStatus, AppName.shortName.rawValue)
            ),
            BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: PrefsKeys.ContextMenuShowLinkPreviews,
                defaultValue: true,
                titleText: .SettingsShowLinkPreviewsTitle,
                statusText: .SettingsShowLinkPreviewsStatus
            )
        ]

        return [SettingSection(title: NSAttributedString(string: .SettingsGeneralSectionTitle),
                               children: generalSettings)]
    }

    private func getPrivacySettings() -> [SettingSection] {
        // Ecosia: replaced AutofillPasswordSetting with PasswordManagerSetting,
        // added EcosiaSendAnonymousUsageDataSetting, removed NotificationsSetting,
        // replaced PrivacyPolicySetting with Ecosia equivalents, added EcosiaTermsSetting
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        var privacySettings: [Setting] = [
            PasswordManagerSetting(settings: self, settingsDelegate: parentCoordinator),
            ClearPrivateDataSetting(settings: self, settingsDelegate: parentCoordinator),
        ]

        if let profile {
            privacySettings.append(EcosiaSendAnonymousUsageDataSetting(prefs: profile.prefs, theme: theme))
            privacySettings.append(BoolSetting(
                prefs: profile.prefs,
                theme: theme,
                prefKey: PrefsKeys.Settings.closePrivateTabs,
                // Ecosia: default value is different from Firefox
                defaultValue: PrefsKeysDefaultValues.Settings.closePrivateTabs,
                titleText: .AppSettingsClosePrivateTabsTitle,
                statusText: .AppSettingsClosePrivateTabsDescription
            ))
        }

        privacySettings.append(ContentBlockerSetting(settings: self, settingsDelegate: parentCoordinator))
        privacySettings.append(EcosiaPrivacyPolicySetting(settings: self))
        privacySettings.append(EcosiaTermsSetting(settings: self))

        return [SettingSection(title: NSAttributedString(string: .AppSettingsPrivacyTitle),
                               children: privacySettings)]
    }

    private func getSupportSettings() -> [SettingSection] {
        // Ecosia: replaced Firefox support items with Ecosia Help Center and Send Feedback
        let supportSettings: [Setting] = [
            HelpCenterSetting(),
            EcosiaSendFeedbackSetting(settings: self)
        ]

        return [SettingSection(title: NSAttributedString(string: .AppSettingsSupport),
                               children: supportSettings)]
    }

    private func getAboutSettings() -> [SettingSection] {
        // Ecosia: removed YourRightsSetting
        let aboutSettings = [
            AppStoreReviewSetting(settingsDelegate: parentCoordinator),
            VersionSetting(settingsDelegate: self),
            LicenseAndAcknowledgementsSetting(settingsDelegate: parentCoordinator),
        ]

        return [SettingSection(title: NSAttributedString(string: .AppSettingsAbout),
                               children: aboutSettings)]
    }

    private func getDebugSettings() -> [SettingSection] {
        var hiddenDebugOptions = [
            ExperimentsSettings(settings: self, settingsDelegate: self),
            ExportLogDataSetting(settings: self),
            ExportBrowserDataSetting(settings: self),
            AppDataUsageReportSetting(settings: self),
            DeleteExportedDataSetting(settings: self),
            ForceCrashSetting(settings: self),
            ForceRSSyncSetting(settings: self),
            ChangeToChinaSetting(settings: self),
            AppReviewPromptSetting(settings: self, settingsDelegate: self),
            ResetContextualHints(settings: self),
            ResetWallpaperOnboardingPage(settings: self, settingsDelegate: self),
            ResetTermsOfServiceAcceptancePage(settings: self, settingsDelegate: self),
            ResetSearchEnginePrefsSetting(settings: self),
            SentryIDSetting(settings: self, settingsDelegate: self),
            TermsOfUseTimeout(settings: self, settingsDelegate: self),
            OpenFiftyTabsDebugOption(settings: self, settingsDelegate: self),
            FirefoxSuggestSettings(settings: self, settingsDelegate: self),
            ScreenshotSetting(settings: self),
            DeleteLoginsKeysSetting(settings: self),
            DeleteAutofillKeysSetting(settings: self),
            ChangeRSServerSetting(settings: self),
            PopupHTMLSetting(settings: self),
            AddShortcutsSetting(settings: self, settingsDelegate: self),
            MerinoTestDataSetting(settings: self, settingsDelegate: self)
        ]

        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        hiddenDebugOptions.append(PrivacyNoticeUpdate(settings: self))
        hiddenDebugOptions.append(FeatureFlagsSettings(settings: self, settingsDelegate: self))
        #endif

        return [SettingSection(title: NSAttributedString(string: "Debug"), children: hiddenDebugOptions)]
    }

    // MARK: - DebugSettingsDelegate

    func pressedVersion() {
        debugSettingsClickCount += 1
        if debugSettingsClickCount >= 5 {
            debugSettingsClickCount = 0
            showDebugSettings = !showDebugSettings
            settings = generateSettings()
            askedToReload()
        }
    }

    func pressedExperiments() {
        parentCoordinator?.showExperiments()
    }

    func pressedShowTour() {
        parentCoordinator?.didFinishShowingSettings()

        let urlString = URL.mozInternalScheme + "://deep-link?url=/action/show-intro-onboarding"
        guard let url = URL(string: urlString) else { return }
        applicationHelper.open(url, inWindow: windowUUID)
    }

    func pressedFirefoxSuggest() {
        parentCoordinator?.showFirefoxSuggest()
    }

    func pressedOpenFiftyTabs() {
        parentCoordinator?.openDebugTestTabs(count: 50)
    }

    /// Adds 20 random shortcuts to the top sites / shortcuts library
    func pressedAddShortcuts() {
        guard let filePath = Bundle.main.path(forResource: "topdomains", ofType: "txt"),
              let fileContents = try? String(contentsOfFile: filePath, encoding: .utf8) else { return }

        let allDomains = Array(Set(
            fileContents
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty && $0.filter { $0 == "." }.count < 2 }
        ))

        let randomDomains = Array(allDomains.shuffled().prefix(20))

        let sites = Dictionary(uniqueKeysWithValues: randomDomains.map { domain in
            let title = domain.components(separatedBy: ".").first ?? domain
            let url = "https://\(domain)"
            return (title, url)
        })

        for site in sites {
            let visitObservation = VisitObservation(url: site.value, title: site.key, visitType: .link)
            _ = profile?.places.applyObservation(visitObservation: visitObservation)
        }
    }

    func pressedDebugFeatureFlags() {
        parentCoordinator?.showDebugFeatureFlags()
    }

    // MARK: SharedSettingsDelegate

    func askedToShow(alert: AlertController) {
        present(alert, animated: true) {
            // Dismiss the debug alert briefly after it's shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    func askedToReload() {
        tableView.reloadData()
    }

    override func applyTheme() {
        super.applyTheme()
        if #available(iOS 26.0, *) {
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            navigationItem.rightBarButtonItem?.tintColor = theme.colors.textPrimary
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Ecosia: Show nudge card header for default browser section
        if shouldShowDefaultBrowserNudgeCardInSection(section),
           let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: DefaultBrowserSettingsNudgeCardHeaderView.cellIdentifier) as? DefaultBrowserSettingsNudgeCardHeaderView {
            header.configure(theme: themeManager.getCurrentTheme(for: windowUUID))
            header.onDismiss = { [weak self] in
                User.shared.hideDefaultBrowserSettingNudgeCard()
                self?.hideDefaultBrowserNudgeCardInSection(section)
            }
            header.onTap = { [weak self] in
                self?.showDefaultBrowserDetailView()
            }
            return header
        }

        guard let headerView = super.tableView(
            tableView,
            viewForHeaderInSection: section
        ) as? ThemedTableSectionHeaderFooterView else {
            logger.log("Failed to cast or retrieve ThemedTableSectionHeaderFooterView for section: \(section)",
                       level: .fatal,
                       category: .lifecycle)
            return UIView()
        }
        return headerView
    }
}
