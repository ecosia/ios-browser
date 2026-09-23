// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Ecosia
@testable import Client

@MainActor
final class InvisibleTabSessionTests: XCTestCase {

    private let urlProvider: URLProvider = .production

    func testHasLandedOnWwwPageOtherThanStart() {
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/", from: urlProvider.signUpURL))
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/accounts/profile", from: urlProvider.logoutURL))
    }

    func testHasLandedOnErrorPage() {
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/accounts/error", from: urlProvider.signUpURL))
    }

    func testHasNotLandedOnSignIn() {
        XCTAssertFalse(hasLanded(on: "https://www.ecosia.org/accounts/sign-in", from: urlProvider.signUpURL))
        XCTAssertFalse(hasLanded(on: "https://www.ecosia.org/accounts/sign-in?returnTo=x", from: urlProvider.logoutURL))
    }

    func testHasNotLandedOnStartPage() {
        XCTAssertFalse(hasLanded(on: urlProvider.signUpURL.absoluteString, from: urlProvider.signUpURL))
        XCTAssertFalse(hasLanded(on: "https://www.ecosia.org/accounts/sign-out?x=1", from: urlProvider.logoutURL))
    }

    func testHasNotLandedOnAuth0Host() {
        XCTAssertFalse(hasLanded(on: "https://login.ecosia.org/authorize", from: urlProvider.signUpURL))
        XCTAssertFalse(hasLanded(on: "https://login.ecosia.org/v2/logout", from: urlProvider.logoutURL))
    }

    func testHasNotLandedOnOtherHost() {
        XCTAssertFalse(hasLanded(on: "https://example.com/", from: urlProvider.signUpURL))
    }

    private func hasLanded(on urlString: String, from startURL: URL) -> Bool {
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid URL: \(urlString)")
            return false
        }
        return InvisibleTabSession.hasLanded(on: url, from: startURL, urlProvider: urlProvider)
    }
}
