import ProjectDescription

/// Ecosia schemes.
///
/// Test targets and skipped tests are declared inline so Tuist resolves
/// identifiers at generation time — no manually-maintained .xctestplan
/// with fragile UUIDs needed.
public enum EcosiaSchemes {

    // MARK: - Shared test targets

    /// Test targets shared by Ecosia & EcosiaBeta schemes.
    private static let unitTestTargets: [TestableTarget] = [
        "EcosiaTests",
        "ClientTests",
        "SyncTests",
        "StorageTests",
        "SharedTests",
        "SyncTelemetryTests",
    ]

    /// Tests to skip across all unit-test schemes.
    ///
    /// Format: `"ClassName/methodName()"` for a single test,
    ///         `"ClassName"` for an entire test class.
    /// These are written into the xcscheme's `<SkippedTests>` section.
    private static let skippedTests: [String] = [
        // EcosiaTests — AppDelegate integration tests
        //
        // Root cause: These tests call DependencyHelperMock().bootstrapDependencies() which
        // calls AppContainer.shared.reset(). The test host is a real iOS app whose startup
        // (application(_:willFinishLaunchingWithOptions:)) kicked off async tasks that hold
        // on to AppContainer service references (e.g. Storage.DiskImageStore via
        // TabManagerImplementation). When reset() clears the container in setUp, those
        // in-flight async tasks try to re-resolve DiskImageStore and fatal-crash before any
        // test code runs. There is no safe way to cancel or drain the host-app tasks without
        // modifying production code. Tracked in MOB-4384.
        "AppDelegateFeatureManagementIntegrationTests",
        "AppDelegateMMPIntegrationTests",

        // EcosiaTests — AnalyticsSpyTests
        //
        // The class-level skip was reduced to only the tests that call appDelegate methods or
        // trigger a full DI bootstrap. The DI-independent tests were extracted to
        // AnalyticsContextTests and run without issues. The remaining AnalyticsSpyTests tests
        // use DependencyHelperMock().bootstrapDependencies() and interact with AppDelegate
        // (application(_:didFinishLaunchingWithOptions:), applicationDidBecomeActive(_:)),
        // which carries the same AppContainer reset race as the AppDelegate integration tests
        // above. Tracked in MOB-4384.
        "AnalyticsSpyTests",

        // ClientTests
        "ContentBlockerTests/testCompileListsNotInStore_callsCompletionHandlerSuccessfully()",
        "GeneralizedImageFetcherTests/testBadStatusCode()",
        "GeneralizedImageFetcherTests/testErrorResponse()",
        "GeneralizedImageFetcherTests/testNilData()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_withMalformedURL()",
        // Ecosia: testHasSeenIntroScreen_shouldNotShowIt is commented out in source (replaced by
        // Ecosia-specific intro logic) — skip entry removed to avoid maintaining dead references.
        "ShortcutRouteTests",
        "SyncContentSettingsViewControllerTests",
        // Ecosia: The wallpaper settings header is not yet surfaced as a feature in the Ecosia app (coming soon).
        // This test asserts a collection-JSON-driven description (nil when the collection has none), but the
        // current production header uses hardcoded Limited-Edition strings, and real collections ship null
        // heading/description — so implementing it now would regress the live UI. Skip until the wallpaper
        // feature ships, then implement collection-driven headers and re-enable. (MOB-4384)
        "WallpaperSettingsViewModelTests/testSectionHeaderViewModel_headingWithoutDescription()",
        // Ecosia: testLoadSummary forces the Firefox HOSTED summarizer (setIsHostedSummaryEnabled(true)); the
        // production path spins up a real web-process summarization and HANGS (2-min timeout) in the test host.
        // Ecosia ships the Apple-Intelligence summarizer only (hosted summarizer disabled), so this is a
        // Firefox-only path. Skip until/unless Ecosia ships a hosted summarizer. (MOB-4384)
        "ToolbarMiddlewareTests/testLoadSummary_dispatchesToolbarAction()",

        // Ecosia: The following ClientTests cover Firefox-only features that Ecosia does not ship, so they
        // assert Firefox production behavior that diverges in Ecosia — syncing the test to upstream would not
        // help (the difference is in production, not the test). They subscript arrays that are shorter under
        // Ecosia, which CRASHES (index-out-of-range / "no TabManager"), so they are skipped per the
        // "evaluate relevance, otherwise disable" guidance. (MOB-4384)
        // - Firefox SearchPlugins/list.json is not bundled in the Ecosia Client app (Ecosia ships its own search):
        "DefaultSearchPrefsTests/testParsing_hasAllInfo_succeeds()",
        // - Firefox sponsored top-site tiles are not shown on the Ecosia NTP:
        "TopSitesManagerTests/test_recalculateTopSites_duplicatePinnedTile_doesNotShowDuplicateSponsoredSite()",
        // - Firefox "Terms of Use" acceptance telemetry — Ecosia uses its own ToS/onboarding flow:
        "TermsOfServiceTelemetryTests/testRecordTermsOfServiceAcceptButtonTappedThenGleanIsCalled()",
        // - Firefox Sync engine prefs — Ecosia authenticates via Auth0 and does not use Firefox Sync. The whole
        //   testUpdateEnginePrefs_* family crashes with an unowned-reference lifetime error (RustSyncManager is
        //   not instantiated in Ecosia production), so skip the class:
        "RustSyncManagerTests",
        // Ecosia: These TelemetryWrapperTests record settings via the DEPRECATED `(.action,.change,.setting)`
        // path, which v147 deliberately fatal-asserts ("use SettingsTelemetry().changedSetting()") — PR #29799
        // moved settings telemetry to SettingsTelemetry. With telemetry recording enabled for tests they crash;
        // upstream removed these. Skipped as a stale deprecated-path test. (MOB-4384)
        "TelemetryWrapperTests/test_preferencesWithExtras_GleanIsCalled()",
        "TelemetryWrapperTests/test_preferencesWithoutExtras_GleanIsNotCalled()",
        // Ecosia: App-error Glean metrics (AppErrors.crashedLastLaunch/tabLossDetected/cpuException/hangException/
        // largeFileWrite) are intentionally commented out in TelemetryWrapper.gleanRecordEvent (Ecosia silences
        // Firefox telemetry; uses Snowplow). These tests assert those disabled metrics record, so they cannot
        // pass — skipped as a disabled-feature per "evaluate relevance, otherwise disable". (MOB-4384)
        "TelemetryWrapperTests/test_error_crashedLastLaunchIsCalled()",
        "TelemetryWrapperTests/test_error_tabLossDetectedIsCalled()",
        "TelemetryWrapperTests/test_error_cpuExceptionIsCalled()",
        "TelemetryWrapperTests/test_error_hangExceptionIsCalled()",
        "TelemetryWrapperTests/test_error_largeFileWriteIsCalled()",

        // Ecosia: User-confirmed Firefox features NOT shipped by Ecosia (Ecosia has a custom NTP /
        // NTPLayout.swift, Snowplow analytics, and its own status bar). These tests assert that Firefox
        // production behavior, which Ecosia replaces — relevance-skipped per "evaluate relevance, otherwise
        // disable". (MOB-4384)
        // - Pocket/Merino story feed (Ecosia NTP has no Pocket stories):
        "MerinoProviderTests/test_fetchStories_cachesManyStories_returnsRequired()",
        "MerinoProviderTests/test_fetchStories_fetchesAndSaves_whenNoCache()",
        "MerinoProviderTests/test_fetchStories_fetchesAndSaves_whenThresholdPassed()",
        "MerinoProviderTests/test_fetchStories_fetches_whenNoLastUpdatedEvenIfItemsExist()",
        "MerinoProviderTests/test_fetchStories_returnsCached_whenThresholdNotPassed()",
        // - iOS-26 translucent "glass" status bar overlay (whole class asserts the old opaque behavior):
        "StatusBarOverlayTests",
        // - Firefox sponsored top-site tiles (Ecosia NTP shows none):
        "TopSitesManagerTests/test_fetchSponsoredSites_forUnifiedAds_withSuccessData_returnSponsoredSites()",
        "TopSitesManagerTests/test_recalculateTopSites_andNoPinnedSites_returnGoogleAndSponsoredSites()",
        "TopSitesManagerTests/test_recalculateTopSites_availableSpace_returnSitesInOrder()",
        "TopSitesManagerTests/test_recalculateTopSites_matchingSponsoredAndHistoryBasedTiles_removeDuplicates()",
        "TopSitesManagerTests/test_recalculateTopSites_shouldShowSponsoredSites_returnOnlyMaxSponsoredSites()",
        "TopSitesManagerTests/test_recalculateTopSites_withOtherSitesAndNoGoogleSite_returnNoGoogleTopSite()",
        "TopSitesManagerTests/test_searchEngine_sponsoredSite_getsRemoved()",
        // - Firefox homepage stories-redesign + glass status-bar scroll coupling:
        "HomepageViewControllerTests/test_newState_forTriggeringImpression_withStoriesRedesignEnabled_triggersHomepageAction()",
        "HomepageViewControllerTests/test_scrollViewDidEndDecelerating_withStoriesRedesignEnabled_triggersHomepageAction()",
        "HomepageViewControllerTests/test_viewDidAppear_withStoriesRedesignEnabled_triggersHomepageAction()",
        "HomepageViewControllerTests/test_scrollToTop_updatesStatusBarScrollDelegate_andSetsCollectionViewOffset()",
        "HomepageViewControllerTests/test_newState_didSelectedTabChangeToHomepageAction_forScrollToTop_setsCollectionViewOffsetToZero()",

        // Ecosia: Firefox's Glean telemetry is NOT used at all in Ecosia (Ecosia uses Snowplow via
        // Analytics.shared, tested separately by EcosiaTests/AnalyticsSpyTests). DefaultGleanWrapper delegates
        // every metric to FakeGleanWrapper (no-op) for privacy, so all these ClientTests — which assert Firefox
        // Glean metrics via `testGetValue()` — test a deliberately-disabled feature and cannot pass. Skipped per
        // "evaluate relevance, otherwise disable" (user-confirmed). (MOB-4384)
        "ActionExtensionTelemetryTests",
        "AdjustTelemetryHelperTests",
        "AppIconSelectionTelemetryTests",
        "BookmarksTelemetryTests",
        "ContextMenuTelemetryTests",
        "HistoryDeletionUtilityTelemetryTests",
        "MainMenuTelemetryTests",
        "MicrosurveyTelemetryTests",
        "NotificationManagerTelemetryTests",
        "OnboardingTelemetryDelegationTests",
        "OnboardingTelemetryUtilityTests",
        "PasswordGeneratorTelemetryTests",
        "PrivateBrowsingTelemetryTests",
        "SearchTelemetryTests",
        "SettingsTelemetryTests",
        "ShareExtensionTelemetryTests",
        "ShareTelemetryActivityItemProviderTests",
        "ShareTelemetryTests",
        "StoriesFeedTelemetryTests",
        "TabsTelemetryTests",
        "TelemetryContextualIdentifierTests",
        "TelemetryWrapperTests",
        "TermsOfServiceTelemetryTests",
        "TermsOfUseTelemetryTests",
        "ToastTelemetryTests",
        "ToolbarTelemetryTests",
        "TranslationsTelemetryTests",
        "UnifiedAdsCallbackTelemetryTests",
        "UserTelemetryTests",
        "WebviewTelemetryTests",
        "ZoomTelemetryTests",
        // Ecosia: Firefox-Glean telemetry tests living inside non-*Telemetry* (mixed) classes — same rationale
        // as above (Firefox Glean not used; Ecosia uses Snowplow). Only the Glean-asserting tests are skipped;
        // the logic tests in these classes (e.g. GleanPlumb testManagerGetMessage, DefaultBrowser
        // savesDatesinUserDefaults) still run. (MOB-4384)
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_linkWithEmbeddedParam()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_linkWithEmbeddedParamAndOneActionParam()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_linkWithOneParam()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_linkWithScheme()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_linkWithTwoParams()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_withNoAction()",
        "GleanPlumbMessageManagerTests/testManagerOnMessagePressed_withoutExpiring()",
        "DefaultBrowserUtilityTests/testAPIError_recordsTelemetryWithErrorDetails()",
        "DefaultBrowserUtilityTests/testFirstLaunchWithDMAUser()",
        "DefaultBrowserUtilityTests/testFirstLaunchWithNonDMAUser()",
        "DefaultBrowserUtilityTests/testSecondLaunchWithDMAUser()",
        "DefaultBrowserUtilityTests/testSecondLaunchWithNonDMAUser()",
        "MerinoMiddlewareTests/test_tapOnHomepagePocketCellAction_sendTelemetryData()",
        "MerinoMiddlewareTests/test_viewedSectionAction_sendTelemetryData()",
        "TopSitesMiddlewareTests/test_tappedOnHomepageTopSite_forSponsoredSites_withUnifiedAds_sendsTelemetry()",
        "TopSitesMiddlewareTests/test_tappedOnHomepageTopSite_withoutIsZeroSearch_forSuggestedSites_sendsCorrectTelemetry()",
        "MicrosurveyMiddlewareIntegrationTests/testDismissSurveyAction()",
        "MicrosurveyMiddlewareIntegrationTests/testPrivacyNoticeTappedAction()",
        "MicrosurveyMiddlewareIntegrationTests/testSubmitSurveyAction()",
        "MicrosurveyMiddlewareIntegrationTests/testConfirmationViewedAction()",
        "HomepageMiddlewareTests/test_sectionSeenAction_sendTelemetryData()",

        // EcosiaTests — TopSiteNativeContextMenuTests
        //
        // Root cause: setUp() calls DependencyHelperMock().bootstrapDependencies() + creates a
        // HomepageViewController. A background thread (GCD global queue, origin unconfirmed without
        // a full crash stacktrace) calls AppContainer.shared.resolve() as Profile while the container
        // is being rebuilt — crashing the test process for every test in the class. The DiskImageStore
        // warning that precedes the crash (Dip log, resolveOptional) suggests a TabManagerImplementation
        // or BrowserViewController init is being triggered from a scene lifecycle path on a background
        // thread concurrent with test setUp. Tracked in MOB-4384 for follow-up with a real stack trace.
        "TopSiteNativeContextMenuTests",

        // EcosiaTests — EcosiaStartAtHomeMiddlewareTests
        //
        // Verified self-contained crasher: run *in isolation* it restarts repeatedly and
        // executes 0 tests. setUp() calls DependencyHelperMock().bootstrapDependencies()
        // and drives the real EcosiaStartAtHomeMiddleware through a Redux store
        // (StoreTestUtility). The crash is the same architectural defect tracked in
        // MOB-4384: app-hosted unit tests run the full production Client.app startup, whose
        // background work resolves services from the global Dip AppContainer that
        // fatalErrors on a miss (compounded by a BrazeUI/BrazeKit duplicate-class link in
        // the EcosiaTests bundle). Four mitigation attempts (resolveOptional, Profile-first,
        // removing reset() from bootstrapDependencies, launch-time UnitTestAppDelegate
        // detection) were tried and verified insufficient — per systematic-debugging
        // Phase 4.5 this is an architecture decision, not another patch. Skipped here using
        // the same single-class strategy as the entries above. Tracked in MOB-4384.
        "EcosiaStartAtHomeMiddlewareTests",

        // StorageTests
        "TestBrowserDB/testMovesDB()",
        // Ecosia: CertTests and TestBrowserDB/testUpgradeV33toV34RemovesLongURLs() were
        // skipped because the .pem certificates and v33.db fixture were missing from the
        // StorageTests bundle. The resource globs added in Targets+Tests.swift now ship
        // testcert1.pem, testcert2.pem and fixtures/v33.db into StorageTests.xctest
        // (verified in the built bundle), so both are re-enabled here. Tracked in MOB-4384.
    ]

