// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Ecosia

final class AccountsDisabledTests: XCTestCase {

    func testIsActive_whenIPad_returnsTrue() {
        XCTAssertTrue(AccountsDisabled.isActive(for: .pad))
    }

    func testIsActive_whenIPhone_returnsFalse() {
        XCTAssertFalse(AccountsDisabled.isActive(for: .phone))
    }

    func testIsActive_whenMac_returnsFalse() {
        XCTAssertFalse(AccountsDisabled.isActive(for: .mac))
    }
}
