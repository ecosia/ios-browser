// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia
@testable import Client

@MainActor
final class SearchEnginesManagerReconfigureTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Unleash.clearInstanceModel()
        Unleash.loadCachedModelIfNeeded()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        Unleash.clearInstanceModel()
        super.tearDown()
    }

    func testReconfigureEngineProviderSwapsToHybridWhenFlagBecomesEnabled() {
        var model = Unleash.Model()
        model.updated = Date()
        model.toggles.insert(
            Unleash.Toggle(
                name: Unleash.Toggle.Name.customSearchProvider.rawValue,
                enabled: true,
                variant: .init(name: "enabled", enabled: true, payload: nil)
            )
        )
        Unleash.model = model

        let manager: SearchEnginesManager = AppContainer.shared.resolve()
        manager.reconfigureEngineProviderIfNeeded()

        let expectation = expectation(description: "Hybrid engines load after reconfigure")
        manager.getOrderedEngines { _, engines in
            XCTAssertGreaterThan(engines.count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
}
