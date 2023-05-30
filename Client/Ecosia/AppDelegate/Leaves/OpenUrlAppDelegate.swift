// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

final class OpenUrlAppDelegate: AppDelegateLeaf {
    
    private var profile: Profile
    private var browserViewController: BrowserViewController?

    required init(profile: Profile, browserViewController: BrowserViewController?) {
        self.profile = profile
        self.browserViewController = browserViewController
    }
    
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        guard let browserViewController else { return false }
        guard let routerpath = NavigationPath(url: url) else { return false }

        if let _ = profile.prefs.boolForKey(PrefsKeys.AppExtensionTelemetryOpenUrl) {
            profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryOpenUrl)
            var object = TelemetryWrapper.EventObject.url
            if case .text = routerpath {
                object = .searchText
            }
            TelemetryWrapper.recordEvent(category: .appExtensionAction, method: .applicationOpenUrl, object: object)
        }

        DispatchQueue.main.async {
            NavigationPath.handle(nav: routerpath, with: browserViewController)
        }
        
        return true
    }

}
