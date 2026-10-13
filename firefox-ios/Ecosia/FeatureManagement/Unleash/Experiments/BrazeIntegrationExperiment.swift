// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct BrazeIntegrationExperiment {

    private init() {}

    static var isEnabled: Bool {
        guard Unleash.isEnabled(.brazeCoreMarkets) else { return false }
        // Users in the holdout group are withheld from Braze.
        guard Unleash.getVariant(.brazeCoreMarkets).name != "st_braze_features_holdout" else { return false }

        return true
    }
}
