// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreSpotlight

final class RootViewControllerAppDelegate: AppDelegateLeaf {
    
    var window: UIWindow?
    private var profile: Profile
    private var tabManager: TabManager
    private var coordinator: MainCoordinator?
    private var browserViewController: BrowserViewController!

    required init(profile: Profile,
                  window: UIWindow?,
                  tabManager: TabManager,
                  coordinator: MainCoordinator?) {
        self.profile = profile
        self.window = window
        self.tabManager = tabManager
        self.coordinator = coordinator
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        if !LegacyThemeManager.instance.systemThemeIsOn {
            window?.overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
        }
        
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)

        coordinator = MainCoordinator(navigationController: navigationController, profile: profile, tabManager: tabManager, welcomeDelegate: self)
        coordinator?.start()
        browserViewController = coordinator?.browserViewController
        
        /// Workaround to keep the `browserViewController` isolated
        /// as the `browserViewController`'s AppDelegate's instance is too spreaded throughout the codebase
        (UIApplication.shared.delegate as? AppDelegate)?.browserViewController = browserViewController
        
        window!.rootViewController = navigationController
        
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        window!.makeKeyAndVisible()
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        /// When transitioning to scenes, each scene's BVC needs to resume its file download queue.
        browserViewController.downloadQueue.resumeAll()
        
        // Delay these operations until after UIKit/UIApp init is complete
        // - loadQueuedTabs accesses the DB and shows up as a hot path in profiling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // We could load these here, but then we have to futz with the tab counter
            // and making NSURLRequests.
            self.browserViewController.loadQueuedTabs()
            application.applicationIconBadgeNumber = 0
        }
        
        // Cleanup can be a heavy operation, take it out of the startup path. Instead check after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.profile.cleanupHistoryIfNeeded()
            self.browserViewController.ratingPromptManager.updateData()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Pause file downloads.
        // TODO: iOS 13 needs to iterate all the BVCs.
        browserViewController.downloadQueue.pauseAll()
    }
    
    /// When a user presses and holds the app icon from the Home Screen, we present quick actions / shortcut items (see QuickActions).
    ///
    /// This method can handle a quick action from both app launch and when the app becomes active. However, the system calls launch methods first if the app `launches`
    /// and gives you a chance to handle the shortcut there. If it's not handled there, this method is called in the activation process with the shortcut item.
    ///
    /// Quick actions / shortcut items are handled here as long as our two launch methods return `true`. If either of them return `false`, this method
    /// won't be called to handle shortcut items.
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = QuickActions.sharedInstance.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)

        completionHandler(handledShortCutItem)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == SiriShortcuts.activityType.openURL.rawValue {
            browserViewController.openBlankNewTab(focusLocationField: false)
            return true
        }

        // If the `NSUserActivity` has a `webpageURL`, it is either a deep link or an old history item
        // reached via a "Spotlight" search before we began indexing visited pages via CoreSpotlight.
        if let url = userActivity.webpageURL {
            let query = url.getQuery()

            // Check for fxa sign-in code and launch the login screen directly
            if query["signin"] != nil {
                // bvc.launchFxAFromDeeplinkURL(url) // Was using Adjust. Consider hooking up again when replacement system in-place.
                return true
            }

            // Per Adjust documentation, https://docs.adjust.com/en/universal-links/#running-campaigns-through-universal-links,
            // it is recommended that links contain the `deep_link` query parameter. This link will also
            // be url encoded.
            if let deepLink = query["deep_link"]?.removingPercentEncoding, let url = URL(string: deepLink) {
                browserViewController.switchToTabForURLOrOpen(url)
                return true
            }

            browserViewController.switchToTabForURLOrOpen(url)
            return true
        }

        // Otherwise, check if the `NSUserActivity` is a CoreSpotlight item and switch to its tab or
        // open a new one.
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
                let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: urlString) {
                browserViewController.switchToTabForURLOrOpen(url)
                return true
            }
        }

        return false
    }
    
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        guard let routerpath = NavigationPath(url: url) else { return false }

        DispatchQueue.main.async {
            NavigationPath.handle(nav: routerpath, with: self.browserViewController)
        }
        return true
    }
}

extension RootViewControllerAppDelegate: WelcomeDelegate {
    
    func welcomeDidFinish(_ welcome: Welcome) {
        coordinator?.navigationController.setViewControllers([browserViewController], animated: true)
    }
}
