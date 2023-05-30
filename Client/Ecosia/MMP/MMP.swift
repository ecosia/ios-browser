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
                
                /// We are hardcoding `iOS` as per the platform parameter
                /// as `Singular` MMP doesn't currently support others like `iPadOS`
                /// We don't want to modify the `DeviceInfo.platform` as other services may need the correct one.
                let appDeviceInfo = AppDeviceInfo(platform: "iOS",
                                                  bundleId: AppInfo.bundleIdentifier,
                                                  osVersion: DeviceInfo.osVersionNumber,
                                                  deviceManufacturer: DeviceInfo.manufacturer,
                                                  deviceModel: DeviceInfo.deviceModelName,
                                                  locale: DeviceInfo.currentLocale,
                                                  deviceBuildVersion: DeviceInfo.osBuildNumber,
                                                  appVersion: AppInfo.appVersion,
                                                  installReceipt: AppInfo.installReceipt)
                
                let mmpProvider: MMPProvider = Singular(includeSKAN: true)
                try await mmpProvider.sendSessionInfo(appDeviceInfo: appDeviceInfo)
            } catch {
                debugPrint(error)
            }
        }
    }
}
