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
        SearchRouterConfiguration.invalidateCache()
        super.tearDown()
    }

    func testReconfigureEngineProviderSwapsToCuratedWhenFlagBecomesEnabled() {
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

        let expectation = expectation(description: "Curated engines load after reconfigure")
        manager.getOrderedEngines { _, engines in
            XCTAssertGreaterThan(engines.count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    /// A refresh that only narrows the provider allowlist leaves the flag on, so the engine
    /// list must still be rebuilt.
    func testReconfigureRebuildsWhenOnlyThePayloadChanges() {
        setRouterToggle(payload: #"{"providers": ["ecosia", "google", "duckduckgo"]}"#)
        let manager: SearchEnginesManager = AppContainer.shared.resolve()
        manager.reconfigureEngineProviderIfNeeded()
        waitForEngines(manager) { XCTAssertTrue($0.contains("duckduckgo")) }

        setRouterToggle(payload: #"{"providers": ["ecosia"]}"#)
        manager.reconfigureEngineProviderIfNeeded()
        waitForEngines(manager) { XCTAssertEqual($0, ["ecosia"]) }
    }

    func testReconfigureIsANoOpWhenNothingChanged() {
        setRouterToggle(payload: #"{"providers": ["ecosia", "google"]}"#)
        let manager: SearchEnginesManager = AppContainer.shared.resolve()
        manager.reconfigureEngineProviderIfNeeded()
        waitForEngines(manager) { XCTAssertEqual($0, ["ecosia", "google"]) }

        // Same configuration, so the list must be unchanged rather than rebuilt differently.
        manager.reconfigureEngineProviderIfNeeded()
        waitForEngines(manager) { XCTAssertEqual($0, ["ecosia", "google"]) }
    }

    // MARK: - Helpers

    private func setRouterToggle(payload: String?) {
        var model = Unleash.Model()
        model.updated = Date()
        model.toggles.insert(
            Unleash.Toggle(
                name: Unleash.Toggle.Name.customSearchProvider.rawValue,
                enabled: true,
                variant: .init(name: "config",
                               enabled: true,
                               payload: payload.map { .init(type: "json", value: $0) })
            )
        )
        Unleash.model = model
        SearchRouterConfiguration.invalidateCache()
    }

    private func waitForEngines(_ manager: SearchEnginesManager,
                                _ assert: @escaping ([String]) -> Void) {
        let expectation = expectation(description: "engines load")
        manager.getOrderedEngines { _, engines in
            assert(engines.map(\.engineID))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
}
