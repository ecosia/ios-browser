// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client
@testable import Ecosia

@MainActor
class EcosiaHomeViewModelTests: XCTestCase {

    var profile: MockProfile!
    var tabManager: MockTabManager!
    var referrals: Referrals!
    var theme: Theme!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        tabManager = MockTabManager()
        referrals = Referrals()
        theme = LightTheme()

        User.shared = User()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        // Clean user defaults to avoid having flaky test changing the section count
        // because message card reach max amount of impressions
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    // MARK: Number of sections

    func testNumberOfSection_withoutUpdatingData_hasExpectedSections() {
        let adapter = EcosiaHomepageAdapter(
            profile: profile,
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            referrals: referrals,
            theme: theme,
            auth: EcosiaAuth(browserViewController: BrowserViewController(profile: profile, tabManager: tabManager))
        )
        User.shared.showClimateImpact = true
        User.shared.showNews = false

        let sections = adapter.getEcosiaSections()
        
        // Should have: logo, library, impact, customization (4 sections when header is not shown)
        XCTAssertGreaterThanOrEqual(sections.count, 4)
        XCTAssertTrue(sections.contains(.ecosiaLogo))
        XCTAssertTrue(sections.contains(.ecosiaLibrary))
        XCTAssertTrue(sections.contains(.ecosiaImpact))
        XCTAssertTrue(sections.contains(.ecosiaNTPCustomization))
    }
}
