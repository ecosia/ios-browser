// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import Common
import Shared
import Core
import MozillaAppServices
@testable import Client

class HomepageViewControllerTests: XCTestCase {
    
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
    }

    func testHomepageViewController() {
        User.shared.firstTime = false
        let tabManager = TabManagerImplementation(profile: profile, imageStore: nil)
        let urlBar = URLBarView(profile: profile)
        let overlayManager = MockOverlayModeManager()
        overlayManager.setURLBar(urlBarView: urlBar)

        let homeViewController = HomepageViewController(profile: profile,
                                                               toastContainer: UIView(),
                                                               tabManager: tabManager,
                                                               overlayManager: overlayManager,
                                                               referrals: .init(),
                                                               delegate: nil)
        // Providing precision = 0.95 to accommodate the trees and the money counter updates which will result into different numbers
        // for different snapshots.
        SnapshotTestHelper.assertSnapshot(of: homeViewController, wait: 3.0, precision: 0.95, testName: "HomepageViewController_Initial")
    }
}
