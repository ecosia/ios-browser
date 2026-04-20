// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia
@testable import Client
// swiftlint:disable implicitly_unwrapped_optional

class EcosiaNTPTooltipHighlightTests: XCTestCase {

    var user: Ecosia.User!

    override func setUpWithError() throws {
        try? FileManager().removeItem(at: FileManager.user)
        user = .init()
        user.firstTime = false
    }

    func testFirstTimeReturnsNil() throws {
        user.firstTime = true
        XCTAssertNil(NTPTooltip.highlight(for: user))
    }

    func testImpactIntro() throws {
        user.showImpactIntro()
        XCTAssert(NTPTooltip.highlight(for: user) == .collectiveImpactIntro)
    }

    func testFallthrough() throws {
        user.hideImpactIntro()
        XCTAssertNil(NTPTooltip.highlight(for: user))
    }
}
// swiftlint:enable implicitly_unwrapped_optional
