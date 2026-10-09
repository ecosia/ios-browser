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
        warmUpVideoPlayback()
        SnapshotTestHelper.assertSnapshot(
            initializingWith: makeWelcomeViewController,
            wait: welcomeAnimationSettleDuration,
            // Background video frames differ between simulator runs (often ~65–70% pixel match).
            precision: 0.65
        )
    }

    /// The first video load in a freshly launched test host can take several seconds longer than later
    /// ones, which would capture the first snapshot mid-animation. Presenting the screen once beforehand
    /// keeps every snapshot on the same warm path.
    private func warmUpVideoPlayback() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = makeWelcomeViewController()
        window.makeKeyAndVisible()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: welcomeAnimationSettleDuration))
        window.isHidden = true
        window.rootViewController = nil
    }

    private func makeWelcomeViewController() -> WelcomeViewController {
        WelcomeViewController(
            delegate: MockWelcomeDelegate(),
            windowUUID: .snapshotTestDefaultUUID
        )
    }
}
