// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum BrazeCoreMarketState: String {
    case disabled = "disabled"
    case holdout = "holdout"
    case treatment = "treatment"
    case control = "control"
}

struct BrazeIntegration {

    private init() {}

    static var state: BrazeCoreMarketState {
        guard let state = BrazeCoreMarketState(rawValue: Unleash.getVariant(.brazeCoreMarkets).name) else {
            return .disabled
        }
        return state
    }
    
    static var isEnabled: Bool {
        return [BrazeCoreMarketState.holdout, BrazeCoreMarketState.treatment].contains(state)
    }
}
