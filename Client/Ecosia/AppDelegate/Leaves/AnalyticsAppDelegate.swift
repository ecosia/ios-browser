// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Core

final class AnalyticsAppDelegate: AppDelegateLeaf {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        Analytics.shared.activity(.launch)
        
        if User.shared.firstTime {
            Analytics.shared.install()
        }
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Analytics.shared.activity(.resume)
    }
}
