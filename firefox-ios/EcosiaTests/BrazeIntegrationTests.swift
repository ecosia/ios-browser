// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class BrazeIntegrationTests: XCTestCase {

    private var previousUnleashModel = Unleash.Model()

    override func setUp() {
        super.setUp()
        previousUnleashModel = Unleash.model
    }

    override func tearDown() {
        Unleash.model = previousUnleashModel
        super.tearDown()
    }

    // MARK: - isEnabled

    func testIsEnabled_forControlVariant_returnsTrue() {
        setCoreMarketsFlag(variant: BrazeCoreMarketVariant.control.rawValue)

        XCTAssertTrue(BrazeIntegration.isEnabled)
    }

    func testIsEnabled_forTreatmentVariant_returnsTrue() {
        setCoreMarketsFlag(variant: BrazeCoreMarketVariant.treatment.rawValue)

        XCTAssertTrue(BrazeIntegration.isEnabled)
    }

    func testIsEnabled_forHoldoutVariant_returnsFalse() {
        setCoreMarketsFlag(variant: BrazeCoreMarketVariant.holdout.rawValue)

        XCTAssertFalse(BrazeIntegration.isEnabled)
    }

    func testIsEnabled_forUnknownVariant_returnsFalse() {
        setCoreMarketsFlag(variant: "unknown-variant")

        XCTAssertFalse(BrazeIntegration.isEnabled)
    }

    func testIsEnabled_whenCoreMarketsFlagIsOff_returnsFalse() {
        setCoreMarketsFlag(enabled: false, variant: BrazeCoreMarketVariant.treatment.rawValue)

        XCTAssertFalse(BrazeIntegration.isEnabled)
    }

    func testIsEnabled_whenFlagCannotBeEvaluated_returnsFalse() {
        Unleash.model = Unleash.Model()

        XCTAssertFalse(BrazeIntegration.isEnabled)
    }

    // MARK: - isReportedToAnalytics

    func testIsReportedToAnalytics_forTreatmentVariant_returnsTrue() {
        setCoreMarketsFlag(variant: BrazeCoreMarketVariant.treatment.rawValue)

        XCTAssertTrue(BrazeIntegration.isReportedToAnalytics)
    }

    func testIsReportedToAnalytics_forHoldoutVariant_returnsTrue() {
        setCoreMarketsFlag(variant: BrazeCoreMarketVariant.holdout.rawValue)

        XCTAssertTrue(BrazeIntegration.isReportedToAnalytics)
    }

    func testIsReportedToAnalytics_forControlVariant_returnsFalse() {
        setCoreMarketsFlag(variant: BrazeCoreMarketVariant.control.rawValue)

        XCTAssertFalse(BrazeIntegration.isReportedToAnalytics)
    }

    func testIsReportedToAnalytics_whenFlagCannotBeEvaluated_returnsFalse() {
        Unleash.model = Unleash.Model()

        XCTAssertFalse(BrazeIntegration.isReportedToAnalytics)
    }

    // MARK: - Helpers

    private func setCoreMarketsFlag(enabled: Bool = true, variant: String) {
        var model = Unleash.Model()
        model.toggles.insert(
            Unleash.Toggle(name: Unleash.Toggle.Name.brazeCoreMarkets.rawValue,
                           enabled: enabled,
                           variant: .init(name: variant, enabled: true, payload: nil))
        )
        Unleash.model = model
    }
}
