// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

extension NTPTooltip {
    enum Highlight {
        case collectiveImpactIntro

        var text: String {
            switch self {
            case .collectiveImpactIntro:
                return .localized(.seeTheCollectiveImpact)
            }
        }
    }

    class func highlight(for user: User = User.shared) -> NTPTooltip.Highlight? {
        guard !user.firstTime else { return nil }

        if user.shouldShowImpactIntro {
            return .collectiveImpactIntro
        }

        return nil
    }
}
