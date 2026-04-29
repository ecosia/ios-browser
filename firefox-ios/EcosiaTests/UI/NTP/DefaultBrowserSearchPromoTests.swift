// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import Ecosia

/// Tests for MOB-4323 — Ecosia default-browser promo triggered after search-count threshold.
///
/// The eligibility logic is isolated in `BrowserViewController.isEligibleForEcosiaDefaultBrowserSearchPromo`,
/// which makes it straightforward to unit-test without spinning up a real `BrowserViewController`.
final class DefaultBrowserSearchPromoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        User.shared.resetDefaultBrowserSearchPromo()
    }

    override func tearDown() {
        User.shared.resetDefaultBrowserSearchPromo()
        super.tearDown()
    }

    // MARK: - Threshold constant

    func testMinSearchCountToTriggerIs50() {
        XCTAssertEqual(
            DefaultBrowserViewController.minSearchCountToTrigger,
            50,
            "Threshold changed — re-verify analytics and QA guidance for MOB-4323."
        )
    }

    // MARK: - isEligibleForEcosiaDefaultBrowserSearchPromo

    func testEligible_whenCountAboveThreshold_notDefault_notShown() {
        XCTAssertTrue(eligible(searchCount: 51, isDefaultBrowser: false, promoAlreadyShown: false))
    }

    func testEligible_exactlyAtThresholdPlusOne() {
        XCTAssertTrue(eligible(searchCount: DefaultBrowserViewController.minSearchCountToTrigger + 1,
                               isDefaultBrowser: false,
                               promoAlreadyShown: false))
    }

    func testNotEligible_exactlyAtThreshold() {
        XCTAssertFalse(eligible(searchCount: DefaultBrowserViewController.minSearchCountToTrigger,
                                isDefaultBrowser: false,
                                promoAlreadyShown: false),
                       "Promo requires count *greater than* the threshold, not equal.")
    }

    func testNotEligible_countBelowThreshold() {
        XCTAssertFalse(eligible(searchCount: 10, isDefaultBrowser: false, promoAlreadyShown: false))
    }

    func testNotEligible_alreadyDefaultBrowser() {
        XCTAssertFalse(eligible(searchCount: 100, isDefaultBrowser: true, promoAlreadyShown: false))
    }

    func testNotEligible_promoAlreadyShown() {
        XCTAssertFalse(eligible(searchCount: 100, isDefaultBrowser: false, promoAlreadyShown: true))
    }

    func testNotEligible_alreadyDefaultAndPromoShown() {
        XCTAssertFalse(eligible(searchCount: 100, isDefaultBrowser: true, promoAlreadyShown: true))
    }

    func testNotEligible_zeroSearchCount() {
        XCTAssertFalse(eligible(searchCount: 0, isDefaultBrowser: false, promoAlreadyShown: false))
    }

    // MARK: - Helpers

    private func eligible(searchCount: Int, isDefaultBrowser: Bool, promoAlreadyShown: Bool) -> Bool {
        BrowserViewController.isEligibleForEcosiaDefaultBrowserSearchPromo(
            searchCount: searchCount,
            isDefaultBrowser: isDefaultBrowser,
            promoAlreadyShown: promoAlreadyShown
        )
    }
}
