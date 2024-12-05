@testable import Core
import XCTest

final class UserStateTests: XCTestCase {
    private var user: User!

    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)
        user = .init()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: FileManager.user)
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
