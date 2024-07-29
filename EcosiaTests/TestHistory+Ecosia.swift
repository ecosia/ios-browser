// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import Foundation
import Storage

extension TestHistory {

    fileprivate func addSites(_ places: RustPlaces, count: Int) {
        for index in 0..<count {
            self.addSite(places, url: "https://example\(index).com/", title: "Title \(index)")
        }
    }

    // Function to test getSitesWithBound performance
    fileprivate func testGetSitesWithBoundPerformance(limit: Int, entries: Int) {
        withTestProfile { profile in
            let places = profile.places
            
            // Add the specified number of sites
            self.addSites(places, count: entries)

            self.measure {
                let expectation = self.expectation(description: "getSitesWithBound completes")

                let startTime = Date()
                
                let deferred = places.getSitesWithBound(limit: limit, offset: 0, excludedTypes: VisitTransitionSet(0))
                deferred.upon { cursorResult in
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds
                    
                    switch cursorResult {
                    case .success(let cursor):
                        XCTAssertGreaterThan(cursor.count, 0, "No sites were retrieved")
                        print("Execution time: \(duration) ms")
                    case .failure(let error):
                        XCTFail("Failed to retrieve sites: \(error)")
                    }
                    
                    expectation.fulfill()
                }

                self.waitForExpectations(timeout: 10.0, handler: nil)
            }

            self.clear(places)
        }
    }

    // Tests for each row in the table
    func testGetSitesWithBoundPerformance_Limit100_500Entries() {
        testGetSitesWithBoundPerformance(limit: 100, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit400_500Entries() {
        testGetSitesWithBoundPerformance(limit: 400, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit600_500Entries() {
        testGetSitesWithBoundPerformance(limit: 600, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit1000_500Entries() {
        testGetSitesWithBoundPerformance(limit: 1000, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit100_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 100, entries: 1000)
    }

    func testGetSitesWithBoundPerformance_Limit400_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 400, entries: 1000)
    }

    func testGetSitesWithBoundPerformance_Limit600_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 600, entries: 1000)
    }

    func testGetSitesWithBoundPerformance_Limit1000_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 1000, entries: 1000)
    }
}