    /// Environment for the unit-test run.
    ///
    /// These keys are normally injected via the signing xcconfig (CI secrets) and are
    /// absent in local / unsecured environments:
    ///
    /// - AUTH0_CLIENT_ID: without it, DefaultAuth0SettingsProvider.id calls
    ///   fatalError("AUTH0_CLIENT_ID not found"), which crashes every test that
    ///   transitively constructs EcosiaAuthenticationService (e.g. AccountsServiceTests),
    ///   thrash-restarting the whole xcodebuild run.
    /// - CF_ACCESS_CLIENT_ID / CF_ACCESS_CLIENT_SECRET: without them,
    ///   Environment.cloudFlareAuth returns nil for .staging, so the Cloudflare
    ///   access headers are never attached to staging requests — failing
    ///   AnalyticsTests.test_makeNetworkConfig_usesMicroEndpoint_whenShouldUseMicroIsTrue
    ///   and UnleashTests.testMakeRequest, which assert those headers are present.
    ///
    /// Non-secret placeholders are safe here: no test asserts the values (only header
    /// presence / non-fatal id), and all network calls are mocked. EnvironmentFetcher
    /// checks Bundle.main before ProcessInfo, so a real CI-provided value still takes
    /// precedence. Tracked in MOB-4384.
    ///
    /// ECOSIA_RUN_UNIT_TESTS is read by main.swift at UIApplicationMain time to select the
    /// minimal UnitTestAppDelegate. NSClassFromString("XCTestCase") is nil that early for
    /// app-hosted tests (XCTest is DYLD-injected post-launch), so without this the production
    /// AppDelegate runs during unit tests and its background work crashes the suite via the
    /// global AppContainer. It is an *environment variable* (not a launch argument): the
    /// environment is inherited by the host process at exec and is therefore readable at
    /// launch — the same path that makes AUTH0_CLIENT_ID reach the host — whereas scheme
    /// command-line arguments are not forwarded to the app-hosted host under
    /// `xcodebuild test-without-building`. Tracked in MOB-4384.
    private static let testArguments: Arguments = .arguments(environmentVariables: [
        "AUTH0_CLIENT_ID": .environmentVariable(value: "test-auth0-client-id", isEnabled: true),
        "CF_ACCESS_CLIENT_ID": .environmentVariable(value: "test-cf-access-client-id", isEnabled: true),
        "CF_ACCESS_CLIENT_SECRET": .environmentVariable(value: "test-cf-access-client-secret", isEnabled: true),
        "ECOSIA_RUN_UNIT_TESTS": .environmentVariable(value: "1", isEnabled: true)
    ])

