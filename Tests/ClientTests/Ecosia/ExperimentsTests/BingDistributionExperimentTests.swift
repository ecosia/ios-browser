// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class BingDistributionExperimentTests: XCTestCase {

    func testMakeBingSearchURLFromURLAppendingTags() {
        // When
        let bingURL = BingDistributionExperiment.bingSearchWithQuery("apple")
        
        // Then
        XCTAssertEqual(bingURL?.absoluteString,
                       "https://www.bing.com/search?q=apple&PC=ECAA&FORM=ECAA01&PTAG=st_ios_bing_distribution_test")
    }
    
    func testAppendControlGroupAdditionalTypeTagTo() {
        // When
        let updatedURL = BingDistributionExperiment.ecosiaSearchWithTypetag("apple")
        
        // Then
        let components = URLComponents(url: updatedURL!, resolvingAgainstBaseURL: true)
        XCTAssertTrue(components?.queryItems?.contains { $0.name == "tts" && $0.value == "st_ios_bing_distribution_control" } ?? false)
    }
}
