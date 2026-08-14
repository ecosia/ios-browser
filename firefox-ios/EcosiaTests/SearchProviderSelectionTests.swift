// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import XCTest
@testable import Client

@MainActor
final class SearchProviderSelectionTests: XCTestCase {

    private var previousEngineID: String!

    override func setUp() {
        super.setUp()
        previousEngineID = User.shared.selectedSearchEngineID
    }

    override func tearDown() {
        User.shared.selectedSearchEngineID = previousEngineID
        super.tearDown()
    }

    func testShowsEcosiaSearchSettingsWhenFeatureFlagDisabled() throws {
        guard !CustomSearchProviderFeatureFlag.isEnabled else {
            throw XCTSkip("Requires custom search provider flag to be disabled")
        }

        User.shared.selectedSearchEngineID = SearchProviderSelection.googleEngineID
        XCTAssertTrue(SearchProviderSelection.showsEcosiaSearchSettings)
    }

    func testPrepareSearchSettingsSectionResetsEngineIDWhenFeatureFlagDisabled() throws {
        guard !CustomSearchProviderFeatureFlag.isEnabled else {
            throw XCTSkip("Requires custom search provider flag to be disabled")
        }

        User.shared.selectedSearchEngineID = SearchProviderSelection.googleEngineID
        SearchProviderSelection.prepareSearchSettingsSection(defaultEngineID: SearchProviderSelection.googleEngineID)

        XCTAssertEqual(User.shared.selectedSearchEngineID, SearchProviderSelection.ecosiaEngineID)
    }

    func testPrepareSearchSettingsSectionSyncsDefaultEngineWhenFeatureFlagEnabled() throws {
        guard CustomSearchProviderFeatureFlag.isEnabled else {
            throw XCTSkip("Custom search provider flag is disabled in this test run")
        }

        User.shared.selectedSearchEngineID = SearchProviderSelection.ecosiaEngineID
        SearchProviderSelection.prepareSearchSettingsSection(defaultEngineID: SearchProviderSelection.googleEngineID)

        XCTAssertEqual(User.shared.selectedSearchEngineID, SearchProviderSelection.googleEngineID)
        XCTAssertFalse(SearchProviderSelection.showsEcosiaSearchSettings)
    }
}
