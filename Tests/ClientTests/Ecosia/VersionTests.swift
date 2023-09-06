// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class VersionTests: XCTestCase {
    
    override class func setUp() {
        UserDefaults.standard.removeObject(forKey: Version.appVersionUpdateKey)
    }
    
    override class func tearDown() {
        UserDefaults.standard.removeObject(forKey: Version.appVersionUpdateKey)
    }

    // Test initialization
    func testInitialization() {
        XCTAssertNotNil(Version("1.0.0"))
        XCTAssertNil(Version("1.0")) // Not a semantic version
        XCTAssertNil(Version("abc")) // Invalid format
    }

    // Test description output
    func testDescription() {
        let version = Version("1.2.3")
        XCTAssertEqual(version?.description, "1.2.3")
    }

    // Test equality
    func testEquality() {
        XCTAssertEqual(Version("1.0.0"), Version("1.0.0"))
        XCTAssertNotEqual(Version("1.0.0"), Version("1.0.1"))
    }

    // Test less-than comparison
    func testComparison() {
        XCTAssertTrue(Version("1.0.0")! < Version("1.0.1")!)
        XCTAssertTrue(Version("1.0.0")! < Version("1.1.0")!)
        XCTAssertTrue(Version("1.0.0")! < Version("2.0.0")!)
    }

    // Test Hashability
    func testHash() {
        XCTAssertEqual(Version("1.0.0")?.hashValue, Version("1.0.0")?.hashValue)
        XCTAssertNotEqual(Version("1.0.0")?.hashValue, Version("1.0.1")?.hashValue)
    }
    
    // Test Version retrieval and saving using UserDefaults
    func testVersionStorage() {
        
        let version1 = Version("1.0.0")
        let version2 = Version("1.0.1")
        
        // Test initial state
        XCTAssertNil(Version.retrievePreviousVersionElseSaveCurrent(nil))
        
        // Test saving and retrieving version
        _ = Version.retrievePreviousVersionElseSaveCurrent(version1)
        XCTAssertEqual(Version.retrievePreviousVersionElseSaveCurrent(version1), version1)
        
        // Test updating and retrieving newer version
        _ = Version.retrievePreviousVersionElseSaveCurrent(version2)
        XCTAssertEqual(Version.retrievePreviousVersionElseSaveCurrent(version2), version2)
    }
    
    func testDoubleDigitVersions() {
        let version1 = Version("10.9.8")
        let version2 = Version("10.10.8")
        let version3 = Version("11.9.8")
        let version4 = Version("11.11.11")

        // Test save and retrieve
        _ = Version.retrievePreviousVersionElseSaveCurrent(version1)
        var retrievedVersion = Version.retrievePreviousVersionElseSaveCurrent(version1)
        XCTAssertEqual(retrievedVersion, version1)

        // Test update and retrieve
        _ = Version.retrievePreviousVersionElseSaveCurrent(version2)
        retrievedVersion = Version.retrievePreviousVersionElseSaveCurrent(version2)
        XCTAssertEqual(retrievedVersion, version2)

        // Test comparability
        XCTAssertTrue(version2! < version3!)
        XCTAssertTrue(version3! < version4!)

        // Test equality
        XCTAssertFalse(version3! == version4!)
    }
}
