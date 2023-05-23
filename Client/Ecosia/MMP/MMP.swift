// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core
import Shared

struct MMP {
    
    private init() {}
        
    static func sendSession() {
        Task {
            do {
                let appDeviceInfo = AppDeviceInfo(platform: DeviceInfo.platform,
                                                  bundleId: AppInfo.bundleIdentifier,
                                                  osVersion: DeviceInfo.osVersionNumber,
                                                  deviceManufacturer: DeviceInfo.manufacturer,
                                                  deviceModel: DeviceInfo.deviceModelName,
                                                  locale: DeviceInfo.currentLocale,
                                                  deviceBuildVersion: DeviceInfo.osBuildNumber,
                                                  appVersion: AppInfo.appVersion,
                                                  installReceipt: AppInfo.installReceipt,
                                                  installTime: NSDate().timeIntervalSince1970,
                                                  updateTime: NSDate().timeIntervalSince1970)
                try await Singular.sendSessionInfo(appDeviceInfo: appDeviceInfo, env: Environment.current)
            } catch {
                debugPrint(error)
            }
        }
    }
}
