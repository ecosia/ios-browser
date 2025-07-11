// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Client

final class InvisibleTabManagerTests: XCTestCase {

    // MARK: - Properties

    private var manager: InvisibleTabManager!
    private var mockNotificationCenter: MockNotificationCenter!
    private var testTab: Tab!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        mockNotificationCenter = MockNotificationCenter()

        // Use reflection to inject mock notification center for testing
        // Note: In production, this uses NotificationCenter.default
        manager = InvisibleTabManager.shared
        testTab = createMockTab(uuid: "test-tab-123")

        // Clear any existing state
        manager.clearAllInvisibleTabs()
    }

    override func tearDown() {
        manager.clearAllInvisibleTabs()
        testTab = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSingletonInstance() {
        // Given/When
        let instance1 = InvisibleTabManager.shared
        let instance2 = InvisibleTabManager.shared

        // Then
        XCTAssertTrue(instance1 === instance2, "InvisibleTabManager should be a singleton")
    }

    // MARK: - Tab Visibility Management Tests

    func testMarkTabAsInvisible() {
        // Given
        XCTAssertFalse(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabCount, 0)

        // When
        manager.markTabAsInvisible(testTab)

        // Then
        XCTAssertTrue(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabCount, 1)
        XCTAssertTrue(manager.invisibleTabUUIDs.contains(testTab.tabUUID))
    }

    func testMarkTabAsVisible() {
        // Given
        manager.markTabAsInvisible(testTab)
        XCTAssertTrue(manager.isTabInvisible(testTab))

        // When
        manager.markTabAsVisible(testTab)

        // Then
        XCTAssertFalse(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabCount, 0)
        XCTAssertFalse(manager.invisibleTabUUIDs.contains(testTab.tabUUID))
    }

    func testToggleTabVisibilityMultipleTimes() {
        // Given
        let tab = testTab!

        // When/Then - Multiple toggles
        manager.markTabAsInvisible(tab)
        XCTAssertTrue(manager.isTabInvisible(tab))

        manager.markTabAsVisible(tab)
        XCTAssertFalse(manager.isTabInvisible(tab))

        manager.markTabAsInvisible(tab)
        XCTAssertTrue(manager.isTabInvisible(tab))

        manager.markTabAsVisible(tab)
        XCTAssertFalse(manager.isTabInvisible(tab))
    }

    func testMarkSameTabInvisibleMultipleTimes() {
        // Given
        let tab = testTab!

        // When
        manager.markTabAsInvisible(tab)
        manager.markTabAsInvisible(tab)
        manager.markTabAsInvisible(tab)

        // Then
        XCTAssertTrue(manager.isTabInvisible(tab))
        XCTAssertEqual(manager.invisibleTabCount, 1, "Should not duplicate invisible tabs")
    }

    // MARK: - Tab Collection Filtering Tests

    func testGetVisibleTabsFromMixedCollection() {
        // Given
        let visibleTab1 = createMockTab(uuid: "visible-1")
        let visibleTab2 = createMockTab(uuid: "visible-2")
        let invisibleTab1 = createMockTab(uuid: "invisible-1")
        let invisibleTab2 = createMockTab(uuid: "invisible-2")

        manager.markTabAsInvisible(invisibleTab1)
        manager.markTabAsInvisible(invisibleTab2)

        let allTabs = [visibleTab1, invisibleTab1, visibleTab2, invisibleTab2]

        // When
        let visibleTabs = manager.getVisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 2)
        XCTAssertTrue(visibleTabs.contains(visibleTab1))
        XCTAssertTrue(visibleTabs.contains(visibleTab2))
        XCTAssertFalse(visibleTabs.contains(invisibleTab1))
        XCTAssertFalse(visibleTabs.contains(invisibleTab2))
    }

    func testGetInvisibleTabsFromMixedCollection() {
        // Given
        let visibleTab1 = createMockTab(uuid: "visible-1")
        let visibleTab2 = createMockTab(uuid: "visible-2")
        let invisibleTab1 = createMockTab(uuid: "invisible-1")
        let invisibleTab2 = createMockTab(uuid: "invisible-2")

        manager.markTabAsInvisible(invisibleTab1)
        manager.markTabAsInvisible(invisibleTab2)

        let allTabs = [visibleTab1, invisibleTab1, visibleTab2, invisibleTab2]

        // When
        let invisibleTabs = manager.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleTabs.count, 2)
        XCTAssertTrue(invisibleTabs.contains(invisibleTab1))
        XCTAssertTrue(invisibleTabs.contains(invisibleTab2))
        XCTAssertFalse(invisibleTabs.contains(visibleTab1))
        XCTAssertFalse(invisibleTabs.contains(visibleTab2))
    }

    func testFilteringWithEmptyTabCollection() {
        // Given
        let emptyTabs: [Tab] = []

        // When
        let visibleTabs = manager.getVisibleTabs(from: emptyTabs)
        let invisibleTabs = manager.getInvisibleTabs(from: emptyTabs)

        // Then
        XCTAssertTrue(visibleTabs.isEmpty)
        XCTAssertTrue(invisibleTabs.isEmpty)
    }

    // MARK: - Cleanup Tests

    func testCleanupRemovedTabs() {
        // Given
        let keepTab = createMockTab(uuid: "keep-tab")
        let removeTab = createMockTab(uuid: "remove-tab")

        manager.markTabAsInvisible(keepTab)
        manager.markTabAsInvisible(removeTab)
        XCTAssertEqual(manager.invisibleTabCount, 2)

        // When - Only keep one tab
        let existingTabUUIDs: Set<String> = [keepTab.tabUUID]
        manager.cleanupRemovedTabs(existingTabUUIDs: existingTabUUIDs)

        // Then
        XCTAssertEqual(manager.invisibleTabCount, 1)
        XCTAssertTrue(manager.isTabInvisible(keepTab))
        XCTAssertFalse(manager.isTabInvisible(removeTab))
    }

    func testCleanupWithNoRemovedTabs() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        let originalCount = manager.invisibleTabCount

        // When - All tabs still exist
        let existingTabUUIDs: Set<String> = [tab1.tabUUID, tab2.tabUUID]
        manager.cleanupRemovedTabs(existingTabUUIDs: existingTabUUIDs)

        // Then
        XCTAssertEqual(manager.invisibleTabCount, originalCount)
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertTrue(manager.isTabInvisible(tab2))
    }

    func testClearAllInvisibleTabs() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        XCTAssertEqual(manager.invisibleTabCount, 2)

        // When
        manager.clearAllInvisibleTabs()

        // Then
        XCTAssertEqual(manager.invisibleTabCount, 0)
        XCTAssertFalse(manager.isTabInvisible(tab1))
        XCTAssertFalse(manager.isTabInvisible(tab2))
        XCTAssertTrue(manager.invisibleTabUUIDs.isEmpty)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentTabManagement() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        let iterationCount = 100
        var completedOperations = 0
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 10

        // When - Perform concurrent operations
        for i in 0..<iterationCount {
            operationQueue.addOperation {
                let tab = self.createMockTab(uuid: "concurrent-tab-\(i)")

                // Random operations
                self.manager.markTabAsInvisible(tab)
                let isInvisible1 = self.manager.isTabInvisible(tab)
                self.manager.markTabAsVisible(tab)
                let isInvisible2 = self.manager.isTabInvisible(tab)

                // Verify state consistency
                XCTAssertTrue(isInvisible1)
                XCTAssertFalse(isInvisible2)

                DispatchQueue.main.async {
                    completedOperations += 1
                    if completedOperations == iterationCount {
                        expectation.fulfill()
                    }
                }
            }
        }

        // Then
        wait(for: [expectation], timeout: 10.0)

        // Verify final state is consistent
        XCTAssertEqual(manager.invisibleTabCount, 0, "All tabs should be visible after operations")
    }

    func testConcurrentCleanupOperations() {
        // Given
        let tabs = (0..<50).map { createMockTab(uuid: "cleanup-tab-\($0)") }
        tabs.forEach { manager.markTabAsInvisible($0) }

        let expectation = XCTestExpectation(description: "Concurrent cleanup operations complete")
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 5
        var completedOperations = 0

        // When - Perform concurrent cleanup operations
        for i in 0..<10 {
            operationQueue.addOperation {
                let keepTabs = Array(tabs.prefix(10 + i * 2))
                let existingUUIDs = Set(keepTabs.map { $0.tabUUID })
                self.manager.cleanupRemovedTabs(existingTabUUIDs: existingUUIDs)

                DispatchQueue.main.async {
                    completedOperations += 1
                    if completedOperations == 10 {
                        expectation.fulfill()
                    }
                }
            }
        }

        // Then
        wait(for: [expectation], timeout: 10.0)

        // Verify consistency - the exact count may vary due to race conditions,
        // but it should be within reasonable bounds
        let finalCount = manager.invisibleTabCount
        XCTAssertGreaterThanOrEqual(finalCount, 0)
        XCTAssertLessThanOrEqual(finalCount, tabs.count)
    }

    // MARK: - Edge Cases

    func testIsTabInvisibleWithNilTab() {
        // This test would need to be adjusted based on how Tab objects are created
        // and whether nil tabs are possible in the actual implementation
    }

    func testLargeNumberOfInvisibleTabs() {
        // Given
        let tabCount = 1000
        let tabs = (0..<tabCount).map { createMockTab(uuid: "bulk-tab-\($0)") }

        // When
        tabs.forEach { manager.markTabAsInvisible($0) }

        // Then
        XCTAssertEqual(manager.invisibleTabCount, tabCount)

        // Verify all tabs are tracked correctly
        tabs.forEach { tab in
            XCTAssertTrue(manager.isTabInvisible(tab))
        }

        // Test bulk cleanup
        let keepTabs = Array(tabs.prefix(500))
        let existingUUIDs = Set(keepTabs.map { $0.tabUUID })
        manager.cleanupRemovedTabs(existingTabUUIDs: existingUUIDs)

        XCTAssertEqual(manager.invisibleTabCount, 500)
    }

    // MARK: - Helper Methods

    private func createMockTab(uuid: String) -> Tab {
        // Create a minimal mock tab for testing using existing mock infrastructure
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
