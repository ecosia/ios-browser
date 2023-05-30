// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class WebServerUtilAppDelegate: AppDelegateLeaf {
    
    private var webServerUtil: WebServerUtil?
    private var profile: Profile
    
    required init(profile: Profile) {
        self.profile = profile
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        webServerUtil = WebServerUtil(profile: profile)
        webServerUtil?.setUpWebServer()
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        webServerUtil?.setUpWebServer()
    }
}
