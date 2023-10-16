// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Core

final class EcosiaInstallTypeTests: XCTestCase {
    
    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.installTypeKey)
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.currentInstalledVersionKey)
    }
    
    func testGetInstallType_WhenUnknown_ShouldReturnUnknown() {
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .unknown)
    }
    
    func testSetInstallType_ShouldPersistType() {
        EcosiaInstallType.set(type: .fresh)
        let persistedType = EcosiaInstallType.get()
        XCTAssertEqual(persistedType, .fresh)
    }
    
    func testPersistedCurrentVersion_WhenNotSet_ShouldReturnEmptyString() {
        let version = EcosiaInstallType.persistedCurrentVersion()
        XCTAssertEqual(version, "")
    }
    
    func testUpdateCurrentVersion_ShouldPersistVersion() {
        let testVersion = "1.0.0"
        EcosiaInstallType.updateCurrentVersion(version: testVersion)
        let persistedVersion = EcosiaInstallType.persistedCurrentVersion()
        XCTAssertEqual(persistedVersion, testVersion)
    }
    
    func testEvaluateCurrentEcosiaInstallType_WhenUnknown_ShouldSetToFresh() {
        User.shared.firstTime = true
        let mockVersion = MockAppVersion(version: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: mockVersion)
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .fresh)
    }

    func testEvaluateCurrentEcosiaInstallType_WhenVersionDiffers_ShouldSetToUpgrade() {
        let mockVersion = MockAppVersion(version: "1.0.0")
        EcosiaInstallType.set(type: .fresh)
        EcosiaInstallType.updateCurrentVersion(version: "0.9.0")
        
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: mockVersion)
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .upgrade)
    }

    func testEvaluateCurrentEcosiaInstallType_WhenVersionSame_ShouldNotChangeType() {
        let mockVersion = MockAppVersion(version: "1.0.0")
        EcosiaInstallType.set(type: .fresh)
        EcosiaInstallType.updateCurrentVersion(version: "1.0.0")
        
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: mockVersion)
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .fresh)
    }
}

extension EcosiaInstallTypeTests {
    
    // Test evaluating install type and version for a fresh install with firstTime=true
    func testEvaluateFreshInstallType_WithFirstTime_And_VersionProvider() {
        User.shared.firstTime = true
        let versionProvider = MockAppVersionInfoProvider(mockedAppVersion: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: versionProvider)
        
        XCTAssertEqual(EcosiaInstallType.get(), .fresh)
        XCTAssertEqual(EcosiaInstallType.persistedCurrentVersion(), "1.0.0")
    }

    // Test evaluating install type and version for an upgrade with firstTime=true
    func testEvaluateUpgradeInstallType_WithFirstTimeFalse_And_VersionProvider() {
        User.shared.firstTime = false
        UserDefaults.standard.set("0.9.0", forKey: EcosiaInstallType.currentInstalledVersionKey)
        
        let versionProvider = MockAppVersionInfoProvider(mockedAppVersion: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: versionProvider)
        
        XCTAssertEqual(EcosiaInstallType.get(), .upgrade)
        XCTAssertEqual(EcosiaInstallType.persistedCurrentVersion(), "1.0.0")
    }
}

extension EcosiaInstallTypeTests {
    struct MockAppVersion: AppVersionInfoProvider {
        var version: String
    }
}
