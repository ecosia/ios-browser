// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import Ecosia
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

class EcosiaSearchBarLocationSaverTests: XCTestCase {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        await DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        User.shared.firstTime = true
        UserDefaults.standard.removeObject(forKey: EcosiaSearchBarLocationSaver.didMigrateToBottomToolbarKey)
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        User.shared.firstTime = true
        UserDefaults.standard.removeObject(forKey: EcosiaSearchBarLocationSaver.didMigrateToBottomToolbarKey)
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func test_saveSearchBarLocation_withFirstTimeUser_setsPositionToBottom() async throws {
        let subject = createSubject()
        User.shared.firstTime = true

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)

        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.bottom.rawValue)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: EcosiaSearchBarLocationSaver.didMigrateToBottomToolbarKey))
    }

    @MainActor
    func test_saveSearchBarLocation_withExistingUser_andNoPosition_marksMigratedWithoutOverride() async throws {
        // No stored preference means the default (bottom) already applies, so the
        // migration should only record that it ran without writing anything.
        let subject = createSubject()
        User.shared.firstTime = false

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)

        XCTAssertNil(profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: EcosiaSearchBarLocationSaver.didMigrateToBottomToolbarKey))
    }

    @MainActor
    func test_saveSearchBarLocation_withExistingUser_onTop_migratesToBottomOnce() async throws {
        let subject = createSubject()
        User.shared.firstTime = false
        profile.prefs.setString(SearchBarPosition.top.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)

        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.bottom.rawValue)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: EcosiaSearchBarLocationSaver.didMigrateToBottomToolbarKey))
    }

    @MainActor
    func test_saveSearchBarLocation_afterMigration_doesNotOverrideTopChoice() async throws {
        let subject = createSubject()
        User.shared.firstTime = false
        UserDefaults.standard.set(true, forKey: EcosiaSearchBarLocationSaver.didMigrateToBottomToolbarKey)
        profile.prefs.setString(SearchBarPosition.top.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)

        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.top.rawValue)
    }

    @MainActor
    func test_saveSearchBarLocation_withExistingUser_onBottom_marksMigratedWithoutOverride() async throws {
        let subject = createSubject()
        User.shared.firstTime = false
        profile.prefs.setString(SearchBarPosition.bottom.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)

        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.bottom.rawValue)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: EcosiaSearchBarLocationSaver.didMigrateToBottomToolbarKey))
    }

    @MainActor
    func test_saveSearchBarLocation_oniPad_withFirstTimeUser_setsPositionToBottom() async throws {
        let subject = createSubject()
        User.shared.firstTime = true

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .pad)

        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.bottom.rawValue)
    }

    private func createSubject() -> EcosiaSearchBarLocationSaver {
        return EcosiaSearchBarLocationSaver()
    }
}
// swiftlint:enable implicitly_unwrapped_optional
