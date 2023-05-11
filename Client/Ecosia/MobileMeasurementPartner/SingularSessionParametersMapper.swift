// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum SingularSessionParametersMapper {
    
    private struct SingularSessionInfo: Encodable {
        let identifier: String
        let platform: String
        let bundleId: String
        let osVersion: String
        let deviceManufacturer: String
        let deviceModel: String
        let locale: String
        let deviceBuildVersion: String?
        let appVersion: String
        let installReceipt: String?
        let installTime: String
        let updateTime: String
        
        enum CodingKeys: String, CodingKey {
            case identifier = "sing"
            case platform = "p"
            case bundleId = "i"
            case osVersion = "ve"
            case deviceManufacturer = "ma"
            case deviceModel = "mo"
            case locale = "lc"
            case deviceBuildVersion = "bd"
            case appVersion = "app_v"
            case installReceipt = "install_receipt"
            case installTime = "install_time"
            case updateTime = "update_time"
        }
    }
    
    static func map(_ info: AppDeviceInfo) -> [String: String]? {
        
        var deviceBuildVersion: String?
        if let deviceBuildVersionString = info.deviceBuildVersion {
            deviceBuildVersion = #"Build\\#(deviceBuildVersionString)"#
        }
        
        let singularSessionInfo = SingularSessionInfo(identifier: info.identifier,
                                                      platform: info.platform,
                                                      bundleId: info.bundleId,
                                                      osVersion: info.osVersion,
                                                      deviceManufacturer: info.deviceManufacturer,
                                                      deviceModel: info.deviceModel,
                                                      locale: info.locale,
                                                      deviceBuildVersion: deviceBuildVersion,
                                                      appVersion: info.appVersion,
                                                      installReceipt: info.installReceipt,
                                                      installTime: "\(Int(info.installTime.rounded()))",
                                                      updateTime: "\(Int(info.updateTime.rounded()))")
        
        return try? JSONSerialization.jsonObject(with: JSONEncoder().encode(singularSessionInfo)) as? [String: String]
    }
}
