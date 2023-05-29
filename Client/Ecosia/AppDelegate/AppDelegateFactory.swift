// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum AppDelegateFactory {
        
    static func makeWith(window: UIWindow?,
                         orientationLock: UIInterfaceOrientationMask,
                         tabManager: TabManager,
                         profile: Profile,
                         coordinator: MainCoordinator?) -> AppDelegateType {
        let appDelegateLeaves: [AppDelegateLeaf] = [
            EnvironmentAppDelegate(),
            AnalyticsAppDelegate(),
            AppLaunchUtilAppDelegate(profile: profile),
            WebServerUtilAppDelegate(profile: profile),
            TabManagerAppDelegate(profile: profile, tabManager: tabManager),
            ProfileBehaviorAppDelegate(profile: profile),
            RootViewControllerAppDelegate(profile: profile,
                                          window: window,
                                          tabManager: tabManager,
                                          coordinator: coordinator),
            ThemeUpdatesAppDelegate(window: window),
            OrientationLockAppDelegate(orientationLock: orientationLock),
            TopSiteWidgetAppDelegate(profile: profile),
            ShutdownWebServerAppDelegate(profile: profile),
            TelemetryAppDelegate(profile: profile, tabManager: tabManager),
            ThirdPartyServicesAppDelegate()
        ]
        return CompositeAppDelegate(appDelegates: appDelegateLeaves)
    }
}
