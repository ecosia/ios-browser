// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage
import TabDataStore
@testable import Client

// Ecosia: Minimal SearchEngineProvider that completes immediately with no engines.
// Used in DependencyHelperMock to prevent real background network calls (via ASSearchEngineProvider /
// EcosiaSearchEngineProvider) from running during tests. Without this, the default provider dispatches
// DispatchQueue.global().async work that later tries to resolve Profile from AppContainer on a background
// thread — racing with the next test's AppContainer.shared.reset() and causing a fatalError crash.
private final class NoOpSearchEngineProvider: SearchEngineProvider, @unchecked Sendable {
    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v1
    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        DispatchQueue.main.async {
            completion(engineOrderingPrefs, [])
        }
    }
}

class DependencyHelperMock {
    @MainActor
    func bootstrapDependencies(
        injectedTabManager: TabManager? = nil,
        injectedWindowManager: WindowManager? = nil,
        injectedMicrosurveyManager: MicrosurveyManager? = nil,
        themeManager: ThemeManager = MockThemeManager() // Ecosia: Make themeManager injectable
    ) {
        AppContainer.shared.reset()

        // Ecosia: Register every service under the PROTOCOL type the consumers resolve
        // by (`as Profile`, `as ThemeManager`, …), mirroring the production
        // DependencyHelper. This is the Swift 6 adaptation of the main-133 baseline:
        // pre-upgrade, `register(service: profile)` with `profile` typed as the protocol
        // keyed the Dip definition by the protocol. Swift 6.2's implicit existential
        // opening now infers the generic T from the *concrete* dynamic type, so without
        // the explicit cast the registration is keyed by the concrete type (MockProfile,
        // DefaultDiskImageStore, …) while Firefox-core Coordinators resolve by protocol —
        // a key mismatch that throws "No definition registered for type: Profile/…" and
        // crash-thrashes the suite. Proven via pointer+type instrumentation: same
        // AppContainer instance, registered-type ≠ resolved-type. Tracked in MOB-4384.
        let placeholderProfile: Client.Profile = MockProfile()
        AppContainer.shared.register(service: placeholderProfile as Profile)

        let documentLogger = DocumentLogger(logger: DefaultLogger.shared)
        AppContainer.shared.register(service: documentLogger)

        AppContainer.shared.register(service: themeManager as ThemeManager)

        let windowUUID = WindowUUID.XCTestDefaultUUID
        let windowManager: WindowManager = injectedWindowManager ?? MockWindowManager(wrappedManager: WindowManagerImplementation())
        AppContainer.shared.register(service: windowManager as WindowManager)

        let appSessionProvider: AppSessionProvider = AppSessionManager()
        AppContainer.shared.register(service: appSessionProvider as AppSessionProvider)

        let downloadQueue = DownloadQueue()
        AppContainer.shared.register(service: downloadQueue)

        let microsurveyManager: MicrosurveyManager = injectedMicrosurveyManager ?? MockMicrosurveySurfaceManager()
        AppContainer.shared.register(service: microsurveyManager as MicrosurveyManager)

        // Profile creation is slow (opens SQLite databases, etc.). All lightweight services
        // and the placeholder profile above are already registered before this point.
        let profile: Client.Profile = BrowserProfile(localName: "profile")
        AppContainer.shared.register(service: profile as Profile)

        let diskImageStore: DiskImageStore = DefaultDiskImageStore(
            files: profile.files,
            namespace: TabManagerConstants.tabScreenshotNamespace,
            quality: UIConstants.ScreenshotQuality)
        AppContainer.shared.register(service: diskImageStore as DiskImageStore)

        // Ecosia: Use NoOpSearchEngineProvider so no background DispatchQueue.global() work
        // is dispatched (see comment on NoOpSearchEngineProvider above).
        let searchEnginesManager = SearchEnginesManager(prefs: profile.prefs,
                                                        files: profile.files,
                                                        engineProvider: NoOpSearchEngineProvider())
        AppContainer.shared.register(service: searchEnginesManager)

        // Ecosia: Also register the services the production DependencyHelper registers
        // but this mock previously omitted (MOB-4384). Firefox-core Coordinators (e.g.
        // SettingsCoordinator) resolve these via fatal default-arg AppContainer.resolve();
        // if a test instantiates such a Coordinator and the type was never registered the
        // process crashes. MerinoManagerProvider is a protocol (register under the
        // protocol type); GleanUsageReportingMetricsService is a concrete class.
        let merinoManager: MerinoManagerProvider = MerinoManager(
            storyProvider: StoryProvider(merinoAPI: MerinoProvider(prefs: profile.prefs))
        )
        AppContainer.shared.register(service: merinoManager as MerinoManagerProvider)

        let gleanUsageReportingMetricsService = GleanUsageReportingMetricsService(profile: profile)
        AppContainer.shared.register(service: gleanUsageReportingMetricsService)

        // Ecosia: GleanPlumbMessageManagerProtocol is resolved from AppContainer by some
        // ClientTests paths but is not a production DependencyHelper service (production
        // uses Experiments.messaging as a default). Register the existing test mock under
        // the protocol so those resolves succeed instead of crashing. Tracked in MOB-4384.
        let gleanPlumbMessageManager: GleanPlumbMessageManagerProtocol = MockGleanPlumbMessageManagerProtocol()
        AppContainer.shared.register(service: gleanPlumbMessageManager as GleanPlumbMessageManagerProtocol)

        let tabManager: TabManager =
        injectedTabManager ?? TabManagerImplementation(profile: profile,
                                                       uuid: ReservedWindowUUID(uuid: windowUUID, isNew: false),
                                                       windowManager: windowManager)

        let ratingPromptManager = RatingPromptManager(prefs: profile.prefs, crashTracker: DefaultCrashTracker())
        AppContainer.shared.register(service: ratingPromptManager)

        // Ecosia: Register the window UNCONDITIONALLY, matching upstream v147.5. A prior Ecosia change
        // guarded this with `if injectedWindowManager == nil`, which left tests that inject their own
        // WindowManager (e.g. ToolbarMiddlewareTests) without a window for WindowUUID.XCTestDefaultUUID —
        // causing `WindowManager.swift: Fatal error: No window for UUID …` crashes. (MOB-4384)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: windowUUID)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }

    func reset() {
        // Ecosia: Do NOT call AppContainer.shared.reset() here. bootstrapDependencies() already
        // calls reset() at the very start of the next test's setUp, so clearing the container in
        // tearDown would only extend the window in which the container is empty and background app
        // tasks (e.g. from SceneCoordinator or BrowserCoordinator) can race to resolve a service
        // that isn't registered yet, causing a fatalError crash.
        // The services from the current test remain registered until the next bootstrapDependencies()
        // replaces them, which is the safest possible state between tests.
    }
}
