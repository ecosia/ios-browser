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

final class HomepageViewControllerTests: XCTestCase {
    
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
    
    func testNTPShowingImpactIntro() {
        User.shared.showImpactIntro()
        snapshotNTP(impactIntroShown: true)
    }
    
    func testNTPImpactIntroHidden() {
        User.shared.hideImpactIntro()
        snapshotNTP(impactIntroShown: false)
    }
}

extension HomepageViewControllerTests {
    fileprivate func snapshotNTP(impactIntroShown: Bool) {
        let tabManager = TabManagerImplementation(profile: profile, imageStore: nil)
        let urlBar = URLBarView(profile: profile)
        let overlayManager = MockOverlayModeManager()
        overlayManager.setURLBar(urlBarView: urlBar)
        
        let homePageViewController = HomepageViewController(profile: profile,
                                                            toastContainer: UIView(),
                                                            tabManager: tabManager,
                                                            overlayManager: overlayManager,
                                                            referrals: .init(),
                                                            delegate: nil)
        
        // Providing precision = 0.95 to accommodate the trees and the money counter updates which will result into different numbers
        // for different snapshots.
        let snapshotTitle = impactIntroShown ? "NTP_with_impact_intro" : "NTP_without_impact_intro"
        SnapshotTestHelper.assertSnapshot(of: homePageViewController,
                                          wait: 4.0,
                                          precision: 0.95,
                                          testName: snapshotTitle)
    }
}
