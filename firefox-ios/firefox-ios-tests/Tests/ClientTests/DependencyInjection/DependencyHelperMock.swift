// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage
import TabDataStore
@testable import Client

class DependencyHelperMock {
    // Ecosia: Make themeManager injectable
    // func bootstrapDependencies(injectedTabManager: TabManager? = nil) {
    func bootstrapDependencies(injectedTabManager: TabManager? = nil, themeManager: ThemeManager = MockThemeManager()) {
        AppContainer.shared.reset()

        let profile: Client.Profile = BrowserProfile(
            localName: "profile"
        )
        AppContainer.shared.register(service: profile)

        let tabDataStore: TabDataStore = MockTabDataStore()
        AppContainer.shared.register(service: tabDataStore)

        let windowUUID = WindowUUID()
        let tabManager: TabManager = injectedTabManager ?? TabManagerImplementation(
            profile: profile,
            imageStore: DefaultDiskImageStore(
                files: profile.files,
                namespace: "TabManagerScreenshots",
                quality: UIConstants.ScreenshotQuality),
            uuid: windowUUID
        )

        let appSessionProvider: AppSessionProvider = AppSessionManager()
        AppContainer.shared.register(service: appSessionProvider)
        // Ecosia: Remove themeManager constant
        // let themeManager: ThemeManager = MockThemeManager()
        AppContainer.shared.register(service: themeManager)

        let ratingPromptManager = RatingPromptManager(profile: profile)
        AppContainer.shared.register(service: ratingPromptManager)

        let downloadQueue = DownloadQueue()
        AppContainer.shared.register(service: downloadQueue)

        let windowManager: WindowManager = WindowManagerImplementation()
        AppContainer.shared.register(service: windowManager)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: windowUUID)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }

    func reset() {
        AppContainer.shared.reset()
    }
}
