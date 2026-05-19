// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class StagingURLProviderTests: XCTestCase {

    var urlProvider: URLProvider = .staging

    func testStaging() {
        XCTAssertEqual("https://www.ecosia-staging.xyz", urlProvider.root.absoluteString)
    }

    func testStagingURLsAreValid() {
        XCTAssertNotNil(urlProvider.root)
        XCTAssertNotNil(urlProvider.statistics)
        XCTAssertNotNil(urlProvider.privacy)
        XCTAssertNotNil(urlProvider.faq)
        XCTAssertNotNil(urlProvider.terms)
        XCTAssertNotNil(urlProvider.aboutCounter)
        XCTAssertNotNil(urlProvider.snowplow)
        XCTAssertNotNil(urlProvider.notifications)
    }

    // MARK: - Search term extraction (address bar query display)
    //
    // The Ecosia search engine XML template is hardcoded to ecosia.org, so the standard
    // OpenSearchEngine matching fails for staging URLs. The AddressToolbarContainerModel
    // fallback uses isEcosiaSearchVertical + getEcosiaSearchQuery, tested here.

    func testStagingTextSearchIsSearchVertical() {
        let url = URL(string: "https://www.ecosia-staging.xyz/search?q=trees")!
        XCTAssertTrue(url.isEcosiaSearchVertical(urlProvider))
    }

    func testStagingImageSearchIsSearchVertical() {
        let url = URL(string: "https://www.ecosia-staging.xyz/images?q=ocean")!
        XCTAssertTrue(url.isEcosiaSearchVertical(urlProvider))
    }

    func testStagingVideoSearchIsSearchVertical() {
        let url = URL(string: "https://www.ecosia-staging.xyz/videos?q=reforestation")!
        XCTAssertTrue(url.isEcosiaSearchVertical(urlProvider))
    }

    func testStagingNewsSearchIsSearchVertical() {
        let url = URL(string: "https://www.ecosia-staging.xyz/news?q=solar+energy")!
        XCTAssertTrue(url.isEcosiaSearchVertical(urlProvider))
    }

    func testStagingSearchReturnsQuery() {
        let url = URL(string: "https://www.ecosia-staging.xyz/search?q=trees")!
        XCTAssertEqual(url.getEcosiaSearchQuery(urlProvider), "trees")
    }

    func testStagingImageSearchReturnsQuery() {
        let url = URL(string: "https://www.ecosia-staging.xyz/images?q=ocean")!
        XCTAssertEqual(url.getEcosiaSearchQuery(urlProvider), "ocean")
    }

    func testNonSearchStagingPageIsNotSearchVertical() {
        let url = URL(string: "https://www.ecosia-staging.xyz/settings")!
        XCTAssertFalse(url.isEcosiaSearchVertical(urlProvider))
        XCTAssertNil(url.getEcosiaSearchQuery(urlProvider))
    }
}