    // MARK: - Schemes

    public static let all: [Scheme] = [
        .scheme(
            name: "Ecosia",
            buildAction: .buildAction(targets: ["Client"]),
            testAction: .targets(
                unitTestTargets,
                arguments: testArguments,
                configuration: "Testing",
                attachDebugger: false,
                skippedTests: skippedTests
            ),
            runAction: .runAction(
                executable: "Client",
                arguments: .arguments(environmentVariables: [
                    "OS_ACTIVITY_MODE": .environmentVariable(value: "${DEBUG_ACTIVITY_MODE}", isEnabled: true),
                    "DYLD_PRINT_STATISTICS": .environmentVariable(value: "1", isEnabled: true)
                ])
            )
        ),
        .scheme(
            name: "EcosiaBeta",
            buildAction: .buildAction(targets: ["Client"]),
            testAction: .targets(
                unitTestTargets,
                arguments: testArguments,
                configuration: "Testing",
                attachDebugger: false,
                skippedTests: skippedTests
            ),
            runAction: .runAction(
                configuration: "BetaDebug",
                executable: "Client",
                arguments: .arguments(environmentVariables: [
                    "OS_ACTIVITY_MODE": .environmentVariable(value: "${DEBUG_ACTIVITY_MODE}", isEnabled: true)
                ])
            )
        ),
        .scheme(
            name: "EcosiaSnapshotTests",
            buildAction: .buildAction(targets: ["EcosiaSnapshotTests"]),
            testAction: .targets(
                ["EcosiaSnapshotTests"],
                configuration: .debug
            ),
            runAction: .runAction(executable: "Client")
        ),
    ]
}