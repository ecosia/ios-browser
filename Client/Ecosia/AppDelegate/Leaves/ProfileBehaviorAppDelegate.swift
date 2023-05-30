// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class ProfileBehaviorAppDelegate: AppDelegateLeaf {
    
    private var profile: Profile
    
    required init(profile: Profile) {
        self.profile = profile
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        profile._reopen()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // We have only five seconds here, so let's hope this doesn't take too long.
        profile._shutdown(force: true)
    }
    
}
