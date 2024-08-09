// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
@testable import Client

final class OnboardingTests: SnapshotBaseTests {
    
    func testWelcomeScreen() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            Welcome(delegate: MockWelcomeDelegate())
        }, locales: LocalizationOverrideTestingBundle.supportedLocales, wait: 1.0)
    }
    
    func testWelcomeStepsScreens() {
        // Number of steps in the WelcomeTour
        let numberOfSteps = 4
        // Iterate through steps and take snapshots, skipping the first one
        for step in 1...numberOfSteps {
            let startingStep = WelcomeTour.Step.all[step-1]
            // Precision at .95 to accommodate a snapshot looking slightly different due to the different data output
            // from the statistics json
            let precision = startingStep == .transparent ? 0.95 : 1.0
            SnapshotTestHelper.assertSnapshot(initializingWith: {
                WelcomeTour(delegate: MockWelcomeTourDelegate(), startingStep: startingStep)
            }, devices: [.iPhone12Pro_Portrait, .iPadPro_Portrait], 
                                              locales: LocalizationOverrideTestingBundle.supportedLocales,
                                              wait: 2.0,
                                              precision: precision,
                                              testName: "testWelcomeScreen_step_\(step)")
        }
    }
}
