// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest
import Shared
import Glean

@testable import Client

@MainActor
class BrowserViewControllerTests: XCTestCase {
    var profile: MockProfile!
    var tabManager: MockTabManager!
    var browserViewController: BrowserViewController!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        TelemetryContextualIdentifier.setupContextId()
        Glean.shared.resetGlean(clearStores: true)

        profile = MockProfile()
        tabManager = MockTabManager()
        browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
    }

    override func tearDown() {
        TelemetryContextualIdentifier.clearUserDefaults()
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testTrackVisibleSuggestion() throws {
        // Ecosia: Firefox Glean telemetry is silenced (Ecosia uses Snowplow), so the Firefox Suggest
        // impression ping is never submitted and this expectation can never be fulfilled. The Firefox
        // Suggest feature/telemetry is not used in Ecosia.
        throw XCTSkip("Firefox Suggest Glean telemetry is not used in Ecosia (Snowplow is used instead).")
        /* Ecosia: Firefox-only telemetry assertions retained for upstream merges.
        let expectation = expectation(description: "The Firefox Suggest ping was sent")

        GleanMetrics.Pings.shared.fxSuggest.testBeforeNextSubmit { _ in
            XCTAssertEqual(GleanMetrics.FxSuggest.pingType.testGetValue(), "fxsuggest-impression")
            XCTAssertEqual(
                GleanMetrics.FxSuggest.contextId.testGetValue()?.uuidString,
                TelemetryContextualIdentifier.contextId
            )
            XCTAssertEqual(GleanMetrics.FxSuggest.isClicked.testGetValue(), false)
            XCTAssertEqual(GleanMetrics.FxSuggest.position.testGetValue(), 3)
            XCTAssertEqual(GleanMetrics.FxSuggest.blockId.testGetValue(), 1)
            XCTAssertEqual(GleanMetrics.FxSuggest.advertiser.testGetValue(), "test advertiser")
            XCTAssertEqual(GleanMetrics.FxSuggest.iabCategory.testGetValue(), "999 - Test Category")
            XCTAssertEqual(GleanMetrics.FxSuggest.reportingUrl.testGetValue(), "https://example.com/ios_test_impression_reporting_url")
            expectation.fulfill()
        }

        browserViewController.trackVisibleSuggestion(
            telemetryInfo: .firefoxSuggestion(
                RustFirefoxSuggestionTelemetryInfo.amp(
                    blockId: 1,
                    advertiser: "test advertiser",
                    iabCategory: "999 - Test Category",
                    impressionReportingURL: URL(string: "https://example.com/ios_test_impression_reporting_url"),
                    clickReportingURL: URL(string: "https://example.com/ios_test_click_reporting_url")
                ),
                position: 3,
                didTap: false
            ),
            suggestTelemetry: FxSuggestTelemetry()
        )

        wait(for: [expectation], timeout: 5.0)
         */
    }
}
