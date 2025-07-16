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
    private var mockNotificationCenter: InvisibleTabManagerMockNotificationCenter!
    private var testTab: Tab!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        mockNotificationCenter = InvisibleTabManagerMockNotificationCenter()

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
        XCTAssertEqual(manager.invisibleTabCount, 1)

        // When
        manager.markTabAsVisible(testTab)

        // Then
        XCTAssertFalse(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabCount, 0)
        XCTAssertFalse(manager.invisibleTabUUIDs.contains(testTab.tabUUID))
    }

    func testMarkSameTabAsInvisibleMultipleTimes() {
        // Given
        XCTAssertFalse(manager.isTabInvisible(testTab))

        // When
        manager.markTabAsInvisible(testTab)
        manager.markTabAsInvisible(testTab)
        manager.markTabAsInvisible(testTab)

        // Then
        XCTAssertTrue(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabCount, 1, "Should only count the tab once")
    }

    func testMarkVisibleTabAsVisible() {
        // Given
        XCTAssertFalse(manager.isTabInvisible(testTab))

        // When
        manager.markTabAsVisible(testTab)

        // Then
        XCTAssertFalse(manager.isTabInvisible(testTab))
        XCTAssertEqual(manager.invisibleTabCount, 0)
    }

    // MARK: - Multiple Tab Tests

    func testMultipleTabsInvisible() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")

        // When
        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        manager.markTabAsInvisible(tab3)

        // Then
        XCTAssertEqual(manager.invisibleTabCount, 3)
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertTrue(manager.isTabInvisible(tab2))
        XCTAssertTrue(manager.isTabInvisible(tab3))
    }

    func testMixedVisibilityTabs() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")

        // When
        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab3)
        // tab2 remains visible

        // Then
        XCTAssertEqual(manager.invisibleTabCount, 2)
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertFalse(manager.isTabInvisible(tab2))
        XCTAssertTrue(manager.isTabInvisible(tab3))
    }

    // MARK: - Tab Filtering Tests

    func testGetVisibleTabsFromArray() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")
        let allTabs = [tab1, tab2, tab3]

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab3)

        // When
        let visibleTabs = manager.getVisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 1)
        XCTAssertTrue(visibleTabs.contains(tab2))
        XCTAssertFalse(visibleTabs.contains(tab1))
        XCTAssertFalse(visibleTabs.contains(tab3))
    }

    func testGetInvisibleTabsFromArray() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")
        let allTabs = [tab1, tab2, tab3]

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab3)

        // When
        let invisibleTabs = manager.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleTabs.count, 2)
        XCTAssertTrue(invisibleTabs.contains(tab1))
        XCTAssertFalse(invisibleTabs.contains(tab2))
        XCTAssertTrue(invisibleTabs.contains(tab3))
    }

    func testGetVisibleTabsWhenAllVisible() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")
        let allTabs = [tab1, tab2, tab3]

        // When
        let visibleTabs = manager.getVisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 3)
        XCTAssertEqual(visibleTabs, allTabs)
    }

    func testGetInvisibleTabsWhenAllVisible() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")
        let allTabs = [tab1, tab2, tab3]

        // When
        let invisibleTabs = manager.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleTabs.count, 0)
    }

    func testGetVisibleTabsWhenAllInvisible() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")
        let allTabs = [tab1, tab2, tab3]

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        manager.markTabAsInvisible(tab3)

        // When
        let visibleTabs = manager.getVisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 0)
    }

    func testGetInvisibleTabsWhenAllInvisible() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")
        let allTabs = [tab1, tab2, tab3]

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        manager.markTabAsInvisible(tab3)

        // When
        let invisibleTabs = manager.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleTabs.count, 3)
        XCTAssertEqual(Set(invisibleTabs), Set(allTabs))
    }

    // MARK: - Tab Count Tests

    func testInvisibleTabCount() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")

        XCTAssertEqual(manager.invisibleTabCount, 0)

        // When
        manager.markTabAsInvisible(tab1)
        XCTAssertEqual(manager.invisibleTabCount, 1)

        manager.markTabAsInvisible(tab2)
        XCTAssertEqual(manager.invisibleTabCount, 2)

        manager.markTabAsInvisible(tab3)
        XCTAssertEqual(manager.invisibleTabCount, 3)

        manager.markTabAsVisible(tab2)
        XCTAssertEqual(manager.invisibleTabCount, 2)

        manager.markTabAsVisible(tab1)
        manager.markTabAsVisible(tab3)
        XCTAssertEqual(manager.invisibleTabCount, 0)
    }

    func testVisibleTabCountWithoutTabManager() {
        // Given/When
        let visibleCount = manager.visibleTabCount

        // Then
        XCTAssertEqual(visibleCount, 0, "Should return 0 when no tab manager is available")
    }

    // MARK: - UUID Management Tests

    func testInvisibleTabUUIDs() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")

        // When
        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab3)

        // Then
        let invisibleUUIDs = manager.invisibleTabUUIDs
        XCTAssertEqual(invisibleUUIDs.count, 2)
        XCTAssertTrue(invisibleUUIDs.contains(tab1.tabUUID))
        XCTAssertFalse(invisibleUUIDs.contains(tab2.tabUUID))
        XCTAssertTrue(invisibleUUIDs.contains(tab3.tabUUID))
    }

    func testInvisibleTabUUIDsConsistency() {
        // Given
        let tabs = (0..<10).map { createMockTab(uuid: "tab-\($0)") }

        // When
        tabs.enumerated().forEach { index, tab in
            if index % 2 == 0 {
                manager.markTabAsInvisible(tab)
            }
        }

        // Then
        let invisibleUUIDs = manager.invisibleTabUUIDs
        XCTAssertEqual(invisibleUUIDs.count, manager.invisibleTabCount)
        tabs.enumerated().forEach { index, tab in
            if index % 2 == 0 {
                XCTAssertTrue(invisibleUUIDs.contains(tab.tabUUID))
            } else {
                XCTAssertFalse(invisibleUUIDs.contains(tab.tabUUID))
            }
        }
    }

    // MARK: - Cleanup Tests

    func testClearAllInvisibleTabs() {
        // Given
        let tabs = (0..<5).map { createMockTab(uuid: "tab-\($0)") }
        tabs.forEach { manager.markTabAsInvisible($0) }
        XCTAssertEqual(manager.invisibleTabCount, 5)

        // When
        manager.clearAllInvisibleTabs()

        // Then
        XCTAssertEqual(manager.invisibleTabCount, 0)
        tabs.forEach { tab in
            XCTAssertFalse(manager.isTabInvisible(tab))
        }
    }

    func testClearAllInvisibleTabsWhenNoneExist() {
        // Given
        XCTAssertEqual(manager.invisibleTabCount, 0)

        // When/Then - Should not crash
        manager.clearAllInvisibleTabs()
        XCTAssertEqual(manager.invisibleTabCount, 0)
    }

    func testCleanupRemovedTabs() {
        // Given
        let tab1 = createMockTab(uuid: "tab-1")
        let tab2 = createMockTab(uuid: "tab-2")
        let tab3 = createMockTab(uuid: "tab-3")
        let removedTab = createMockTab(uuid: "removed-tab")

        manager.markTabAsInvisible(tab1)
        manager.markTabAsInvisible(tab2)
        manager.markTabAsInvisible(tab3)
        manager.markTabAsInvisible(removedTab)
        XCTAssertEqual(manager.invisibleTabCount, 4)

        let existingTabUUIDs = Set([tab1.tabUUID, tab2.tabUUID, tab3.tabUUID])

        // When
        manager.cleanupRemovedTabs(existingTabUUIDs: existingTabUUIDs)

        // Then
        XCTAssertEqual(manager.invisibleTabCount, 3)
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertTrue(manager.isTabInvisible(tab2))
        XCTAssertTrue(manager.isTabInvisible(tab3))
        XCTAssertFalse(manager.isTabInvisible(removedTab))
    }

    // MARK: - Thread Safety Tests

    func testConcurrentOperations() {
        // Given
        let tabs = (0..<100).map { createMockTab(uuid: "tab-\($0)") }
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = tabs.count

        // When
        tabs.forEach { tab in
            DispatchQueue.global(qos: .background).async {
                self.manager.markTabAsInvisible(tab)
                        expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // Then
        XCTAssertEqual(manager.invisibleTabCount, 100)
        tabs.forEach { tab in
            XCTAssertTrue(manager.isTabInvisible(tab))
        }
    }

    func testConcurrentMarkAndClear() {
        // Given
        let tabs = (0..<50).map { createMockTab(uuid: "tab-\($0)") }
        let markExpectation = XCTestExpectation(description: "Mark operations completed")
        markExpectation.expectedFulfillmentCount = tabs.count

        // When
        tabs.forEach { tab in
            DispatchQueue.global(qos: .background).async {
                self.manager.markTabAsInvisible(tab)
                markExpectation.fulfill()
            }
        }

        // Clear after some marking has started
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
            self.manager.clearAllInvisibleTabs()
        }

        wait(for: [markExpectation], timeout: 5.0)

        // Allow clear operation to complete
        let clearExpectation = XCTestExpectation(description: "Clear operation completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            clearExpectation.fulfill()
        }
        wait(for: [clearExpectation], timeout: 1.0)

        // Then - Final state should be consistent
        let finalCount = manager.invisibleTabCount
        XCTAssertTrue(finalCount >= 0, "Count should be non-negative")
        XCTAssertLessThanOrEqual(finalCount, tabs.count, "Count should not exceed number of tabs")
    }

    // MARK: - Performance Tests

    func testPerformanceWithManyTabs() {
        // Given
        let manyTabs = (0..<1000).map { createMockTab(uuid: "tab-\($0)") }

        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        manyTabs.forEach { manager.markTabAsInvisible($0) }
        let endTime = CFAbsoluteTimeGetCurrent()

        // Then
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 1.0, "Should handle 1000 tabs in under 1 second")
        XCTAssertEqual(manager.invisibleTabCount, 1000)
    }

    func testPerformanceOfFiltering() {
        // Given
        let manyTabs = (0..<1000).map { createMockTab(uuid: "tab-\($0)") }
        manyTabs.enumerated().forEach { index, tab in
            if index % 2 == 0 {
                manager.markTabAsInvisible(tab)
            }
        }

        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let visibleTabs = manager.getVisibleTabs(from: manyTabs)
        let invisibleTabs = manager.getInvisibleTabs(from: manyTabs)
        let endTime = CFAbsoluteTimeGetCurrent()

        // Then
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 0.1, "Should filter 1000 tabs in under 0.1 seconds")
        XCTAssertEqual(visibleTabs.count, 500)
        XCTAssertEqual(invisibleTabs.count, 500)
    }

    // MARK: - Edge Case Tests

    func testTabWithEmptyUUID() {
        // Given
        let tabWithEmptyUUID = createMockTab(uuid: "")

        // When
        manager.markTabAsInvisible(tabWithEmptyUUID)

        // Then
        XCTAssertTrue(manager.isTabInvisible(tabWithEmptyUUID))
        XCTAssertEqual(manager.invisibleTabCount, 1)
        XCTAssertTrue(manager.invisibleTabUUIDs.contains(""))
    }

    func testTabWithSameUUIDDifferentInstances() {
        // Given
        let uuid = "same-uuid"
        let tab1 = createMockTab(uuid: uuid)
        let tab2 = createMockTab(uuid: uuid)

        // When
        manager.markTabAsInvisible(tab1)

        // Then
        XCTAssertTrue(manager.isTabInvisible(tab1))
        XCTAssertTrue(manager.isTabInvisible(tab2), "Should consider tab2 invisible due to same UUID")
        XCTAssertEqual(manager.invisibleTabCount, 1, "Should only count once for same UUID")
    }

    // MARK: - Helper Methods

    private func createMockTab(uuid: String) -> Tab {
        let profile = MockProfile()
        let tab = Tab(profile: profile, isPrivate: false, windowUUID: WindowUUID())
        tab.tabUUID = uuid
        return tab
    }
}

// MARK: - Mock Notification Center

class InvisibleTabManagerMockNotificationCenter: NotificationCenter, @unchecked Sendable {
    private var observers: [(name: Notification.Name, observer: Any, selector: Selector)] = []

    override func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        if let name = aName {
            observers.append((name: name, observer: observer, selector: aSelector))
        }
    }

    override func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        observers.removeAll { (_, obs, _) in
            return (obs as AnyObject) === (observer as AnyObject)
        }
    }

    func simulateNotification(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        let notification = Notification(name: name, object: object, userInfo: userInfo)

        for (notificationName, observer, selector) in observers {
            if notificationName == name {
                _ = (observer as AnyObject).perform(selector, with: notification)
            }
        }
    }
}
