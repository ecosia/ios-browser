// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class BrazeIntegrationExperimentTests: XCTestCase {

    private var previousUnleashModel = Unleash.Model()

    override func setUp() {
        super.setUp()
        previousUnleashModel = Unleash.model
    }

    override func tearDown() {
        Unleash.model = previousUnleashModel
        super.tearDown()
    }

    func testIsEnabled_whenCoreMarketsFlagIsOn_returnsTrue() {
        setCoreMarketsFlag(enabled: true)

        XCTAssertTrue(BrazeIntegrationExperiment.isEnabled)
    }

    func testIsEnabled_whenCoreMarketsFlagIsOff_returnsFalse() {
        setCoreMarketsFlag(enabled: false)

        XCTAssertFalse(BrazeIntegrationExperiment.isEnabled)
    }

    func testIsEnabled_whenFlagCannotBeEvaluated_returnsFalse() {
        Unleash.model = Unleash.Model()

        XCTAssertFalse(BrazeIntegrationExperiment.isEnabled)
    }

    // MARK: - Helpers

    private func setCoreMarketsFlag(enabled: Bool) {
        var model = Unleash.Model()
        model.toggles.insert(
            Unleash.Toggle(name: Unleash.Toggle.Name.brazeCoreMarkets.rawValue,
                           enabled: enabled,
                           variant: .init(name: "control", enabled: true, payload: nil))
        )
        Unleash.model = model
    }
}
