// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Client

/// Test suite for VisibleTabProvider functionality
final class VisibleTabProviderTests: XCTestCase {

    // MARK: - Properties

    private var testTabs: [Tab] = []

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        createTestTabs()

        // Clear any existing invisible tab state
        InvisibleTabManager.shared.clearAllInvisibleTabs()
    }

    override func tearDown() {
        testTabs.removeAll()
        InvisibleTabManager.shared.clearAllInvisibleTabs()
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestTabs() {
        let profile = MockProfile()

        // Create 6 tabs: 3 normal, 3 private
        testTabs = (0..<6).map { index in
            let isPrivate = index >= 3 // First 3 are normal, last 3 are private
            let tab = Tab(profile: profile, isPrivate: isPrivate, windowUUID: WindowUUID())
            tab.tabUUID = "tab-\(index)"
            return tab
        }
    }

    private func getNormalAndPrivateTabs() -> ([Tab], [Tab]) {
        // Split tabs into normal and private
        let normalTabs = testTabs.filter { !$0.isPrivate }
        let privateTabs = testTabs.filter { $0.isPrivate }
        return (normalTabs, privateTabs)
    }

    // MARK: - Basic Filtering Tests

    func testGetVisibleTabsWithNoInvisibleTabs() {
        // Given
        let allTabs = testTabs

        // When
        let visibleTabs = VisibleTabProvider.getVisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, allTabs.count, "All tabs should be visible when none are invisible")
        XCTAssertEqual(Set(visibleTabs.map { $0.tabUUID }), Set(allTabs.map { $0.tabUUID }))
    }

    func testGetVisibleTabsWithSomeInvisibleTabs() {
        // Given
        let allTabs = testTabs

        // Mark some tabs as invisible
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[2])

        // When
        let visibleTabs = VisibleTabProvider.getVisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 4, "Should return 4 visible tabs")
        let visibleTabUUIDs = visibleTabs.map { $0.tabUUID }
        XCTAssertFalse(visibleTabUUIDs.contains("tab-0"))
        XCTAssertTrue(visibleTabUUIDs.contains("tab-1"))
        XCTAssertFalse(visibleTabUUIDs.contains("tab-2"))
        XCTAssertTrue(visibleTabUUIDs.contains("tab-3"))
    }

    func testGetInvisibleTabsWithNoInvisibleTabs() {
        // Given
        let allTabs = testTabs

        // When
        let invisibleTabs = VisibleTabProvider.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleTabs.count, 0, "Should return no invisible tabs when none exist")
    }

    func testGetInvisibleTabsWithSomeInvisibleTabs() {
        // Given
        let allTabs = testTabs

        // Mark some tabs as invisible
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[1])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[3])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[5])

        // When
        let invisibleTabs = VisibleTabProvider.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleTabs.count, 3, "Should return 3 invisible tabs")
        let invisibleTabUUIDs = invisibleTabs.map { $0.tabUUID }
        XCTAssertTrue(invisibleTabUUIDs.contains("tab-1"))
        XCTAssertTrue(invisibleTabUUIDs.contains("tab-3"))
        XCTAssertTrue(invisibleTabUUIDs.contains("tab-5"))
    }

    // MARK: - Tab Type Filtering Tests

    func testGetVisibleNormalTabs() {
        // Given
        let (normalTabs, privateTabs) = getNormalAndPrivateTabs()
        let allTabs = normalTabs + privateTabs

        // Mark one normal tab as invisible
        InvisibleTabManager.shared.markTabAsInvisible(normalTabs[0])

        // When
        let visibleNormalTabs = VisibleTabProvider.getVisibleNormalTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleNormalTabs.count, 2, "Should return 2 visible normal tabs")
        let visibleNormalTabUUIDs = visibleNormalTabs.map { $0.tabUUID }
        XCTAssertFalse(visibleNormalTabUUIDs.contains(normalTabs[0].tabUUID))
        XCTAssertTrue(visibleNormalTabUUIDs.contains(normalTabs[1].tabUUID))
        XCTAssertTrue(visibleNormalTabUUIDs.contains(normalTabs[2].tabUUID))
    }

    func testGetVisiblePrivateTabs() {
        // Given
        let (normalTabs, privateTabs) = getNormalAndPrivateTabs()
        let allTabs = normalTabs + privateTabs

        // Mark one private tab as invisible
        InvisibleTabManager.shared.markTabAsInvisible(privateTabs[1])

        // When
        let visiblePrivateTabs = VisibleTabProvider.getVisiblePrivateTabs(from: allTabs)

        // Then
        XCTAssertEqual(visiblePrivateTabs.count, 2, "Should return 2 visible private tabs")
        let visiblePrivateTabUUIDs = visiblePrivateTabs.map { $0.tabUUID }
        XCTAssertTrue(visiblePrivateTabUUIDs.contains(privateTabs[0].tabUUID))
        XCTAssertTrue(visiblePrivateTabUUIDs.contains(privateTabs[2].tabUUID))
        XCTAssertFalse(visiblePrivateTabUUIDs.contains(privateTabs[1].tabUUID), "Should not contain invisible tab")
    }

    func testGetInvisibleNormalTabs() {
        // Given
        let (normalTabs, privateTabs) = getNormalAndPrivateTabs()
        let allTabs = normalTabs + privateTabs

        // Mark some normal tabs as invisible
        InvisibleTabManager.shared.markTabAsInvisible(normalTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(normalTabs[2])

        // When
        let invisibleNormalTabs = VisibleTabProvider.getInvisibleNormalTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisibleNormalTabs.count, 2, "Should return 2 invisible normal tabs")
        let invisibleNormalTabUUIDs = invisibleNormalTabs.map { $0.tabUUID }
        XCTAssertTrue(invisibleNormalTabUUIDs.contains(normalTabs[0].tabUUID))
        XCTAssertTrue(invisibleNormalTabUUIDs.contains(normalTabs[2].tabUUID))
    }

    func testGetInvisiblePrivateTabs() {
        // Given
        let (normalTabs, privateTabs) = getNormalAndPrivateTabs()
        let allTabs = normalTabs + privateTabs

        // Mark some private tabs as invisible
        InvisibleTabManager.shared.markTabAsInvisible(privateTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(privateTabs[2])

        // When
        let invisiblePrivateTabs = VisibleTabProvider.getInvisiblePrivateTabs(from: allTabs)

        // Then
        XCTAssertEqual(invisiblePrivateTabs.count, 2, "Should return 2 invisible private tabs")
        let invisiblePrivateTabUUIDs = invisiblePrivateTabs.map { $0.tabUUID }
        XCTAssertTrue(invisiblePrivateTabUUIDs.contains(privateTabs[0].tabUUID))
        XCTAssertTrue(invisiblePrivateTabUUIDs.contains(privateTabs[2].tabUUID))
    }

    // MARK: - Mixed Scenarios Tests

    func testMixedVisibilityAndPrivacy() {
        // Given
        let (normalTabs, privateTabs) = getNormalAndPrivateTabs()
        let allTabs = normalTabs + privateTabs

        // Mark some tabs as invisible (both normal and private)
        InvisibleTabManager.shared.markTabAsInvisible(normalTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(privateTabs[1])

        // When
        let visibleNormalTabs = VisibleTabProvider.getVisibleNormalTabs(from: allTabs)
        let visiblePrivateTabs = VisibleTabProvider.getVisiblePrivateTabs(from: allTabs)
        let invisibleNormalTabs = VisibleTabProvider.getInvisibleNormalTabs(from: allTabs)
        let invisiblePrivateTabs = VisibleTabProvider.getInvisiblePrivateTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleNormalTabs.count + visiblePrivateTabs.count + invisibleNormalTabs.count + invisiblePrivateTabs.count,
                       allTabs.count, "Total should equal all tabs")
    }

    func testCompletelyInvisibleTabs() {
        // Given
        let allTabs = testTabs

        // Mark all tabs as invisible
        allTabs.forEach { InvisibleTabManager.shared.markTabAsInvisible($0) }

        // When
        let visibleTabs = VisibleTabProvider.getVisibleTabs(from: allTabs)
        let invisibleTabs = VisibleTabProvider.getInvisibleTabs(from: allTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 0, "Should have no visible tabs")
        XCTAssertEqual(invisibleTabs.count, allTabs.count, "All tabs should be invisible")
    }

    // MARK: - Comprehensive Tab Type Tests

    func testComprehensiveTabTypeFiltering() {
        // Given
        let allTabs = testTabs

        // Mark some tabs as invisible
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0]) // normal tab
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[3]) // private tab (simulated)

        // When
        let visibleNormalTabs = VisibleTabProvider.getVisibleNormalTabs(from: allTabs)
        let visiblePrivateTabs = VisibleTabProvider.getVisiblePrivateTabs(from: allTabs)
        let invisibleNormalTabs = VisibleTabProvider.getInvisibleNormalTabs(from: allTabs)
        let invisiblePrivateTabs = VisibleTabProvider.getInvisiblePrivateTabs(from: allTabs)

        // Then
        let totalVisible = visibleNormalTabs.count + visiblePrivateTabs.count
        let totalInvisible = invisibleNormalTabs.count + invisiblePrivateTabs.count

        XCTAssertEqual(totalVisible + totalInvisible, allTabs.count, "Should account for all tabs")
        XCTAssertEqual(totalInvisible, 2, "Should have 2 invisible tabs")
        XCTAssertEqual(totalVisible, 4, "Should have 4 visible tabs")
    }

    func testTabTypeConsistency() {
        // Given
        let allTabs = testTabs

        // When
        let normalTabs = VisibleTabProvider.getVisibleNormalTabs(from: allTabs) +
                        VisibleTabProvider.getInvisibleNormalTabs(from: allTabs)
        let privateTabs = VisibleTabProvider.getVisiblePrivateTabs(from: allTabs) +
                         VisibleTabProvider.getInvisiblePrivateTabs(from: allTabs)

        // Then
        XCTAssertEqual(normalTabs.count + privateTabs.count, allTabs.count, "Should account for all tabs by type")
    }

    // MARK: - Count Helper Tests

    func testGetVisibleCount() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[2])

        // When
        let visibleCount = VisibleTabProvider.getVisibleCount(from: allTabs)

        // Then
        XCTAssertEqual(visibleCount, 4, "Should return correct visible count")
    }

    func testGetInvisibleCount() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[1])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[3])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[5])

        // When
        let invisibleCount = VisibleTabProvider.getInvisibleCount(from: allTabs)

        // Then
        XCTAssertEqual(invisibleCount, 3, "Should return correct invisible count")
    }

    // MARK: - Advanced Filtering Tests

    func testFilterTabsWithAdditionalConditions() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])

        // When
        let filteredTabs = VisibleTabProvider.filterTabs(from: allTabs,
                                                        includeInvisible: false) { tab in
            tab.tabUUID.contains("1") || tab.tabUUID.contains("3")
        }

        // Then
        XCTAssertEqual(filteredTabs.count, 2, "Should return tabs matching additional filter")
        let filteredUUIDs = filteredTabs.map { $0.tabUUID }
        XCTAssertTrue(filteredUUIDs.contains("tab-1"))
        XCTAssertTrue(filteredUUIDs.contains("tab-3"))
    }

    func testFilterTabsIncludingInvisible() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[2])

        // When
        let filteredTabs = VisibleTabProvider.filterTabs(from: allTabs,
                                                        includeInvisible: true) { tab in
            tab.tabUUID.contains("0") || tab.tabUUID.contains("2")
        }

        // Then
        XCTAssertEqual(filteredTabs.count, 2, "Should include invisible tabs when specified")
        let filteredUUIDs = filteredTabs.map { $0.tabUUID }
        XCTAssertTrue(filteredUUIDs.contains("tab-0"))
        XCTAssertTrue(filteredUUIDs.contains("tab-2"))
    }

    // MARK: - Grouping Tests

    func testGroupTabsByVisibility() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[2])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[4])

        // When
        let groupedTabs = VisibleTabProvider.groupTabsByVisibility(from: allTabs)

        // Then
        XCTAssertNotNil(groupedTabs["visible"])
        XCTAssertNotNil(groupedTabs["invisible"])
        XCTAssertEqual(groupedTabs["visible"]?.count, 3, "Should have 3 visible tabs")
        XCTAssertEqual(groupedTabs["invisible"]?.count, 3, "Should have 3 invisible tabs")
    }

    // MARK: - Search Helper Tests

    func testFirstVisibleTab() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[1])

        // When
        let firstVisibleTab = VisibleTabProvider.firstVisibleTab(from: allTabs) { tab in
            tab.tabUUID.contains("2") || tab.tabUUID.contains("3")
        }

        // Then
        XCTAssertNotNil(firstVisibleTab)
        XCTAssertEqual(firstVisibleTab?.tabUUID, "tab-2", "Should return first matching visible tab")
    }

    func testLastVisibleTab() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[4])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[5])

        // When
        let lastVisibleTab = VisibleTabProvider.lastVisibleTab(from: allTabs) { tab in
            tab.tabUUID.contains("1") || tab.tabUUID.contains("3")
        }

        // Then
        XCTAssertNotNil(lastVisibleTab)
        XCTAssertEqual(lastVisibleTab?.tabUUID, "tab-3", "Should return last matching visible tab")
    }

    // MARK: - Boolean Helper Tests

    func testHasInvisibleTabs() {
        // Given
        let allTabs = testTabs

        // When - No invisible tabs
        let hasInvisibleBefore = VisibleTabProvider.hasInvisibleTabs(in: allTabs)

        // Mark one as invisible
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        let hasInvisibleAfter = VisibleTabProvider.hasInvisibleTabs(in: allTabs)

        // Then
        XCTAssertFalse(hasInvisibleBefore, "Should return false when no invisible tabs")
        XCTAssertTrue(hasInvisibleAfter, "Should return true when invisible tabs exist")
    }

    func testAllTabsAreVisible() {
        // Given
        let allTabs = testTabs

        // When - All visible
        let allVisibleBefore = VisibleTabProvider.allTabsAreVisible(in: allTabs)

        // Mark one as invisible
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        let allVisibleAfter = VisibleTabProvider.allTabsAreVisible(in: allTabs)

        // Then
        XCTAssertTrue(allVisibleBefore, "Should return true when all tabs are visible")
        XCTAssertFalse(allVisibleAfter, "Should return false when some tabs are invisible")
    }

    // MARK: - Summary and Debug Tests

    func testGetVisibilitySummary() {
        // Given
        let allTabs = testTabs
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[0])
        InvisibleTabManager.shared.markTabAsInvisible(allTabs[2])

        // When
        let summary = VisibleTabProvider.getVisibilitySummary(for: allTabs)

        // Then
        XCTAssertTrue(summary.contains("6 total"), "Should include total count")
        XCTAssertTrue(summary.contains("4 visible"), "Should include visible count")
        XCTAssertTrue(summary.contains("2 invisible"), "Should include invisible count")
    }

    // MARK: - Edge Cases

    func testEmptyTabArray() {
        // Given
        let emptyTabs: [Tab] = []

        // When
        let visibleTabs = VisibleTabProvider.getVisibleTabs(from: emptyTabs)
        let invisibleTabs = VisibleTabProvider.getInvisibleTabs(from: emptyTabs)
        let visibleCount = VisibleTabProvider.getVisibleCount(from: emptyTabs)
        let invisibleCount = VisibleTabProvider.getInvisibleCount(from: emptyTabs)

        // Then
        XCTAssertEqual(visibleTabs.count, 0, "Should handle empty array")
        XCTAssertEqual(invisibleTabs.count, 0, "Should handle empty array")
        XCTAssertEqual(visibleCount, 0, "Should handle empty array")
        XCTAssertEqual(invisibleCount, 0, "Should handle empty array")
    }

    func testSingleTabScenarios() {
        // Given
        let singleTab = [testTabs[0]]

        // When - Tab is visible
        let visibleWhenVisible = VisibleTabProvider.getVisibleTabs(from: singleTab)
        let invisibleWhenVisible = VisibleTabProvider.getInvisibleTabs(from: singleTab)

        // Mark as invisible
        InvisibleTabManager.shared.markTabAsInvisible(singleTab[0])
        let visibleWhenInvisible = VisibleTabProvider.getVisibleTabs(from: singleTab)
        let invisibleWhenInvisible = VisibleTabProvider.getInvisibleTabs(from: singleTab)

        // Then
        XCTAssertEqual(visibleWhenVisible.count, 1, "Should return single visible tab")
        XCTAssertEqual(invisibleWhenVisible.count, 0, "Should return no invisible tabs")
        XCTAssertEqual(visibleWhenInvisible.count, 0, "Should return no visible tabs")
        XCTAssertEqual(invisibleWhenInvisible.count, 1, "Should return single invisible tab")
    }

    // MARK: - Performance Tests

    func testLargeTabCollectionPerformance() {
        // Given
        let profile = MockProfile()
        let largeTabs = (0..<1000).map { index in
            let tab = Tab(profile: profile, windowUUID: WindowUUID())
            tab.tabUUID = "large-tab-\(index)"
            return tab
        }

        // Mark every 3rd tab as invisible
        for (index, tab) in largeTabs.enumerated() {
            if index % 3 == 0 {
                InvisibleTabManager.shared.markTabAsInvisible(tab)
            }
        }

        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let visibleTabs = VisibleTabProvider.getVisibleTabs(from: largeTabs)
        let invisibleTabs = VisibleTabProvider.getInvisibleTabs(from: largeTabs)
        let endTime = CFAbsoluteTimeGetCurrent()

        // Then
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 0.1, "Should handle 1000 tabs efficiently")
        XCTAssertEqual(visibleTabs.count + invisibleTabs.count, largeTabs.count, "Should account for all tabs")

        // Cleanup
        InvisibleTabManager.shared.clearAllInvisibleTabs()
    }
}
