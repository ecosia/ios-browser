// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Ecosia

final class AccountsDisabledOnIPadFeatureTests: XCTestCase {

    func testIsEnabled_whenIPad_returnsTrue() {
        XCTAssertTrue(AccountsDisabledOnIPadFeature.isEnabled(for: .pad))
    }

    func testIsEnabled_whenIPhone_returnsFalse() {
        XCTAssertFalse(AccountsDisabledOnIPadFeature.isEnabled(for: .phone))
    }

    func testIsEnabled_whenMac_returnsFalse() {
        XCTAssertFalse(AccountsDisabledOnIPadFeature.isEnabled(for: .mac))
    }
}
