// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct OnboardingRemoveExperiment {
    
    private init() {}
    
    private enum Variant: String {
        case control
        case test
    }
    
    private static var variant: Variant {
        Variant(rawValue: Unleash.getVariant(.onboardingRemove).name) ?? .control
    }
    
    private static var isEnabled: Bool {
        Unleash.isEnabled(.onboardingRemove)
    }
    
    static var shouldRemoveOnboarding: Bool {
        isEnabled && variant != .control
    }
}
