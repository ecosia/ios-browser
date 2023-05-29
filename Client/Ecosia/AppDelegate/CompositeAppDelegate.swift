// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

typealias AppDelegateType = UIResponder & UIApplicationDelegate
typealias AppDelegateLeaf = AppDelegateType

final class CompositeAppDelegate: AppDelegateType {
    
    private let appDelegates: [AppDelegateType]

    init(appDelegates: [AppDelegateType]) {
        self.appDelegates = appDelegates
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        appDelegates.forEach { _ = $0.application?(application, willFinishLaunchingWithOptions: launchOptions) }
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        appDelegates.forEach { _ = $0.application?(application, didFinishLaunchingWithOptions: launchOptions) }
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        appDelegates.forEach { _ = $0.applicationDidBecomeActive?(application) }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        appDelegates.forEach { _ = $0.applicationWillResignActive?(application) }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        appDelegates.forEach { _ = $0.applicationDidEnterBackground?(application) }
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        appDelegates.forEach { _ = $0.application?(application, performActionFor: shortcutItem, completionHandler: completionHandler) }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        appDelegates.forEach { _ = $0.applicationWillEnterForeground?(application) }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        appDelegates.forEach { _ = $0.application?(application, continue: userActivity, restorationHandler: restorationHandler) }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        appDelegates.forEach { _ = $0.application?(app, open: url, options: options) }
        return true
    }
}
