// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Client

final class TabAutoCloseManagerTests: XCTestCase {

    // MARK: - Properties

    private var manager: TabAutoCloseManager!
    private var mockNotificationCenter: MockNotificationCenter!
    private var mockTabManager: MockTabManagerExtended!
    private var testTab: Tab!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        mockNotificationCenter = MockNotificationCenter()
        mockTabManager = MockTabManagerExtended()

        // Create manager with mock dependencies
        manager = TabAutoCloseManager.shared
        manager.setTabManager(mockTabManager)

        testTab = createMockInvisibleTab(uuid: "test-tab-123")

        // Clear any existing state
        manager.cleanupAllObservers()
    }

    override func tearDown() {
        manager.cleanupAllObservers()
        mockTabManager = nil
        mockNotificationCenter = nil
        testTab = nil
        super.tearDown()
    }

    // MARK: - Setup Auto-Close Tests

    func testSetupAutoCloseForInvisibleTab() {
        // Given
        XCTAssertEqual(manager.trackedTabCount, 0)

        // When
        manager.setupAutoCloseForTab(testTab)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 1)
        XCTAssertTrue(manager.trackedTabUUIDs.contains(testTab.tabUUID))
    }

    func testSetupAutoCloseForVisibleTabShouldFail() {
        // Given
        let visibleTab = createMockVisibleTab(uuid: "visible-tab")

        // When
        manager.setupAutoCloseForTab(visibleTab)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should not setup auto-close for visible tabs")
        XCTAssertFalse(manager.trackedTabUUIDs.contains(visibleTab.tabUUID))
    }

    func testSetupAutoCloseForMultipleTabs() {
        // Given
        let tabs = (0..<3).map { createMockInvisibleTab(uuid: "tab-\($0)") }

        // When
        manager.setupAutoCloseForTabs(tabs)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 3)
        tabs.forEach { tab in
            XCTAssertTrue(manager.trackedTabUUIDs.contains(tab.tabUUID))
        }
    }

    func testSetupAutoCloseWithTooManyTabs() {
        // Given
        let maxTabs = TabAutoCloseConfig.maxConcurrentAutoCloseTabs
        let tooManyTabs = (0..<(maxTabs + 1)).map { createMockInvisibleTab(uuid: "tab-\($0)") }

        // When
        manager.setupAutoCloseForTabs(tooManyTabs)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Should reject too many concurrent tabs")
    }

    func testSetupAutoCloseWithCustomNotification() {
        // Given
        let customNotification = Notification.Name("CustomAuthCompletion")

        // When
        manager.setupAutoCloseForTab(testTab, on: customNotification)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 1)
        XCTAssertTrue(manager.trackedTabUUIDs.contains(testTab.tabUUID))
    }

    func testSetupAutoCloseWithCustomTimeout() {
        // Given
        let customTimeout: TimeInterval = 5.0

        // When
        manager.setupAutoCloseForTab(testTab, timeout: customTimeout)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 1)
        // Note: Testing the actual timeout would require waiting or mocking timers
    }

    // MARK: - Notification Handling Tests

    func testAuthenticationCompletionNotificationTriggersClose() {
        // Given
        manager.setupAutoCloseForTab(testTab)
        mockTabManager.tabs = [testTab]
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track the tab initially")

        // When
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)

        // Then
        // Wait a bit for async operations
        let expectation = XCTestExpectation(description: "Tab close completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(manager.trackedTabCount, 0, "Tab should be removed from tracking after close")
        XCTAssertTrue(mockTabManager.removedTabs.contains { $0.tabUUID == self.testTab.tabUUID })
    }

    func testFallbackTimeoutTriggersClose() {
        // Given
        let shortTimeout: TimeInterval = 0.1
        manager.setupAutoCloseForTab(testTab, timeout: shortTimeout)
        mockTabManager.tabs = [testTab]

        // When - Wait for timeout to trigger
        let expectation = XCTestExpectation(description: "Fallback timeout triggers")
        DispatchQueue.main.asyncAfter(deadline: .now() + shortTimeout + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Tab should be removed after timeout")
        XCTAssertTrue(mockTabManager.removedTabs.contains { $0.tabUUID == self.testTab.tabUUID })
    }

    func testNotificationBeforeTimeoutPreventsTimeout() {
        // Given
        let longTimeout: TimeInterval = 1.0
        manager.setupAutoCloseForTab(testTab, timeout: longTimeout)
        mockTabManager.tabs = [testTab]

        // When - Trigger notification before timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)
        }

        // Wait for notification to be processed
        let expectation = XCTestExpectation(description: "Notification processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0, "Tab should be closed by notification")
        XCTAssertTrue(mockTabManager.removedTabs.contains { $0.tabUUID == self.testTab.tabUUID })

        // Wait longer to ensure timeout doesn't fire
        let timeoutExpectation = XCTestExpectation(description: "Timeout period passed")
        DispatchQueue.main.asyncAfter(deadline: .now() + longTimeout + 0.1) {
            timeoutExpectation.fulfill()
        }
        wait(for: [timeoutExpectation], timeout: 2.0)

        // Should still only be closed once
        let closedTabsCount = mockTabManager.removedTabs.filter { $0.tabUUID == testTab.tabUUID }.count
        XCTAssertEqual(closedTabsCount, 1, "Tab should only be closed once, not by both notification and timeout")
    }

    // MARK: - Tab Removal Tests

    func testTabRemovedWhenStillInvisible() {
        // Given
        manager.setupAutoCloseForTab(testTab)
        mockTabManager.tabs = [testTab]
        XCTAssertTrue(testTab.isInvisible, "Tab should be invisible")
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track the tab initially")

        // When
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)

        // Wait for processing
        let expectation = XCTestExpectation(description: "Processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(mockTabManager.removedTabs.contains { $0.tabUUID == self.testTab.tabUUID })
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking after close")
    }

    func testTabNotRemovedWhenBecameVisible() {
        // Given
        manager.setupAutoCloseForTab(testTab)
        mockTabManager.tabs = [testTab]
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track the tab initially")

        // Make tab visible before notification
        testTab.isInvisible = false

        // When
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)

        // Wait for processing
        let expectation = XCTestExpectation(description: "Processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertFalse(mockTabManager.removedTabs.contains { $0.tabUUID == self.testTab.tabUUID },
                      "Should not remove tab that became visible")
        XCTAssertEqual(manager.trackedTabCount, 0, "Should still cleanup tracking")
    }

    func testTabNotFoundDoesntCrash() {
        // Given
        manager.setupAutoCloseForTab(testTab)
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track the tab initially")
        mockTabManager.tabs = [] // Tab doesn't exist in manager

        // When
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)

        // Wait for processing
        let expectation = XCTestExpectation(description: "Processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then - Should not crash and should cleanup tracking
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking even when tab not found")
    }

    // MARK: - Cancel Auto-Close Tests

    func testCancelAutoCloseForTab() {
        // Given
        manager.setupAutoCloseForTab(testTab)
        XCTAssertEqual(manager.trackedTabCount, 1)

        // When
        manager.cancelAutoCloseForTab(testTab.tabUUID)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0)
        XCTAssertFalse(manager.trackedTabUUIDs.contains(testTab.tabUUID))
    }

    func testCancelAutoCloseForMultipleTabs() {
        // Given
        let tabs = (0..<3).map { createMockInvisibleTab(uuid: "tab-\($0)") }
        manager.setupAutoCloseForTabs(tabs)
        XCTAssertEqual(manager.trackedTabCount, 3)

        // When
        let tabUUIDs = tabs.map { $0.tabUUID }
        manager.cancelAutoCloseForTabs(tabUUIDs)

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0)
        tabs.forEach { tab in
            XCTAssertFalse(manager.trackedTabUUIDs.contains(tab.tabUUID))
        }
    }

    func testCancelNonExistentTab() {
        // Given
        let nonExistentUUID = "non-existent-tab"

        // When/Then - Should not crash
        manager.cancelAutoCloseForTab(nonExistentUUID)
        XCTAssertEqual(manager.trackedTabCount, 0)
    }

    // MARK: - Cleanup Tests

    func testCleanupAllObservers() {
        // Given
        let tabs = (0..<5).map { createMockInvisibleTab(uuid: "tab-\($0)") }
        manager.setupAutoCloseForTabs(tabs)
        XCTAssertEqual(manager.trackedTabCount, 5)

        // When
        manager.cleanupAllObservers()

        // Then
        XCTAssertEqual(manager.trackedTabCount, 0)
        tabs.forEach { tab in
            XCTAssertFalse(manager.trackedTabUUIDs.contains(tab.tabUUID))
        }
    }

    func testRepeatedSetupForSameTab() {
        // Given
        manager.setupAutoCloseForTab(testTab)
        XCTAssertEqual(manager.trackedTabCount, 1)

        // When - Setup again for same tab
        manager.setupAutoCloseForTab(testTab)

        // Then - Should cleanup previous and setup new
        XCTAssertEqual(manager.trackedTabCount, 1, "Should still track only one instance")
        XCTAssertTrue(manager.trackedTabUUIDs.contains(testTab.tabUUID))
    }

    // MARK: - Tab Selection Tests

    func testTabSelectionAfterRemoval() {
        // Given
        let tab1 = createMockInvisibleTab(uuid: "tab-1")
        let tab2 = createMockVisibleTab(uuid: "tab-2")
        let tab3 = createMockVisibleTab(uuid: "tab-3")

        mockTabManager.tabs = [tab1, tab2, tab3]
        mockTabManager.selectedTab = nil
        manager.setupAutoCloseForTab(tab1)
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track the tab initially")

        // When
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)

        // Wait for processing
        let expectation = XCTestExpectation(description: "Processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(mockTabManager.removedTabs.contains { $0.tabUUID == tab1.tabUUID })
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking after close")
        // Note: Tab selection behavior depends on TabAutoCloseManager implementation
        // The mock may or may not select a tab, so we just verify the tab was removed
    }

    // MARK: - Configuration Tests

    func testTabAutoCloseConfig() {
        // Test that configuration values are reasonable
        XCTAssertGreaterThan(TabAutoCloseConfig.fallbackTimeout, 0)
        XCTAssertGreaterThan(TabAutoCloseConfig.maxConcurrentAutoCloseTabs, 0)
        XCTAssertGreaterThan(TabAutoCloseConfig.debounceInterval, 0)

        // Test specific expected values
        XCTAssertEqual(TabAutoCloseConfig.fallbackTimeout, 10.0)
        XCTAssertEqual(TabAutoCloseConfig.maxConcurrentAutoCloseTabs, 5)
        XCTAssertEqual(TabAutoCloseConfig.debounceInterval, 0.5)
    }

    // MARK: - Edge Cases

    func testMultipleNotificationsForSameTab() {
        // Given
        manager.setupAutoCloseForTab(testTab)
        mockTabManager.tabs = [testTab]
        XCTAssertEqual(manager.trackedTabCount, 1, "Should track the tab initially")

        // When - Post multiple notifications quickly
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)
        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)

        // Wait for processing
        let expectation = XCTestExpectation(description: "Processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then - Should only close once
        let closedTabsCount = mockTabManager.removedTabs.filter { $0.tabUUID == testTab.tabUUID }.count
        XCTAssertEqual(closedTabsCount, 1, "Tab should only be closed once despite multiple notifications")
        XCTAssertEqual(manager.trackedTabCount, 0, "Should cleanup tracking after close")
    }

    // MARK: - Helper Methods

    private func createMockInvisibleTab(uuid: String) -> Tab {
        let tab = createMockTab(uuid: uuid)
        tab.isInvisible = true
        return tab
    }

    private func createMockVisibleTab(uuid: String) -> Tab {
        let tab = createMockTab(uuid: uuid)
        tab.isInvisible = false
        return tab
    }

    private func createMockTab(uuid: String) -> Tab {
        let profile = MockProfile()
        let tab = Tab(profile: profile, isPrivate: false, windowUUID: WindowUUID())
        tab.tabUUID = uuid
        return tab
    }
}

// MARK: - Mock Classes

private class MockNotificationCenter: NotificationCenter {
    var postedNotifications: [(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?)] = []

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        postedNotifications.append((name: aName, object: anObject, userInfo: aUserInfo))
        super.post(name: aName, object: anObject, userInfo: aUserInfo)
    }
}

// MARK: - Mock TabManager Extension

private class MockTabManagerExtended: MockTabManager {
    var removedTabs: [Tab] = []

    override func removeTab(_ tab: Tab, completion: (() -> Void)? = nil) {
        removedTabs.append(tab)
        if let index = tabs.firstIndex(of: tab) {
            tabs.remove(at: index)
        }
        completion?()
    }

    func cleanupInvisibleTabTracking() {
        // Mock implementation for invisible tab tracking cleanup
    }

    var visibleNormalTabs: [Tab] {
        return tabs.filter { !$0.isPrivate && !$0.isInvisible }
    }

    var visibleTabs: [Tab] {
        return tabs.filter { !$0.isInvisible }
    }
}
