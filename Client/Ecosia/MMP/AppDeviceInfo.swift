// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct AppDeviceInfo {
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
    let installTime: TimeInterval
    let updateTime: TimeInterval
}
