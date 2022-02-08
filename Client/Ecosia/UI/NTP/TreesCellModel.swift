/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TreesCellModel {
    enum Appearance {
        case ntp, impact
    }

    let title: String
    let subtitle: String
    let appearance: Appearance

    let highlight: String?
    var spotlight: Spotlight?

    struct Spotlight {
        let headline: String
        let description: String
    }
}
