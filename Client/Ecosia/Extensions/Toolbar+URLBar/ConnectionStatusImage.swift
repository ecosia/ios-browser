// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ConnectionStatusImage {
    
    static let connectionSecureImage = UIImage.templateImageNamed("secureLock")?.tinted(withColor: .theme.ecosia.secondaryIcon)
    static let connectionUnsecureImage = UIImage.templateImageNamed("problem")?.tinted(withColor: .theme.ecosia.warning)
}
