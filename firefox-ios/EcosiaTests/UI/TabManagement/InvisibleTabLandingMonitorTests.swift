// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Ecosia
@testable import Client

@MainActor
final class InvisibleTabLandingMonitorTests: XCTestCase {

    private let urlProvider: URLProvider = .production
    private let settleDelay: TimeInterval = 0.05
    private let landedURL = URL(string: "https://www.ecosia.org/")!

    // MARK: - Landing Transitions

    func testReportsLandingOnceIdleOnLandedPage() {
        let landed = expectation(description: "Landing reported")
        var reportedURLs: [URL] = []
        let monitor = makeMonitor { reportedURLs.append($0); landed.fulfill() }

        monitor.start(isLoading: true)
        monitor.urlChanged(to: landedURL)
        monitor.loadingChanged(isLoading: false)

        wait(for: [landed], timeout: 1.0)
        waitPastSettleDelay()
        XCTAssertEqual(reportedURLs, [landedURL])
    }

    func testRedirectWithinSettleDelayCancelsPendingLanding() {
        var reportCount = 0
        let monitor = makeMonitor { _ in reportCount += 1 }

        monitor.start(isLoading: true)
        monitor.urlChanged(to: landedURL)
        monitor.loadingChanged(isLoading: false)
        monitor.loadingChanged(isLoading: true)

        waitPastSettleDelay()
        XCTAssertEqual(reportCount, 0)
    }

    func testReportsLandingAfterRedirectChainSettles() {
        let landed = expectation(description: "Landing reported")
        var reportedURLs: [URL] = []
        let monitor = makeMonitor { reportedURLs.append($0); landed.fulfill() }
        let callbackURL = URL(string: "https://www.ecosia.org/accounts/callback")!

        monitor.start(isLoading: true)
        monitor.urlChanged(to: callbackURL)
        monitor.loadingChanged(isLoading: false)
        monitor.loadingChanged(isLoading: true)
        monitor.urlChanged(to: landedURL)
        monitor.loadingChanged(isLoading: false)

        wait(for: [landed], timeout: 1.0)
        XCTAssertEqual(reportedURLs, [landedURL])
    }

    func testReportsLandingThatHappenedBeforeStart() {
        let landed = expectation(description: "Landing reported")
        let monitor = makeMonitor { _ in landed.fulfill() }

        monitor.urlChanged(to: landedURL)
        monitor.loadingChanged(isLoading: false)
        monitor.start(isLoading: false)

        wait(for: [landed], timeout: 1.0)
    }

    func testDoesNotReportBeforeStart() {
        var reportCount = 0
        let monitor = makeMonitor { _ in reportCount += 1 }

        monitor.urlChanged(to: landedURL)
        monitor.loadingChanged(isLoading: false)

        waitPastSettleDelay()
        XCTAssertEqual(reportCount, 0)
    }

    func testStopCancelsPendingLanding() {
        var reportCount = 0
        let monitor = makeMonitor { _ in reportCount += 1 }

        monitor.start(isLoading: true)
        monitor.urlChanged(to: landedURL)
        monitor.loadingChanged(isLoading: false)
        monitor.stop()

        waitPastSettleDelay()
        XCTAssertEqual(reportCount, 0)
    }

    func testDoesNotReportWhileIdleOnStartPage() {
        var reportCount = 0
        let monitor = makeMonitor { _ in reportCount += 1 }

        monitor.start(isLoading: false)

        waitPastSettleDelay()
        XCTAssertEqual(reportCount, 0)
    }

    // MARK: - Landed Pages

    func testHasLandedOnWwwPageOtherThanStart() {
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/", from: urlProvider.signUpURL))
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/accounts/profile", from: urlProvider.logoutURL))
    }

    func testHasLandedOnErrorPage() {
        XCTAssertTrue(hasLanded(on: "https://www.ecosia.org/accounts/error", from: urlProvider.signUpURL))
    }

    func testHasLandedOnErrorPageThatIsAlsoTheStartPage() {
        let errorURL = URL(string: "https://www.ecosia.org/accounts/error")!
        XCTAssertTrue(InvisibleTabLandingMonitor.hasLanded(on: errorURL, from: errorURL, urlProvider: urlProvider))
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

    // MARK: - Helpers

    private func makeMonitor(onLanded: @escaping (URL) -> Void) -> InvisibleTabLandingMonitor {
        InvisibleTabLandingMonitor(startURL: urlProvider.signUpURL,
                                   urlProvider: urlProvider,
                                   settleDelay: settleDelay,
                                   onLanded: onLanded)
    }

    private func waitPastSettleDelay() {
        let waited = expectation(description: "Waited past settle delay")
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay * 4) { waited.fulfill() }
        wait(for: [waited], timeout: 1.0)
    }

    private func hasLanded(on urlString: String, from startURL: URL) -> Bool {
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid URL: \(urlString)")
            return false
        }
        return InvisibleTabLandingMonitor.hasLanded(on: url, from: startURL, urlProvider: urlProvider)
    }
}
