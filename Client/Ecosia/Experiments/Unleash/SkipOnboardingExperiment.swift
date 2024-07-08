// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

struct SkipOnboardingExperiment {
    
    private init() {}
    
    private static var isEnabled: Bool {
        Unleash.isEnabled(.hideOnboardingSkip)
    }
    
    static var shouldHideSkipButton: Bool {
        Self.isEnabled && Unleash.getVariant(.hideOnboardingSkip).name == "test"
    }
}
