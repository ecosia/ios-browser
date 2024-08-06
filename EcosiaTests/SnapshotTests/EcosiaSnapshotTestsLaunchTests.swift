// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
@testable import Client

final class EcosiaSnapshotTestsLaunchTests: XCTestCase {
    
    func testOnbaordingWelcomeScreen() {
        SnapshotTestHelper.assertSnapshot(of: Welcome(delegate: MockWelcomeDelegate()))
    }
    
    func testOnboardingStepsScreens() {
        let welcomeTourViewController = WelcomeTour(delegate: MockWelcomeTourDelegate())
        // Number of steps in the WelcomeTour
        let numberOfSteps = 4
        // Iterate through steps and take snapshots, skipping the first one
        for step in 1...numberOfSteps {
            if step != 1 {
                welcomeTourViewController.forward() // Move to the next step
            }
            SnapshotTestHelper.assertSnapshot(of: welcomeTourViewController, wait: 1.0, testName: "testWelcomeTourViewController_step_\(step)")
        }
    }    
}
