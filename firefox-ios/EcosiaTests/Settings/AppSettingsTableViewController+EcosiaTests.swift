// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
@testable import Ecosia

import Common
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

final class AppSettingsTableViewControllerEcosiaTests: XCTestCase {
    private var profile: MockProfile!
    private var tabManager: TabManager!
    private var delegate: MockSettingsFlowDelegate!
    private var settingsDelegate: MockSettingsDelegate!

    override func setUp() async throws {
        try await super.setUp()
        Unleash.clearInstanceModel()
        await DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        tabManager = await TabManagerImplementation(profile: profile,
                                                    uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        delegate = MockSettingsFlowDelegate()
        settingsDelegate = MockSettingsDelegate()
    }

    override func tearDown() async throws {
        Unleash.clearInstanceModel()
        DependencyHelperMock().reset()
        profile = nil
        tabManager = nil
        delegate = nil
        settingsDelegate = nil
        try await super.tearDown()
    }

    @MainActor
    func testSendCrashReportsSetting_whenSentryExperimentEnabled_isShown() {
        setSentryReportingExperiment(enabled: true)
        let subject = createSubject()

        XCTAssertNotNil(sendCrashReportsSetting(in: subject))
    }

    @MainActor
    func testSendCrashReportsSetting_whenSentryExperimentDisabled_isHidden() {
        setSentryReportingExperiment(enabled: false)
        let subject = createSubject()

        XCTAssertNil(sendCrashReportsSetting(in: subject))
    }

    @MainActor
    func testSendCrashReportsSetting_whenShown_isBackedByPrefSendCrashReportsKey() {
        setSentryReportingExperiment(enabled: true)
        let subject = createSubject()

        XCTAssertEqual(sendCrashReportsSetting(in: subject)?.prefKey, AppConstants.prefSendCrashReports)
    }

    // MARK: - AI-free searching replaces Firefox's AI controls hub (MOB-5035)

    @MainActor
    func testAIFeatureRows_whenAIFreeSearchingIsOffered_areHidden() {
        setUnleash(aiFreeSearching: true)
        let subject = createSubject(appleIntelligenceAvailable: true)

        XCTAssertFalse(generalSettingsContain(SummarizeSetting.self, in: subject))
        XCTAssertFalse(generalSettingsContain(TranslationSetting.self, in: subject))
    }

    /// Covers every reason the toggle is not offered, including a non-Ecosia search provider
    /// (see `AIFreeSearchingSelectionTests.testIsAvailableIsFalseWithACustomSearchProvider`): Settings
    /// syncs the provider from the default engine, which these tests leave at Ecosia.
    @MainActor
    func testAIFeatureRows_whenAIFreeSearchingIsNotOffered_areShown() {
        setUnleash(aiFreeSearching: false)
        let subject = createSubject(appleIntelligenceAvailable: true)

        XCTAssertTrue(generalSettingsContain(SummarizeSetting.self, in: subject))
        XCTAssertTrue(generalSettingsContain(TranslationSetting.self, in: subject))
    }

    @MainActor
    func testSummarizeRow_onADeviceThatCannotSummarize_isHidden() {
        setUnleash(aiFreeSearching: false)
        let subject = createSubject(appleIntelligenceAvailable: false)

        XCTAssertFalse(generalSettingsContain(SummarizeSetting.self, in: subject))
        XCTAssertTrue(generalSettingsContain(TranslationSetting.self, in: subject))
    }

    // MARK: - Helper

    private func setUnleash(aiFreeSearching: Bool) {
        let toggle = Unleash.Toggle(name: Unleash.Toggle.Name.aiFreeSearching.rawValue,
                                    enabled: aiFreeSearching,
                                    variant: Unleash.Variant(name: "", enabled: false, payload: nil))
        Unleash.model = Unleash.Model(toggles: Set([toggle]))
    }

    @MainActor
    private func generalSettingsContain<T: Setting>(_ type: T.Type, in subject: AppSettingsTableViewController) -> Bool {
        let generalSection = subject.generateSettings().first {
            $0.title?.string == String.SettingsGeneralSectionTitle
        }
        return generalSection?.children.contains { $0 is T } ?? false
    }

    private func setSentryReportingExperiment(enabled: Bool) {
        let toggle = Unleash.Toggle(name: Unleash.Toggle.Name.sentryReporting.rawValue,
                                    enabled: enabled,
                                    variant: Unleash.Variant(name: "", enabled: false, payload: nil))
        Unleash.model = Unleash.Model(toggles: enabled ? Set([toggle]) : [])
    }

    @MainActor
    private func sendCrashReportsSetting(in subject: AppSettingsTableViewController) -> BoolSetting? {
        let supportSection = subject.generateSettings().first {
            $0.title?.string == String.AppSettingsSupport
        }
        return supportSection?.children.compactMap { $0 as? BoolSetting }
            .first { $0.prefKey == AppConstants.prefSendCrashReports }
    }

    @MainActor
    private func createSubject(appleIntelligenceAvailable: Bool = false) -> AppSettingsTableViewController {
        let subject = AppSettingsTableViewController(with: profile,
                                                     and: tabManager,
                                                     settingsDelegate: settingsDelegate,
                                                     parentCoordinator: delegate,
                                                     gleanUsageReportingMetricsService: GleanUsageReportingMetricsService(profile: profile),
                                                     appAuthenticator: MockAppAuthenticator(),
                                                     applicationHelper: MockApplicationHelper(),
                                                     summarizerNimbusUtils: DefaultSummarizerNimbusUtils.make(
                                                        profile: profile,
                                                        appleIntelligenceAvailable: appleIntelligenceAvailable
                                                     ))
        trackForMemoryLeaks(subject)
        return subject
    }
}
// swiftlint:enable implicitly_unwrapped_optional
