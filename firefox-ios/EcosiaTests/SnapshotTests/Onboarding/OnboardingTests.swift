// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
@testable import Client
@testable import Ecosia

final class OnboardingTests: SnapshotBaseTests {

    func testWelcomeScreen() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            WelcomeViewController(delegate: MockWelcomeDelegate(), windowUUID: .snapshotTestDefaultUUID)
        }, wait: 1.0)
    }
}
