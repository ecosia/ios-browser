// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct AIChatExperiment {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.aiChat)
    }

    private static var variant: Unleash.Variant {
        Unleash.getVariant(.aiChat)
    }
}
