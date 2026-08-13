// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
import WebKit

final class AIFreeSearchingCookieHandlerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Cookie.setURLProvider(.production)
        resetAIFreeSearchingUserState()
        Unleash.clearInstanceModel()
    }

    override func tearDown() {
        super.tearDown()
        resetAIFreeSearchingUserState()
        Unleash.clearInstanceModel()
        try? FileManager.default.removeItem(at: FileManager.user)
        Cookie.resetURLProvider()
    }

    // MARK: - Three-state cookie

    func testMakeCookieOmitsCookieOnDefault() {
        setAIFreeSearchingFlagEnabled(true)

        let handler = AIFreeSearchingCookieHandler()
        XCTAssertNil(handler.makeCookie(), "Default (never toggled) must omit ECNOAI")
    }

    func testMakeCookieWritesTrueWhenEnabled() {
        setAIFreeSearchingFlagEnabled(true)
        AIFreeSearchingSelection.setEnabled(true)

        let handler = AIFreeSearchingCookieHandler()
        guard let cookie = handler.makeCookie() else {
            return XCTFail("Expected ECNOAI=true after enabling")
        }

        XCTAssertEqual(cookie.name, "ECNOAI")
        XCTAssertEqual(cookie.value, "true")
        XCTAssertEqual(cookie.domain, ".ecosia.org")
        XCTAssertEqual(cookie.path, "/")
    }

    func testMakeCookieWritesFalseWhenExplicitlyDisabled() {
        setAIFreeSearchingFlagEnabled(true)
        AIFreeSearchingSelection.setEnabled(true)
        AIFreeSearchingSelection.setEnabled(false)

        let handler = AIFreeSearchingCookieHandler()
        guard let cookie = handler.makeCookie() else {
            return XCTFail("Expected ECNOAI=false after explicit disable")
        }

        XCTAssertEqual(cookie.name, "ECNOAI")
        XCTAssertEqual(cookie.value, "false")
    }

    func testMakeCookieReturnsNilWhenFlagOffEvenIfEnabled() {
        AIFreeSearchingSelection.setEnabled(true)
        Unleash.clearInstanceModel()

        let handler = AIFreeSearchingCookieHandler()
        XCTAssertNil(handler.makeCookie(), "Flag off must not write ECNOAI")
    }

    // MARK: - received()

    func testReceivedTrueEnablesAndMarksExplicit() {
        setAIFreeSearchingFlagEnabled(true)
        let handler = AIFreeSearchingCookieHandler()
        handler.received(cookie(value: "true"), in: MockHTTPCookieStore())

        XCTAssertEqual(User.shared.aiFreeSearching, true)
        XCTAssertFalse(User.shared.aiOverviews)
    }

    func testReceivedFalseDisablesAndMarksExplicit() {
        setAIFreeSearchingFlagEnabled(true)
        AIFreeSearchingSelection.setEnabled(true)

        let handler = AIFreeSearchingCookieHandler()
        handler.received(cookie(value: "false"), in: MockHTTPCookieStore())

        XCTAssertEqual(User.shared.aiFreeSearching, false)
    }

    func testReceivedInvalidValueResetsToDefault() {
        setAIFreeSearchingFlagEnabled(true)
        AIFreeSearchingSelection.setEnabled(true)

        let handler = AIFreeSearchingCookieHandler()
        handler.received(cookie(value: "invalid"), in: MockHTTPCookieStore())

        XCTAssertNil(User.shared.aiFreeSearching)
        XCTAssertNil(handler.makeCookie())
    }

    func testReceivedIsNoOpWhenFlagOff() {
        User.shared.aiOverviews = true
        let handler = AIFreeSearchingCookieHandler()
        handler.received(cookie(value: "true"), in: MockHTTPCookieStore())

        XCTAssertNil(User.shared.aiFreeSearching)
        XCTAssertTrue(User.shared.aiOverviews)
    }

    func testRoundTripEnableDisableViaReceived() {
        setAIFreeSearchingFlagEnabled(true)
        let handler = AIFreeSearchingCookieHandler()

        handler.received(cookie(value: "true"), in: MockHTTPCookieStore())
        XCTAssertEqual(handler.makeCookie()?.value, "true")

        handler.received(cookie(value: "false"), in: MockHTTPCookieStore())
        XCTAssertEqual(handler.makeCookie()?.value, "false")
    }

    func testCookieNameIsCorrect() {
        XCTAssertEqual(AIFreeSearchingCookieHandler().cookieName, "ECNOAI")
    }

    // MARK: - Integration with cookie factories

    func testRequiredCookiesOmitECNOAIOnDefault() {
        setAIFreeSearchingFlagEnabled(true)
        let cookies = Cookie.makeRequiredCookies(isPrivate: false)
        XCTAssertFalse(cookies.contains { $0.name == "ECNOAI" })
    }

    func testRequiredCookiesIncludeECNOAIWhenEnabled() {
        setAIFreeSearchingFlagEnabled(true)
        AIFreeSearchingSelection.setEnabled(true)

        let cookies = Cookie.makeRequiredCookies(isPrivate: false)
        let aiFree = cookies.filter { $0.name == "ECNOAI" }
        XCTAssertEqual(aiFree.count, 1)
        XCTAssertEqual(aiFree.first?.value, "true")
    }

    func testSearchSettingsObserverCookiesIncludeECNOAIWhenEnabled() {
        setAIFreeSearchingFlagEnabled(true)
        AIFreeSearchingSelection.setEnabled(true)

        let cookies = Cookie.makeSearchSettingsObserverCookies(isPrivate: false)
        XCTAssertEqual(cookies.first { $0.name == "ECNOAI" }?.value, "true")
    }

    func testSearchSettingsObserverCookiesOmitECNOAIOnDefault() {
        setAIFreeSearchingFlagEnabled(true)
        let cookies = Cookie.makeSearchSettingsObserverCookies(isPrivate: false)
        XCTAssertFalse(cookies.contains { $0.name == "ECNOAI" })
    }

    func testMutualExclusionWritesECAIOFalse() {
        setAIFreeSearchingFlagEnabled(true)
        User.shared.aiOverviews = true
        AIFreeSearchingSelection.setEnabled(true)

        XCTAssertFalse(User.shared.aiOverviews)
        XCTAssertEqual(AIOverviewsCookieHandler().makeCookie()?.value, "false")
        XCTAssertEqual(AIFreeSearchingCookieHandler().makeCookie()?.value, "true")
    }

    // MARK: - Helpers

    private func cookie(value: String) -> HTTPCookie {
        HTTPCookie(properties: [
            .name: "ECNOAI",
            .domain: ".ecosia.org",
            .path: "/",
            .value: value
        ])!
    }
}

private func resetAIFreeSearchingUserState() {
    User.shared.aiFreeSearching = nil
    User.shared.aiOverviews = true
}

private func setAIFreeSearchingFlagEnabled(_ enabled: Bool) {
    let toggle = Unleash.Toggle(
        name: Unleash.Toggle.Name.aiFreeSearching.rawValue,
        enabled: enabled,
        variant: Unleash.Variant(name: "", enabled: false, payload: nil)
    )
    Unleash.model = Unleash.Model(toggles: Set([toggle]))
}
