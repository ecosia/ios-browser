// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit

enum DeviceType: String, CaseIterable {
    case iPhone8_Portrait
    case iPhone12Pro_Portrait
    case iPhone13ProMax_Portrait
    case iPadPro_Portrait
    
    var config: ViewImageConfig {
        switch self {
        case .iPhone8_Portrait:
            return ViewImageConfig.iPhone8(.portrait)
        case .iPhone12Pro_Portrait:
            return ViewImageConfig.iPhone12Pro(.portrait)
        case .iPhone13ProMax_Portrait:
            return ViewImageConfig.iPhone13ProMax(.portrait)
        case .iPadPro_Portrait:
            return ViewImageConfig.iPadPro12_9(.portrait)
        }
    }
}
