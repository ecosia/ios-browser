// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import Ecosia
import XCTest

class EcosiaSearchBarLocationSaverTests: XCTestCase {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        await DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        User.shared.firstTime = true
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        User.shared.firstTime = true
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func test_saveSearchBarLocation_withFirstTimeUser_setsPositionToBottom() async throws {
        let subject = createSubject()
        User.shared.firstTime = true

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, SearchBarPosition.bottom.rawValue)
    }

    @MainActor
    func test_saveSearchBarLocation_withExistingUser_doesNotSetPosition() async throws {
        let subject = createSubject()
        User.shared.firstTime = false

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertNil(searchBarPosition)
    }

    @MainActor
    func test_saveSearchBarLocation_withExistingPosition_keepsPosition() async throws {
        let subject = createSubject()
        User.shared.firstTime = true
        profile.prefs.setString(SearchBarPosition.top.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, SearchBarPosition.top.rawValue)
    }

    @MainActor
    func test_saveSearchBarLocation_oniPad_withFirstTimeUser_setsPositionToBottom() async throws {
        let subject = createSubject()
        User.shared.firstTime = true

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .pad)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, SearchBarPosition.bottom.rawValue)
    }

    private func createSubject() -> EcosiaSearchBarLocationSaver {
        return EcosiaSearchBarLocationSaver()
    }
}
