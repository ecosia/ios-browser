// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client
@testable import Core

class EcosiaHomeViewModelTests: XCTestCase {

    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        // Clean user defaults to avoid having flaky test changing the section count
        // because message card reach max amount of impressions
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    // MARK: Number of sections

    func testNumberOfSection_withoutUpdatingData_has3Sections() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false, 
                                          tabManager: <#TabManager#>,
                                          referrals: .init(),
                                          theme: EcosiaLightTheme())
        // Ecosia: Update shown sections
        XCTAssertEqual(viewModel.shownSections.count, 6)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.logoHeader)
        // Bookmark Nudge depends on User.showsBookmarksNTPNudgeCard()
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.bookmarkNudge)
        XCTAssertEqual(viewModel.shownSections[2], HomepageSectionType.libraryShortcuts)
        XCTAssertEqual(viewModel.shownSections[3], HomepageSectionType.impact)
        // News is not shown without items
        // XCTAssertEqual(viewModel.shownSections[4], HomepageSectionType.news)
        XCTAssertEqual(viewModel.shownSections[4], HomepageSectionType.aboutEcosia)
        XCTAssertEqual(viewModel.shownSections[5], HomepageSectionType.ntpCustomization)
    }
}
