// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct OnboardingProductTourExperiment {

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.onboardingProductTour) && !isControl
    }

    private static var variant: Unleash.Variant {
        Unleash.getVariant(.onboardingProductTour)
    }

    private static let controlVariantName: String = "control"
    public static var isControl: Bool {
        variant.name == controlVariantName
    }
}
