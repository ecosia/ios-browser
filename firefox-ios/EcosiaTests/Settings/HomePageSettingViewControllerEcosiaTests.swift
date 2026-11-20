// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
@testable import Ecosia

import Common
import Shared
import XCTest

/// Settings > Homepage and the NTP's "Customize" button open this screen, so it holds
/// every homepage option Ecosia offers.
@MainActor
final class HomePageSettingViewControllerEcosiaTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile.unmanaged()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        try await super.tearDown()
    }

    func testGenerateSettings_hasNoStoriesToggle() {
        let settings = allSettings(in: createSubject())

        let storiesToggle = settings.first {
            ($0 as? BoolSetting)?.prefKey == PrefsKeys.UserFeatureFlagPrefs.ASPocketStories
        }
        XCTAssertNil(storiesToggle, "Ecosia's NTP never shows stories, so the toggle must not appear")
    }

    func testGenerateSettings_offersShortcutsAndClimateImpact() {
        let settings = allSettings(in: createSubject())

        XCTAssertTrue(settings.contains { $0 is HomePageSettingViewController.TopSitesSettings })
        XCTAssertTrue(settings.contains { $0 is HomePageSettingViewController.ClimateImpactSettings })
    }

    func testGenerateSettings_offersTheOpeningScreenChoice() {
        let settings = allSettings(in: createSubject())
        typealias A11y = AccessibilityIdentifiers.Settings.Homepage.StartAtHome

        let identifiers = settings.compactMap { $0.accessibilityIdentifier }
        XCTAssertTrue(identifiers.contains(A11y.afterFourHours))
        XCTAssertTrue(identifiers.contains(A11y.always))
    }

    // MARK: - Helpers

    private func createSubject() -> HomePageSettingViewController {
        let subject = HomePageSettingViewController(prefs: profile.prefs,
                                                    settingsDelegate: nil,
                                                    tabManager: MockTabManager())
        subject.profile = profile
        return subject
    }

    private func allSettings(in subject: HomePageSettingViewController) -> [Setting] {
        subject.generateSettings().flatMap { $0.children }
    }
}
