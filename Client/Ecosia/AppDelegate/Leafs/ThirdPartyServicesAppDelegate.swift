// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SDWebImage

final class ThirdPartyServicesAppDelegate: AppDelegateLeaf {
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Create fx favicon cache directory
        FaviconFetcher.createWebImageCacheDirectory()

        // Start Ecosia's MMP and Feature Management tools
        MMP.sendSession()
        FeatureManagement.fetchConfiguration()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // send glean telemetry and clear cache
        // we do this to remove any disk cache
        // that the app might have built over the
        // time which is taking up un-necessary space
        SDImageCache.shared.clearDiskCache { _ in }
    }
}
