// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum BrazeCoreMarketVariant: String {
    case holdout
    case treatment
    case control
    case disabled
}

struct BrazeIntegration {

    private init() {}

    private static var state: BrazeCoreMarketVariant {
        return BrazeCoreMarketVariant(rawValue: Unleash.getVariant(.brazeCoreMarkets).name) ?? .disabled
    }

    static var isEnabled: Bool {
        return [BrazeCoreMarketVariant.holdout, BrazeCoreMarketVariant.treatment].contains(state)
    }
}
