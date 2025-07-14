// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Ecosia

final class AuthStateActionTests: XCTestCase {

    var testWindowUUID: WindowUUID!

    override func setUp() {
        super.setUp()
        testWindowUUID = WindowUUID.XCTestDefaultUUID
    }

    override func tearDown() {
        testWindowUUID = nil
        super.tearDown()
    }

    // MARK: - Business Logic Tests

    func testAuthStateAction_withDefaultTimestamp_setsCurrentTimestamp() {
        // This tests our business logic: default timestamp should be "now"
        let before = Date()
        let action = AuthStateAction(
            type: .userLoggedIn,
            windowUUID: testWindowUUID,
            isLoggedIn: true
        )
        let after = Date()

        XCTAssertTrue(action.timestamp >= before && action.timestamp <= after, "Timestamp should default to current time")
    }

    func testAuthWindowState_withDefaultLastUpdated_setsCurrentTimestamp() {
        // This tests our business logic: default lastUpdated should be "now"
        let before = Date()
        let state = AuthWindowState(
            windowUUID: testWindowUUID,
            isLoggedIn: true,
            authStateLoaded: true
        )
        let after = Date()

        XCTAssertTrue(state.lastUpdated >= before && state.lastUpdated <= after, "LastUpdated should default to current time")
    }

    func testEcosiaAuthActionType_rawValues_matchExpectedStrings() {
        // This tests our API contract: raw values are used in notification userInfo
        XCTAssertEqual(EcosiaAuthActionType.authStateLoaded.rawValue, "authStateLoaded")
        XCTAssertEqual(EcosiaAuthActionType.userLoggedIn.rawValue, "userLoggedIn")
        XCTAssertEqual(EcosiaAuthActionType.userLoggedOut.rawValue, "userLoggedOut")
    }

    func testEcosiaAuthActionType_allCases_containsExpectedCases() {
        // This catches missing cases during refactoring
        let expectedCases: [EcosiaAuthActionType] = [.authStateLoaded, .userLoggedIn, .userLoggedOut]
        XCTAssertEqual(Set(EcosiaAuthActionType.allCases), Set(expectedCases), "Should contain exactly the expected cases")
    }
}
