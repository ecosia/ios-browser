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

        // Ecosia: Register Profile FIRST — before any other service — so that background threads
        // lingering from the previous test can still resolve Profile without crashing. Any such
        // thread will see a MockProfile (which is harmless) rather than a missing registration.
        // All other lightweight services are registered immediately after, before the slow
        // BrowserProfile creation further below.
        let placeholderProfile: Client.Profile = MockProfile()
        AppContainer.shared.register(service: placeholderProfile)

        let documentLogger = DocumentLogger(logger: DefaultLogger.shared)
        AppContainer.shared.register(service: documentLogger)

        AppContainer.shared.register(service: themeManager)

        let windowUUID = WindowUUID.XCTestDefaultUUID
        let windowManager: WindowManager = injectedWindowManager ?? MockWindowManager(wrappedManager: WindowManagerImplementation())
        AppContainer.shared.register(service: windowManager)

        let appSessionProvider: AppSessionProvider = AppSessionManager()
        AppContainer.shared.register(service: appSessionProvider)

        let downloadQueue = DownloadQueue()
        AppContainer.shared.register(service: downloadQueue)

        let microsurveyManager: MicrosurveyManager = injectedMicrosurveyManager ?? MockMicrosurveySurfaceManager()
        AppContainer.shared.register(service: microsurveyManager)

        // Profile creation is slow (opens SQLite databases, etc.). All lightweight services
        // and the placeholder profile above are already registered before this point.
        let profile: Client.Profile = BrowserProfile(localName: "profile")
        AppContainer.shared.register(service: profile)

        let diskImageStore: DiskImageStore = DefaultDiskImageStore(
            files: profile.files,
            namespace: TabManagerConstants.tabScreenshotNamespace,
            quality: UIConstants.ScreenshotQuality)
        AppContainer.shared.register(service: diskImageStore)

        // Ecosia: Use NoOpSearchEngineProvider so no background DispatchQueue.global() work
        // is dispatched (see comment on NoOpSearchEngineProvider above).
        let searchEnginesManager = SearchEnginesManager(prefs: profile.prefs,
                                                        files: profile.files,
                                                        engineProvider: NoOpSearchEngineProvider())
        AppContainer.shared.register(service: searchEnginesManager)

        let tabManager: TabManager =
        injectedTabManager ?? TabManagerImplementation(profile: profile,
                                                       uuid: ReservedWindowUUID(uuid: windowUUID, isNew: false),
                                                       windowManager: windowManager)

        let ratingPromptManager = RatingPromptManager(prefs: profile.prefs, crashTracker: DefaultCrashTracker())
        AppContainer.shared.register(service: ratingPromptManager)

        if injectedWindowManager == nil {
            windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: windowUUID)
        }

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
