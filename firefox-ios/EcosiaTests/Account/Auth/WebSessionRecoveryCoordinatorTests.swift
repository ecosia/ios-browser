// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import XCTest
@testable import Client

@MainActor
final class WebSessionRecoveryCoordinatorTests: XCTestCase {

    func testIsWebSessionRecord_withRegistrableDomain_isTrue() {
        XCTAssertTrue(WebSessionRecoveryCoordinator.isWebSessionRecord(displayName: "ecosia.org", urlProvider: .production))
    }

    func testIsWebSessionRecord_withWebHost_isTrue() {
        XCTAssertTrue(WebSessionRecoveryCoordinator.isWebSessionRecord(displayName: "www.ecosia.org", urlProvider: .production))
    }

    func testIsWebSessionRecord_ignoresCase() {
        XCTAssertTrue(WebSessionRecoveryCoordinator.isWebSessionRecord(displayName: "Ecosia.org", urlProvider: .production))
    }

    func testIsWebSessionRecord_withOtherEnvironmentsDomain_isFalse() {
        XCTAssertFalse(WebSessionRecoveryCoordinator.isWebSessionRecord(displayName: "ecosia-staging.xyz", urlProvider: .production))
    }

    func testIsWebSessionRecord_withLookalikeDomain_isFalse() {
        XCTAssertFalse(WebSessionRecoveryCoordinator.isWebSessionRecord(displayName: "notecosia.org", urlProvider: .production))
    }
}
