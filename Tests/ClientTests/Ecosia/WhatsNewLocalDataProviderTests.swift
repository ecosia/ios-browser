// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Core

// This tests are dependant on WhatsNewLocalDataProvider.whatsNewItems hardcoded implementation
final class WhatsNewLocalDataProviderTests: XCTestCase {
    
    override func setUpWithError() throws {
        User.shared.whatsNewItemsVersionsShown = []
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.installTypeKey)
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.currentInstalledVersionKey)
    }
    
    // MARK: Fresh Install Tests
    func testFreshInstallShouldNotShowWhatsNewAndMarkPreviousVersionsAsSeen() {
        // Given
        EcosiaInstallType.set(type: .fresh)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.2"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Fresh install should not show what's new")
        XCTAssertEqual(User.shared.whatsNewItemsVersionsShown, ["9.0.0"])
    }
    
    // MARK: Unknown Install Tests
    func testUnkownInstallShouldNotShowWhatsNewAndMarkPreviousVersionsAsSeen() {
        // Given
        EcosiaInstallType.set(type: .unknown)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "1.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Unknown install should not show what's new")
        XCTAssertEqual(User.shared.whatsNewItemsVersionsShown, [], "No previous versions shoul be marked since 1.0.0 < 9.0.0")
    }
    
    // MARK: Upgrade Install Tests
    func testUpgradeToVersionWithItemsShouldShowWhatsNew() {
        // Given
        EcosiaInstallType.updateCurrentVersion(version: "8.0.0")
        EcosiaInstallType.set(type: .upgrade)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertTrue(shouldShowWhatsNew, "Upgrade to a version with items should show whats new")
    }
    
    func testUpgradeToVersionWithoutItemsShouldNotShowWhatsNew() {
        // Given
        EcosiaInstallType.updateCurrentVersion(version: "8.2.1")
        EcosiaInstallType.set(type: .upgrade)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "8.3.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade to a version without items should not show whats new")
    }
    
    func testDowngradeShouldNotShowWhatsNew() {
        // Given
        User.shared.whatsNewItemsVersionsShown = ["9.0.0"]
        EcosiaInstallType.set(type: .upgrade)
        EcosiaInstallType.updateCurrentVersion(version: "9.3.0")
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Downgrade should not show what's new")
    }
    
    func testUpgradeToGreaterVersionThanTheOneWithItemsShouldShowWhatsNew() {
        // Given
        EcosiaInstallType.set(type: .upgrade)
        EcosiaInstallType.updateCurrentVersion(version: "8.0.0")
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.2"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertTrue(shouldShowWhatsNew, "Upgrade to greater version than the one with items should show what's new")
    }
    
    func testUpgradeWithAlreadyShownItemsShouldNotShow() {
        // Given
        User.shared.whatsNewItemsVersionsShown = ["9.0.0"]
        EcosiaInstallType.set(type: .upgrade)
        EcosiaInstallType.updateCurrentVersion(version: "8.0.0")
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.2"))
        
        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage
        
        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade with already shown items should show not show what's new")
    }
}
