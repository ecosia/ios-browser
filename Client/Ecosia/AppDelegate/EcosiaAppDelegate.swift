// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: MainCoordinator?
    var orientationLock = UIInterfaceOrientationMask.all
    var tabManager: TabManager!
    var browserViewController: BrowserViewController!
    lazy var profile: Profile = BrowserProfile(localName: "profile")
    lazy var appDelegate = AppDelegateFactory.makeWith(window: self.window,
                                                       orientationLock: self.orientationLock,
                                                       tabManager: TabManager.makeWithProfile(profile: profile),
                                                       profile: self.profile,
                                                       coordinator: self.coordinator)

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        appDelegate.application?(application, willFinishLaunchingWithOptions: launchOptions) ?? true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        appDelegate.application?(application, didFinishLaunchingWithOptions: launchOptions) ?? true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        appDelegate.applicationDidBecomeActive?(application)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        appDelegate.applicationWillResignActive?(application)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        appDelegate.applicationDidEnterBackground?(application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        appDelegate.applicationWillEnterForeground?(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        appDelegate.applicationWillTerminate?(application)
    }
    
    // Orientation lock for views that use new modal presenter
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        appDelegate.application?(application, supportedInterfaceOrientationsFor: window) ?? self.orientationLock
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        appDelegate.application?(application, performActionFor: shortcutItem, completionHandler: completionHandler)
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        appDelegate.application?(application, continue: userActivity, restorationHandler: restorationHandler) ?? false
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        appDelegate.application?(application, open: url, options: options) ?? false
    }
}
