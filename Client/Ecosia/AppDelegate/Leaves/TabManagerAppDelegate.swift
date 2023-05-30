// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

final class TabManagerAppDelegate: AppDelegateLeaf {
    
    private var tabManager: TabManager?
    private var profile: Profile
    
    required init(profile: Profile, tabManager: TabManager?) {
        self.profile = profile
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Allow deinitializers to close our database connections.
        tabManager = nil
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        tabManager?.preserveTabs()
    }
}

extension TabManager {
    
    class func makeWithProfile(profile: Profile) -> TabManager {
        let imageStore = DiskImageStore(files: profile.files, namespace: "TabManagerScreenshots", quality: UIConstants.ScreenshotQuality)
        return TabManager(profile: profile, imageStore: imageStore)
    }
}
