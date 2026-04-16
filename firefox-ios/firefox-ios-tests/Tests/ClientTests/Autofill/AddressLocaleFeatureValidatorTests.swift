// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common

@testable import Client

class AddressLocaleFeatureValidatorTests: XCTestCase {
    func testValidRegionCA() {
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: "CA"),
            "Region valid for CA"
        )
    }

    func testValidRegionUS() {
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: "US"),
            "Region valid for US"
        )
    }

    func testInvalidRegionFR() {
        // Ecosia: FR is now a supported region in v147
        XCTAssertTrue(
            AddressLocaleFeatureValidator.isValidRegion(for: "FR"),
            "Region valid for FR"
        )
    }

    func testInvalidRegionWithoutRegionCode() {
        XCTAssertFalse(
            AddressLocaleFeatureValidator.isValidRegion(for: ""),
            "Invalid region for empty region code"
        )
    }
}
