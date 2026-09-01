// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
// swiftlint:disable implicitly_unwrapped_optional

final class UserStateTests: XCTestCase, @unchecked Sendable, UserPersistenceResettable {
    private var user: User!

    override func setUp() {
        super.setUp()
        resetUserPersistence()
        user = .init()
    }

    override func tearDown() {
        super.tearDown()
        resetUserPersistence()
    }

    func testStoredState() {
        let storedState = ["test": "something_stored"]
        let expect = expectation(description: "")
        User.shared.state = storedState
        User.queue.async {
            let user = User()
            XCTAssertEqual(user.state, storedState)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testShouldShowImpactIntro() {
        XCTAssertTrue(user.shouldShowImpactIntro)

        user.state[User.Key.impactIntro.rawValue] = "\(false)"

        XCTAssertFalse(self.user.shouldShowImpactIntro)
    }

    func testHideImpactIntro() {
        user.state[User.Key.impactIntro.rawValue] = "\(true)"

        user.hideImpactIntro()

        XCTAssertEqual(user.state[User.Key.impactIntro.rawValue], "\(false)")
    }

    func testShowImpactIntro() {
        user.state[User.Key.impactIntro.rawValue] = "\(false)"

        user.showImpactIntro()

        XCTAssertEqual(user.state[User.Key.impactIntro.rawValue], "\(true)")
    }
}
// swiftlint:enable implicitly_unwrapped_optional
