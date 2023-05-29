// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class TopSiteWidgetAppDelegate: AppDelegateLeaf {
    
    private var profile: Profile
    
    required init(profile: Profile) {
        self.profile = profile
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        updateTopSitesWidget()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        updateTopSitesWidget()
        UserDefaults.standard.setValue(Date(), forKey: "LastActiveTimestamp")
    }
}

extension TopSiteWidgetAppDelegate {
    
    private func updateTopSitesWidget() {
        // Since we only need the topSites data in the archiver, let's write it
        // only if iOS 14 is available.
        if #available(iOS 14.0, *) {
            let topSitesProvider = TopSitesProviderImplementation(browserHistoryFetcher: profile.history,
                                                                  prefs: profile.prefs)

            TopSitesWidgetManager(topSitesProvider: topSitesProvider).writeWidgetKitTopSites()
        }
    }
}
