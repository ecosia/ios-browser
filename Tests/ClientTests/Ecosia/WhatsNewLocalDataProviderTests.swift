// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Core

final class WhatsNewLocalDataProviderTests: XCTestCase {
    
    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.installTypeKey)
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.currentInstalledVersionKey)
    }
    
    // MARK: - Fresh Install Tests
    
    func testFreshInstallShouldNotShowWhatsNew() {
        // Given
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "1.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Fresh install should not show What's New")
    }
    
    func testFreshInstallShouldNotGetWhatsNewItems() {
        // Given
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "1.0.0"))
        
        // When
        do {
            let whatsNewItems = try dataProvider.getData()
            
            // Then
            XCTAssertTrue(whatsNewItems.isEmpty, "Fresh install should not get What's New items")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Unknown Install Tests
    
    func testUnkownInstallShouldNotShowWhatsNew() {
        // Given
        EcosiaInstallType.set(type: .unknown)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade to the same version should not show What's New")
    }
    
    func testUnknownInstallShouldNotGetWhatsNewItems() {
        // Given
        EcosiaInstallType.set(type: .unknown)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"))
        
        // When
        do {
            let whatsNewItems = try dataProvider.getData()
            
            // Then
            XCTAssertTrue(whatsNewItems.isEmpty, "Upgrade to the same version should not get What's New items")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Upgrade Install Tests
    
    // TODO: Make the test independent of WhatsNewLocalDataProvider.whatsNewItems
    func testUpgradeToVersionWithItemsShouldShowWhatsNew() {
        // Given
        EcosiaInstallType.updateCurrentVersion(version: "8.0.0")
        EcosiaInstallType.set(type: .upgrade)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertTrue(shouldShowWhatsNew, "Upgrade to a different version should show What's New. Got items to be shown: \(User.shared.whatsNewItemsVersionsShown ?? []), for version range: \(dataProvider.getVersionRange().map { $0.description })")
    }
    
    // TODO: In this case ☝️, don't we also need to test `getData()`?
    
    func testUpgradeToLowerVersionShouldNotShowWhatsNew() {
        // Given
        EcosiaInstallType.set(type: .upgrade)
        EcosiaInstallType.updateCurrentVersion(version: "9.0.0")
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "8.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade to a lower version should not show What's New")
    }
    
    // TODO: Is this repetitive with the ☝️?
    func testUpgradeToLowerVersionShouldNotGetWhatsNewItems() {
        // Given
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "8.0.0"))
        
        // When
        do {
            EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: dataProvider.versionProvider)
            let whatsNewItems = try dataProvider.getData()
            
            // Then
            XCTAssertTrue(whatsNewItems.isEmpty, "Upgrade to a lower version should not get What's New items")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
