// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import CoreSpotlight
import Storage
import Shared
import Sync
import UserNotifications
import Account
import MozillaAppServices
import Common

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    let profile: Profile = AppContainer.shared.resolve()
    var sessionManager: AppSessionProvider = AppContainer.shared.resolve()
    var downloadQueue: DownloadQueue = AppContainer.shared.resolve()

    var sceneCoordinator: SceneCoordinator?
    var routeBuilder = RouteBuilder()

    // MARK: - Connecting / Disconnecting Scenes

    /// Invoked when the app creates OR restores an instance of the UI. This is also where deeplinks are handled
    /// when the app is launched from a cold start. The deeplink URLs are passed in via the `connectionOptions`.
    ///
    /// Use this method to respond to the addition of a new scene, and begin loading data that needs to display.
    /// Take advantage of what's given in `options`.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard !AppConstants.isRunningUnitTest else { return }

        // Add hooks for the nimbus-cli to test experiments on device or involving deeplinks.
        if let url = connectionOptions.urlContexts.first?.url {
            Experiments.shared.initializeTooling(url: url)
        }

        routeBuilder.configure(isPrivate: UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate),
                               prefs: profile.prefs)

        let sceneCoordinator = SceneCoordinator(scene: scene)
        self.sceneCoordinator = sceneCoordinator
        sceneCoordinator.start()

        AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(sceneCoordinator.windowUUID)]) { [weak self] in
            self?.handle(connectionOptions: connectionOptions)
        }
    }

    // MARK: - Transitioning to Foreground

    /// Invoked when the interface is finished loading for your screen, but before that interface appears on screen.
    ///
    /// Use this method to refresh the contents of your scene's view (especially if it's a restored scene), or other activities that need
    /// to begin.
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !AppConstants.isRunningUnitTest else { return }

        // Resume previously stopped downloads for, and on, THIS scene only.
        downloadQueue.resumeAll()
    }

    // MARK: - Transitioning to Background

    /// The scene's running in the background and not visible on screen.
    ///
    /// Use this method to reduce the scene's memory usage, clear claims to resources & dependencies / services.
    /// UIKit takes a snapshot of the scene for the app switcher after this method returns.
    func sceneDidEnterBackground(_ scene: UIScene) {
        downloadQueue.pauseAll()
    }

    // MARK: - Opening URLs

    /// Asks the delegate to open one or more URLs.
    ///
    /// This method is equivalent to AppDelegate's openURL method. Deeplinks opened while
    /// the app is running are passed in through this delegate method.
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        guard let url = URLContexts.first?.url,
              let route = routeBuilder.makeRoute(url: url) else { return }
        handle(route: route)
    }

    // MARK: - Continuing User Activities

    /// Use this method to handle Handoff-related data or other activities.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let route = routeBuilder.makeRoute(userActivity: userActivity) else { return }
        handle(route: route)
    }

    // MARK: - Performing Tasks

    /// Use this method to handle a selected shortcut action.
    ///
    /// Invoked when:
    /// - a user activates the application by selecting a shortcut item on the home screen AND
    /// - the window scene is already connected.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let route = routeBuilder.makeRoute(shortcutItem: shortcutItem,
                                                 tabSetting: NewTabAccessors.getNewTabPage(profile.prefs))
        else { return }
        handle(route: route)
    }

    // MARK: - Misc. Helpers

    private func handle(connectionOptions: UIScene.ConnectionOptions) {
        if let context = connectionOptions.urlContexts.first,
           let route = routeBuilder.makeRoute(url: context.url) {
            handle(route: route)
        }

        if let activity = connectionOptions.userActivities.first,
           let route = routeBuilder.makeRoute(userActivity: activity) {
            handle(route: route)
        }

        if let shortcut = connectionOptions.shortcutItem,
           let route = routeBuilder.makeRoute(shortcutItem: shortcut,
                                              tabSetting: NewTabAccessors.getNewTabPage(profile.prefs)) {
            handle(route: route)
        }

        // Check if our connection options include a user response to a push
        // notification that is for Sent Tabs. If so, route the related tab URLs.
        let sentTabsKey = NotificationSentTabs.sentTabsKey
        if let notification = connectionOptions.notificationResponse?.notification,
           let userInfo = notification.request.content.userInfo[sentTabsKey] as? [[String: Any]] {
            handleConnectionOptionsSentTabs(userInfo)
        }
    }

    private func handleConnectionOptionsSentTabs(_ userInfo: [[String: Any]]) {
        // For Sent Tab data structure, see also:
        // NotificationService.displayNewSentTabNotification()
        for tab in userInfo {
            guard let urlString = tab["url"] as? String,
                  let url = URL(string: urlString),
                  let route = routeBuilder.makeRoute(url: url) else { continue }
            handle(route: route)
        }
    }

    private func handle(route: Route) {
        sessionManager.launchSessionProvider.openedFromExternalSource = true
        sceneCoordinator?.findAndHandle(route: route)
    }
}
