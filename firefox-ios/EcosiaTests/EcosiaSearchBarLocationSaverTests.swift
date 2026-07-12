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
    func test_saveSearchBarLocation_withExistingUser_andNoPosition_migratesToBottom() async throws {
        // The migration's observable contract (MOB-4304) is that an existing user ends
        // up on the bottom search bar and the one-shot migration is recorded. Whether
        // "bottom" is reached by an explicit prefs write or by relying on the default
        // is an implementation detail that legitimately depends on the .bottomSearchBar
        // build-only Nimbus default (off in test builds), so this asserts the behaviour,
        // not the absence of a write. Tracked in MOB-4384.
        let subject = createSubject()
        User.shared.firstTime = false

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)

        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.bottom.rawValue)
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
