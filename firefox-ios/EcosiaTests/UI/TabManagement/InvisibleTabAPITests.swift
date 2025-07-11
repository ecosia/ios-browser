// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Client

/// Test suite for InvisibleTabAPI functionality
final class InvisibleTabAPITests: XCTestCase {

    // MARK: - Properties

    private var api: InvisibleTabAPI!
    private var mockTabManager: MockTabManagerForAPI!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create mock tab manager
        mockTabManager = MockTabManagerForAPI()

        // Set up API instance
        api = InvisibleTabAPI.shared
        api.setTabManager(mockTabManager)

        // Configuration is now handled by TabAutoCloseConfig

        // Clean up any existing state
        api.cleanupAllTracking()
    }

    override func tearDown() {
        api.cleanupAllTracking()
        api.setTabManager(nil)
        mockTabManager = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createMockTab(uuid: String = UUID().uuidString, isPrivate: Bool = false) -> Tab {
        let profile = MockProfile()
        let tab = Tab(profile: profile, isPrivate: isPrivate, windowUUID: WindowUUID())
        tab.tabUUID = uuid
        return tab
    }

    // MARK: - Configuration Tests

    func testTabAutoCloseConfig() {
        // Test that configuration values are reasonable
        XCTAssertGreaterThan(TabAutoCloseConfig.fallbackTimeout, 0, "Fallback timeout should be positive")
        XCTAssertGreaterThan(TabAutoCloseConfig.maxConcurrentAutoCloseTabs, 0, "Max concurrent tabs should be positive")
        XCTAssertGreaterThan(TabAutoCloseConfig.debounceInterval, 0, "Debounce interval should be positive")

        // Test specific expected values
        XCTAssertEqual(TabAutoCloseConfig.fallbackTimeout, 10.0, "Default fallback timeout should be 10 seconds")
        XCTAssertEqual(TabAutoCloseConfig.maxConcurrentAutoCloseTabs, 5, "Default max concurrent tabs should be 5")
        XCTAssertEqual(TabAutoCloseConfig.debounceInterval, 0.5, "Default debounce interval should be 0.5 seconds")
    }

    // MARK: - Basic Functionality Tests

    func testMarkTabAsInvisibleWhenEnabled() {
        // Given
        let tab = createMockTab()

        // When
        let result = api.markTabAsInvisible(tab)

        // Then
        XCTAssertTrue(result, "Should successfully mark tab as invisible when enabled")
    }

    func testMarkTabAsInvisibleAlwaysSucceeds() {
        // Given
        let tab = createMockTab()

        // When
        let result = api.markTabAsInvisible(tab)

        // Then
        XCTAssertTrue(result, "Should always succeed to mark tab as invisible")
    }

    func testMarkTabAsVisible() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)

        // When
        let result = api.markTabAsVisible(tab)

        // Then
        XCTAssertTrue(result, "Should successfully mark tab as visible")
    }

    func testMarkingMultipleTabsAsInvisible() {
        // Given
        let testTabs = (0..<3).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs

        // When
        testTabs.forEach { _ = api.markTabAsInvisible($0) }

        // Then
        XCTAssertEqual(api.invisibleTabsCount, 3, "Should track all tabs that are marked as invisible")
    }

    // MARK: - Auto-Close Tests

    func testSetupAutoCloseForInvisibleTab() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)

        // When
        let result = api.setupAutoCloseForTab(tab)

        // Then
        XCTAssertTrue(result, "Should successfully setup auto-close for invisible tab")
        XCTAssertEqual(api.trackedTabsCount, 1, "Should track one tab")
    }

    func testSetupAutoCloseFailsWithoutTabManager() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)
        api.setTabManager(nil)

        // When
        let result = api.setupAutoCloseForTab(tab)

        // Then
        XCTAssertFalse(result, "Should fail when no tab manager is set")
        XCTAssertEqual(api.trackedTabsCount, 0, "Should not track any tabs")

        // Restore tab manager
        api.setTabManager(mockTabManager)
    }

    func testSetupAutoCloseWithCustomTimeout() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)
        let customTimeout: TimeInterval = 60.0

        // When
        let result = api.setupAutoCloseForTab(tab, timeout: customTimeout)

        // Then
        XCTAssertTrue(result, "Should successfully setup auto-close with custom timeout")
        XCTAssertEqual(api.trackedTabsCount, 1, "Should track one tab")
    }

    func testSetupAutoCloseWithCustomNotification() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)
        let customNotification = Notification.Name("CustomAuth")

        // When
        let result = api.setupAutoCloseForTab(tab, on: customNotification)

        // Then
        XCTAssertTrue(result, "Should successfully setup auto-close with custom notification")
        XCTAssertEqual(api.trackedTabsCount, 1, "Should track one tab")
    }

    func testSetupAutoCloseForMultipleTabs() {
        // Given
        let tabs = (0..<2).map { createMockTab(uuid: "tab-\($0)") }
        tabs.forEach { _ = api.markTabAsInvisible($0) }

        // When
        let result = api.setupAutoCloseForTabs(tabs)

        // Then
        XCTAssertTrue(result, "Should successfully setup auto-close for multiple tabs")
        XCTAssertEqual(api.trackedTabsCount, 2, "Should track two tabs")
    }

    // MARK: - Cancel Auto-Close Tests

    func testCancelAutoCloseForTab() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)
        api.setupAutoCloseForTab(tab)
        XCTAssertEqual(api.trackedTabsCount, 1)

        // When
        let result = api.cancelAutoCloseForTab(tab.tabUUID)

        // Then
        XCTAssertTrue(result, "Should successfully cancel auto-close")
        XCTAssertEqual(api.trackedTabsCount, 0, "Should not track any tabs")
    }

    func testCancelAutoCloseForNonExistentTab() {
        // Given
        let tab = createMockTab()

        // When
        let result = api.cancelAutoCloseForTab(tab.tabUUID)

        // Then
        XCTAssertTrue(result, "Should return true even for non-existent tabs")
        XCTAssertEqual(api.trackedTabsCount, 0, "Should not track any tabs")
    }

    // MARK: - Tab Retrieval Tests

    func testGetVisibleAndInvisibleTabs() {
        // Given
        let testTabs = (0..<4).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs

        // Mark first two as invisible
        api.markTabAsInvisible(testTabs[0])
        api.markTabAsInvisible(testTabs[1])

        // When
        let visibleTabs = api.getVisibleTabs()
        let invisibleTabs = api.getInvisibleTabs()

        // Then
        XCTAssertEqual(visibleTabs.count, 2, "Should have 2 visible tabs")
        XCTAssertEqual(invisibleTabs.count, 2, "Should have 2 invisible tabs")
    }

    func testGetInvisibleTabsWhenNoneExist() {
        // Given
        let testTabs = (0..<3).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs

        // When
        let invisibleTabs = api.getInvisibleTabs()

        // Then
        XCTAssertEqual(invisibleTabs.count, 0, "Should have no invisible tabs")
    }

    func testGetVisibleNormalTabs() {
        // Given
        let testTabs = (0..<4).map { createMockTab(uuid: "tab-\($0)", isPrivate: $0 >= 2) }
        mockTabManager.tabs = testTabs

        // Mark first tab as invisible (normal tab)
        api.markTabAsInvisible(testTabs[0])

        // When
        let visibleNormalTabs = api.getVisibleNormalTabs()

        // Then
        XCTAssertEqual(visibleNormalTabs.count, 1, "Should have 1 visible normal tab")
        XCTAssertFalse(visibleNormalTabs[0].isPrivate, "Should be normal tab")
    }

    func testGetVisiblePrivateTabs() {
        // Given
        let testTabs = (0..<4).map { createMockTab(uuid: "tab-\($0)", isPrivate: $0 >= 2) }
        mockTabManager.tabs = testTabs

        // Mark first private tab as invisible
        api.markTabAsInvisible(testTabs[2])

        // When
        let visiblePrivateTabs = api.getVisiblePrivateTabs()

        // Then
        XCTAssertEqual(visiblePrivateTabs.count, 1, "Should have 1 visible private tab")
        XCTAssertTrue(visiblePrivateTabs[0].isPrivate, "Should be private tab")
    }

    // MARK: - Count Tests

    func testTabCounts() {
        // Given
        let testTabs = (0..<3).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs

        // When
        XCTAssertEqual(api.totalTabsCount, 3)
        XCTAssertEqual(api.visibleTabsCount, 3)
        XCTAssertEqual(api.invisibleTabsCount, 0)

        // Mark some as invisible
        api.markTabAsInvisible(testTabs[0])
        api.markTabAsInvisible(testTabs[1])

        // Then
        XCTAssertEqual(api.totalTabsCount, 3)
        XCTAssertEqual(api.visibleTabsCount, 1)
        XCTAssertEqual(api.invisibleTabsCount, 2)
    }

    // MARK: - Authentication Flow Integration Tests

    func testAuthenticationFlowIntegration() {
        // Given
        let authTab = createMockTab(uuid: "auth-tab")

        // When
        let invisibleResult = api.markTabAsInvisible(authTab)
        XCTAssertTrue(invisibleResult)

        let autoCloseResult = api.setupAutoCloseForTab(authTab)
        XCTAssertTrue(autoCloseResult)

        // Simulate authentication completion
        let expectation = XCTestExpectation(description: "Auth completion processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(api.trackedTabsCount, 0, "Should not track any tabs after completion")
    }

    func testTabBecomeVisibleCancelsAutoClose() {
        // Given
        let authTab = createMockTab(uuid: "auth-tab")
        api.markTabAsInvisible(authTab)
        api.setupAutoCloseForTab(authTab)

        // When
        api.markTabAsVisible(authTab)

        // Simulate auth completion (should not affect anything now)
        let expectation = XCTestExpectation(description: "Processing complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        NotificationCenter.default.post(name: .EcosiaAuthDidLoginWithSessionToken, object: nil)
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(api.trackedTabsCount, 0, "Should cleanup tracking")
    }

    // MARK: - Error Handling Tests

    func testOperationsWithoutTabManager() {
        // Given
        api.setTabManager(nil)
        let tab = createMockTab()

        // When
        let result = api.markTabAsInvisible(tab)

        // Then
        XCTAssertTrue(result, "Marking invisible should work without tab manager")

        // When
        let setupResult = api.setupAutoCloseForTab(tab)

        // Then
        XCTAssertFalse(setupResult, "Setup auto-close should fail without tab manager")
        XCTAssertEqual(api.trackedTabsCount, 0, "Should not track any tabs")

        // Restore tab manager
        api.setTabManager(mockTabManager)
    }

    func testNilTabManagerHandling() {
        // When
        api.setTabManager(nil)

        // Then
        let visibleTabs = api.getVisibleTabs()
        let invisibleTabs = api.getInvisibleTabs()

        XCTAssertEqual(visibleTabs.count, 0, "Should return empty array when no tab manager")
        XCTAssertEqual(invisibleTabs.count, 0, "Should return empty array when no tab manager")
    }

    // MARK: - Performance Tests

    func testLargeNumberOfTabs() {
        // Given
        let largeNumberOfTabs = 1000
        let testTabs = (0..<largeNumberOfTabs).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs

        // When
        let startTime = CFAbsoluteTimeGetCurrent()

        testTabs.enumerated().forEach { index, tab in
            if index % 2 == 0 {
                _ = api.markTabAsInvisible(tab)
            }
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime

        // Then
        XCTAssertLessThan(executionTime, 1.0, "Should handle 1000 tabs in under 1 second")
        XCTAssertEqual(api.trackedTabsCount, 0, "Should have no tracked tabs after operations")
        XCTAssertEqual(api.invisibleTabsCount, 500, "Should have no invisible tabs after operations")
    }

    // MARK: - Cleanup Tests

    func testCleanupAllTracking() {
        // Given
        let testTabs = (0..<3).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs
        testTabs.forEach { _ = api.markTabAsInvisible($0) }
        testTabs.forEach { _ = api.setupAutoCloseForTab($0) }
        XCTAssertEqual(api.trackedTabsCount, 3)

        // When
        api.cleanupAllTracking()

        // Then
        XCTAssertEqual(api.trackedTabsCount, 0, "Should cleanup all tracking")
        XCTAssertEqual(api.invisibleTabsCount, 0, "Should cleanup all invisible tabs")
    }

    func testCleanupRemovedTabs() {
        // Given
        let testTabs = (0..<3).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs
        testTabs.forEach { _ = api.markTabAsInvisible($0) }
        testTabs.forEach { _ = api.setupAutoCloseForTab($0) }

        // Simulate tab removal
        mockTabManager.tabs.remove(at: 0)

        // When
        api.cleanupRemovedTabs()

        // Then
        XCTAssertEqual(api.invisibleTabsCount, 2, "Should cleanup removed tab from invisible tracking")
        XCTAssertEqual(api.trackedTabsCount, 2, "Should cleanup removed tab from auto-close tracking")
    }

    // MARK: - Concurrent Operation Tests

    func testConcurrentOperations() {
        // Given
        let testTabs = (0..<10).map { createMockTab(uuid: "tab-\($0)") }
        mockTabManager.tabs = testTabs
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = testTabs.count

        // When
        testTabs.forEach { tab in
            DispatchQueue.global(qos: .background).async {
                let invisibleResult = self.api.markTabAsInvisible(tab)
                XCTAssertTrue(invisibleResult)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // Then
        XCTAssertEqual(api.trackedTabsCount, 0, "Should have no tracked tabs after operations")
        XCTAssertEqual(api.invisibleTabsCount, 10, "Should have no invisible tabs after operations")
    }

    // MARK: - Idempotency Tests

    func testIdempotentInvisibleMarking() {
        // Given
        let tab = createMockTab()
        mockTabManager.tabs = [tab]

        // When
        let result1 = api.markTabAsInvisible(tab)
        let result2 = api.markTabAsInvisible(tab)
        let result3 = api.markTabAsInvisible(tab)

        // Then
        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
        XCTAssertTrue(result3)
        XCTAssertEqual(api.invisibleTabsCount, 1, "Should only count tab once")
    }

    func testIdempotentAutoCloseSetup() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)

        // When
        let result1 = api.setupAutoCloseForTab(tab)
        let result2 = api.setupAutoCloseForTab(tab)
        let result3 = api.setupAutoCloseForTab(tab)

        // Then
        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
        XCTAssertTrue(result3)
        XCTAssertEqual(api.trackedTabsCount, 1, "Should only track tab once")
    }
}

// MARK: - Mock Classes

/// Extended mock tab manager for API testing
private class MockTabManagerForAPI: MockTabManager {
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
        return tabs.filter { !$0.isPrivate && !InvisibleTabManager.shared.isTabInvisible($0) }
    }

    var visibleTabs: [Tab] {
        return tabs.filter { !InvisibleTabManager.shared.isTabInvisible($0) }
    }
}
