// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Core

struct FeatureManagement {
    
    private init() {}
    
    static func fetchConfiguration() {
        Task {
            do {
                Self.addRefreshingRules()
                try await _ = Unleash.start(env: .current, appVersion: AppInfo.ecosiaAppVersion)
            } catch {
                debugPrint(error)
            }
        }
    }
    
    private static func addRefreshingRules() {
        UnleashRefreshConfigurator()
                    .withAppUpdateCheckRule(appVersion: AppInfo.ecosiaAppVersion)
                    .withDeviceRegionUpdateCheckRule()
                    .withTwentyFourHoursCacheExpirationRule()
    }
}
