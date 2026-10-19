// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum BrazeCoreMarketVariant: String {
    case holdout = "st_braze_features_holdout"
    case treatment = "st_braze_features_treatment"
    case control
    case disabled
}

struct BrazeIntegration {

    private init() {}

    private static var state: BrazeCoreMarketVariant {
        return BrazeCoreMarketVariant(rawValue: Unleash.getVariant(.brazeCoreMarkets).name) ?? .disabled
    }

    static var isEnabled: Bool {
        guard Unleash.isEnabled(.brazeCoreMarkets) else { return false }

        return [BrazeCoreMarketVariant.control, BrazeCoreMarketVariant.treatment].contains(state)
    }

    static var isReportedToAnalytics: Bool {
        return [BrazeCoreMarketVariant.treatment, BrazeCoreMarketVariant.holdout].contains(state)
    }
}
