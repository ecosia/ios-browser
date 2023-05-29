// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class AppLaunchUtilAppDelegate: AppDelegateLeaf {
    
    private var appLaunchUtil: AppLaunchUtil?
    private var profile: Profile
    
    required init(profile: Profile) {
        self.profile = profile
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        appLaunchUtil = AppLaunchUtil(profile: profile)
        appLaunchUtil?.setUpPreLaunchDependencies()
        
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        appLaunchUtil?.setUpPostLaunchDependencies()
        return true
    }
}
