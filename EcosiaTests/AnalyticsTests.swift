// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import XCTest
@testable import Client

final class AnalyticsTests: XCTestCase {
    
    override func setUpWithError() throws {
        let defaults = UserDefaults.standard
        // Remove any saved dates from UserDefaults before each test
        defaults.removeObject(forKey: "testIdentifier")
    }

    func testFirstCheck() throws {
        // The first check should always return true since it sets the date for the first time
        XCTAssertTrue(Analytics.hasDayPassedSinceLastCheck(for: "testIdentifier"))
    }

    func testCheckWithinADay() throws {        
        //Given
        let defaults = UserDefaults.standard
        
        //When
        defaults.set(Date(), forKey: "testIdentifier")
        
        //Then
        XCTAssertFalse(Analytics.hasDayPassedSinceLastCheck(for: "testIdentifier"))
    }

    func testCheckAfterADay() throws {
        //Given
        let defaults = UserDefaults.standard
        let moreThanADayAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        
        //When
        defaults.set(moreThanADayAgo, forKey: "testIdentifier")
        
        //Then
        XCTAssertTrue(Analytics.hasDayPassedSinceLastCheck(for: "testIdentifier"))
    }
}
