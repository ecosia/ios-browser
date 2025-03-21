// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public enum EcosiaIcon: String, CaseIterable, Identifiable {
    case primary    = "AppIcon"
    case rainbow    = "AppIcon-Rainbow"
    case inverted   = "AppIcon-Inverted"
    case gradient   = "AppIcon-Gradient"

    public var id: String { self.rawValue }
}

public struct AppIconManager {

    public static func updateAppIcon(to icon: EcosiaIcon?, completion: ((Error?) -> Void)? = nil) {
        guard UIApplication.shared.supportsAlternateIcons else {
            completion?(NSError(domain: "Alternate icons not supported", code: -1, userInfo: nil))
            return
        }

        UIApplication.shared.setAlternateIconName(icon?.rawValue) { error in
            completion?(error)
        }
    }
}
