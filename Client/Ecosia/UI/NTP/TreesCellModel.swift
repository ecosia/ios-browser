/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TreesCellModel {
    let title: String
    let subtitle: String

    let highlight: String?
    var spotlight: Spotlight?

    struct Spotlight {
        let headline: String
        let description: String
    }
}

extension TreesCellModel {
    static var newUser: TreesCellModel {
        return .init(title: .localizedPlural(.treesPlural, num: 0),
                     subtitle: .localized(.startPlanting),
                     highlight: nil,
                     spotlight: nil)
    }
}
