// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class ShutdownWebServerAppDelegate: AppDelegateLeaf {
    
    private var shutdownWebServer: DispatchSourceTimer?
    private var profile: Profile
    
    required init(profile: Profile) {
        self.profile = profile
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        shutdownWebServer?.cancel()
        shutdownWebServer = nil
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        let singleShotTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        // 2 seconds is ample for a localhost request to be completed by GCDWebServer. <500ms is expected on newer devices.
        singleShotTimer.schedule(deadline: .now() + 2.0, repeating: .never)
        singleShotTimer.setEventHandler {
            WebServer.sharedInstance.server.stop()
            self.shutdownWebServer = nil
        }
        singleShotTimer.resume()
        shutdownWebServer = singleShotTimer
    }
}
