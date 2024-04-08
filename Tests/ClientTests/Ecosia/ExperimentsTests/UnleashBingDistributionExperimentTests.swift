// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class UnleashBingDistributionExperimentTests: XCTestCase {
        
    func testMakeBingSearchURLFromURLNotNil() {
        let url = URL(string: "https://google.com/search?q=test")!
        let bingUrl = BingDistributionExperiment.makeBingSearchURLFromURL(url)
        XCTAssertNotNil(bingUrl)
    }
    
    func testMakeBingSearchURLFromURL() {
        let sourceURL = URL(string: "https://google.com?q=swift")!
        let expectedURLString = "https://bing.com?q=swift"
        let resultURL = BingDistributionExperiment.makeBingSearchURLFromURL(sourceURL)
        XCTAssertEqual(resultURL?.baseDomain, URL(string: expectedURLString)!.baseDomain, "URL should be modified to use bing.com")
    }
    
    func testMakeBingSearchURLFromURLAppendingTags() {
        // Given
        let sourceURL = URL(string: "https://www.example.com/search?q=apple")!
        
        // When
        let bingURL = BingDistributionExperiment.makeBingSearchURLFromURL(sourceURL)
        let components = URLComponents(url: bingURL!, resolvingAgainstBaseURL: false)
        
        XCTAssertNotNil(components)
        XCTAssertEqual(components!.scheme, "https")
        XCTAssertEqual(components!.host, "bing.com")
        XCTAssertEqual(components!.queryItems?.count, 3)
        XCTAssertEqual(components!.queryItems?.first(where: { $0.name == "PC" })?.value, "ECAA")
        XCTAssertEqual(components!.queryItems?.first(where: { $0.name == "FROM" })?.value, "ECAA01")
        XCTAssertEqual(components!.queryItems?.first(where: { $0.name == "PTAG" })?.value, "st_ios_bing_distribution_test")
    }
    
    func testAppendControlGroupAdditionalTypeTagTo() {
        // Given
        let sourceURL = URL(string: "https://www.example.com/search?q=apple")!
        
        // When
        let updatedURL = BingDistributionExperiment.appendControlGroupAdditionalTypeTagTo(sourceURL)
        
        // Then
        guard let components = URLComponents(url: updatedURL, resolvingAgainstBaseURL: true) else {
            XCTFail("Failed to create URL components")
            return
        }
        
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "www.example.com")
        XCTAssertEqual(components.path, "/search")
        
        // Check if the "tts" query item with the expected value is appended
        XCTAssertTrue(components.queryItems?.contains { $0.name == "tts" && $0.value == "st_ios_bing_distribution_control" } ?? false)
    }
}
