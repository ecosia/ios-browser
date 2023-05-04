// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class UnleashBingExperimentTests: XCTestCase {
    
    func testIncrementCounter() {
        let initialCount = BingSearchExperiment.getCounterCurrentCount()
        BingSearchExperiment.incrementCounter()
        let finalCount = BingSearchExperiment.getCounterCurrentCount()
        XCTAssertEqual(initialCount + 1, finalCount, "Counter should be incremented by 1")
    }
    
    func testIncrementCounterMultipleTimes() {
        BingSearchExperiment.incrementCounter()
        XCTAssertEqual(BingSearchExperiment.getCounterCurrentCount(), 1)
        BingSearchExperiment.incrementCounter()
        XCTAssertEqual(BingSearchExperiment.getCounterCurrentCount(), 2)
    }
    
    func testMakeBingSearchURLFromURLNotNil() {
        let url = URL(string: "https://google.com/search?q=test")!
        let bingUrl = BingSearchExperiment.makeBingSearchURLFromURL(url)
        XCTAssertNotNil(bingUrl)
    }
    
    func testMakeBingSearchURLFromURL() {
        let sourceURL = URL(string: "https://google.com?q=swift")!
        let expectedURLString = "https://bing.com?q=swift"
        let resultURL = BingSearchExperiment.makeBingSearchURLFromURL(sourceURL)
        XCTAssertEqual(resultURL?.absoluteString, expectedURLString, "URL should be modified to use bing.com")
    }
}
