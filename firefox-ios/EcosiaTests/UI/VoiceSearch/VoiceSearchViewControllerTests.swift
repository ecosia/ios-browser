// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class VoiceSearchViewControllerTests: XCTestCase {

    func testViewControllerInitialization() {
        let sut = VoiceSearchViewController { _ in }

        // Verify the VC can be created and its view hierarchy loads
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func testVoiceSearchRouteEquatable() {
        let route1: Route = .voiceSearch
        let route2: Route = .voiceSearch

        XCTAssertEqual(route1, route2)
    }

    func testVoiceSearchDeeplinkHost() {
        let host = DeeplinkInput.Host(rawValue: "widget-voice-search")

        XCTAssertEqual(host, .widgetVoiceSearch)
    }

    func testVoiceSearchDeeplinkIsValidURL() {
        let host = DeeplinkInput.Host.widgetVoiceSearch

        XCTAssertTrue(host.isValidURL(urlQuery: nil))
    }
}
