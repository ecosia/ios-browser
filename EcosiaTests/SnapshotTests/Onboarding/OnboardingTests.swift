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
        }, wait: 2.0)
    }
    
    func testWelcomeStepsScreens() {
        // Number of steps in the WelcomeTour
        let numberOfSteps = 4
        // Iterate through steps and take snapshots, skipping the first one
        for step in 1...numberOfSteps {
            let startingStep = WelcomeTour.Step.all[step-1]
            // Using closure to ensure that the snapshot captures the current state of the view controller after navigation actions
            SnapshotTestHelper.assertSnapshot(initializingWith: {
                WelcomeTour(delegate: MockWelcomeTourDelegate(), startingStep: startingStep)
            }, devices: [.iPhone12Pro_Portrait, .iPadPro_Portrait], wait: 1.0, precision: 0.95, testName: "testWelcomeScreen_step_\(step)")
        }
    }
}
