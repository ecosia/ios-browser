// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Core

final class WhatsNewLocalDataProviderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        try? FileManager().removeItem(at: FileManager.user)
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
    
    // MARK: - Upgrade Tests
    
    func testUpgradeToDifferentVersionShouldShowWhatsNew() {
        // Given
        User.shared.firstTime = false
        UserDefaults.standard.set("8.3.0", forKey: EcosiaInstallType.currentInstalledVersionKey)

        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "10.0.0"))
        
        // When
        EcosiaInstallType.evaluateCurrentEcosiaInstallTypeWithVersionProvider(dataProvider.versionProvider)
        // and
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertEqual(EcosiaInstallType.get(), .upgrade)
        XCTAssertTrue(shouldShowWhatsNew, "Upgrade to a different version should show What's New. Got items to be shown: \(User.shared.whatsNewItemsVersionsShown), for version range: \(dataProvider.getVersionRange().map { $0.description })")
    }
        
    func testUpgradeToSameVersionShouldNotShowWhatsNew() {
        // Given
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade to the same version should not show What's New")
    }
    
    func testUpgradeToSameVersionShouldNotGetWhatsNewItems() {
        // Given
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
    
    func testUpgradeToLowerVersionShouldNotShowWhatsNew() {
        // Given
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "8.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade to a lower version should not show What's New")
    }
    
    func testUpgradeToLowerVersionShouldNotGetWhatsNewItems() {
        // Given
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "8.0.0"))
        
        // When
        do {
            let whatsNewItems = try dataProvider.getData()
            
            // Then
            XCTAssertTrue(whatsNewItems.isEmpty, "Upgrade to a lower version should not get What's New items")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
