// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
@testable import Client
@testable import Ecosia

final class OnboardingTests: SnapshotBaseTests {

    // WelcomeView runs a multi-phase intro after the background video becomes ready
    // (initial delay + three animation phases ≈ 2.2s). Allow extra time for AVFoundation
    // to report the player as ready in the simulator-hosted test environment.
    private let welcomeAnimationSettleDuration: TimeInterval = 4.5

    func testWelcomeScreen() {
        SnapshotTestHelper.assertSnapshot(
            initializingWith: makeWelcomeViewController,
            wait: welcomeAnimationSettleDuration,
            // Background video frames differ between simulator runs (often ~65–70% pixel match).
            precision: 0.65
        )
    }

    private func makeWelcomeViewController() -> WelcomeViewController {
        WelcomeViewController(
            delegate: MockWelcomeDelegate(),
            windowUUID: .snapshotTestDefaultUUID
        )
    }
}
