// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class VersionTests: XCTestCase {
    
    private static let appVersionUpdateTestKey = "appVersionUpdateTestKey"
    
    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: Self.appVersionUpdateTestKey)
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
        let version1 = Version("1.0.0")!
        let version2 = Version("1.0.1")!

        Version.updateFromCurrent(forKey: Self.appVersionUpdateTestKey,
                                  provider: MockAppVersionInfoProvider(mockedAppVersion: version1.description))
        
        XCTAssertEqual(Version.saved(forKey: Self.appVersionUpdateTestKey)?.description, version1.description)

        Version.updateFromCurrent(forKey: Self.appVersionUpdateTestKey, provider: MockAppVersionInfoProvider(mockedAppVersion: "1.0.1"))
        
        XCTAssertEqual(Version.saved(forKey: Self.appVersionUpdateTestKey)?.description, version2.description)
    }
    
    func testDoubleDigitVersions() {
        let version1 = Version("10.9.8")!
        let version2 = Version("10.10.8")!
        let version3 = Version("11.9.8")!
        let version4 = Version("11.11.11")!

        Version.updateFromCurrent(forKey: Self.appVersionUpdateTestKey, provider: MockAppVersionInfoProvider(mockedAppVersion: version1.description))
        XCTAssertEqual(Version.saved(forKey: Self.appVersionUpdateTestKey)?.description, version1.description)

        Version.updateFromCurrent(forKey: Self.appVersionUpdateTestKey, provider: MockAppVersionInfoProvider(mockedAppVersion: version2.description))
        XCTAssertEqual(Version.saved(forKey: Self.appVersionUpdateTestKey)?.description, version2.description)

        XCTAssertTrue(version2 < version3)
        XCTAssertTrue(version3 < version4)
        XCTAssertFalse(version3 == version4)
    }
}

extension VersionTests {
    
    struct MockAppVersionInfoProvider: AppVersionInfoProvider {
        
        var mockedAppVersion: String
        
        init(mockedAppVersion: String) {
            self.mockedAppVersion = mockedAppVersion
        }
        
        var version: String {
            mockedAppVersion
        }
    }
}