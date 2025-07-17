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
    private var mockBrowserViewController: MockBrowserViewController!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()

        // Create mock components
        let profile = MockProfile()
        mockTabManager = MockTabManagerForAPI()
        mockBrowserViewController = MockBrowserViewController(profile: profile, tabManager: mockTabManager)

        // Set up API instance with proper dependencies
        api = InvisibleTabAPI(browserViewController: mockBrowserViewController, tabManager: mockTabManager)

        // Clean up any existing state
        api.cleanupAllTracking()
    }
    
    override func tearDown() {
        api.cleanupAllTracking()
        mockBrowserViewController = nil
        mockTabManager = nil
        api = nil
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
    
    func testConfiguration_defaultValues() {
        // Then
        XCTAssertEqual(InvisibleTabAPI.Configuration.defaultTimeout, TabAutoCloseConfig.fallbackTimeout)
        XCTAssertEqual(InvisibleTabAPI.Configuration.maxConcurrentTabs, TabAutoCloseConfig.maxConcurrentAutoCloseTabs)
    }

    // MARK: - Initialization Tests

    func testInitialization_withDependencies() {
        // Given/When - setup in setUp()
        
        // Then
        XCTAssertNotNil(api)
        XCTAssertEqual(api.getTrackedTabCount(), 0, "Should start with no tracked tabs")
    }
    
    // MARK: - Tab Visibility Tests
    
    func testMarkTabAsInvisible() {
        // Given
        let tab = createMockTab()
        XCTAssertFalse(api.isTabInvisible(tab))
        
        // When
        let result = api.markTabAsInvisible(tab)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(api.isTabInvisible(tab))
    }
    
    func testMarkTabAsVisible() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)
        XCTAssertTrue(api.isTabInvisible(tab))
        
        // When
        let result = api.markTabAsVisible(tab)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertFalse(api.isTabInvisible(tab))
    }
    
    func testMarkTabAsVisibleCancelsAutoClose() {
        // Given
        let tab = createMockTab(uuid: "test-tab")
        api.markTabAsInvisible(tab)
        api.setupAutoCloseForTab(tab)
        XCTAssertEqual(api.trackedTabsCount, 1)
        
        // When
        api.markTabAsVisible(tab)
        
        // Then
        XCTAssertFalse(api.isTabInvisible(tab))
        XCTAssertEqual(api.trackedTabsCount, 0, "Should cancel auto-close tracking")
    }
    
    // MARK: - Auto-Close Tests
    
    func testSetupAutoCloseForTab() {
        // Given
        let tab = createMockTab(uuid: "auto-close-tab")
        
        // When
        let result = api.setupAutoCloseForTab(tab)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(api.trackedTabsCount, 1)
        XCTAssertTrue(api.getTrackedTabUUIDs().contains(tab.tabUUID))
    }
    
    func testSetupAutoCloseForTabWithCustomTimeout() {
        // Given
        let tab = createMockTab(uuid: "custom-timeout-tab")
        
        // When
        let result = api.setupAutoCloseForTab(tab, timeout: 5.0)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(api.trackedTabsCount, 1)
    }
    
    func testSetupAutoCloseForTabWithCustomNotification() {
        // Given
        let tab = createMockTab(uuid: "custom-notification-tab")
        let customNotification = Notification.Name("CustomTestNotification")
        
        // When
        let result = api.setupAutoCloseForTab(tab, notification: customNotification)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(api.trackedTabsCount, 1)
    }
    
    func testCancelAutoCloseForTab() {
        // Given
        let tab = createMockTab(uuid: "cancel-tab")
        api.setupAutoCloseForTab(tab)
        XCTAssertEqual(api.trackedTabsCount, 1)
        
        // When
        let result = api.cancelAutoCloseForTab(tab.tabUUID)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(api.trackedTabsCount, 0)
        XCTAssertFalse(api.getTrackedTabUUIDs().contains(tab.tabUUID))
    }
    
    func testCancelAutoCloseForMultipleTabs() {
        // Given
        let tabs = [createMockTab(uuid: "tab1"), createMockTab(uuid: "tab2"), createMockTab(uuid: "tab3")]
        tabs.forEach { api.setupAutoCloseForTab($0) }
        XCTAssertEqual(api.trackedTabsCount, 3)
        
        // When
        api.cancelAutoCloseForTabs(tabs.map { $0.tabUUID })
        
        // Then
        XCTAssertEqual(api.trackedTabsCount, 0)
    }
    
    // MARK: - Tab Filtering Tests
    
    func testGetVisibleTabs() {
        // Given
        let visibleTab = createMockTab(uuid: "visible")
        let invisibleTab = createMockTab(uuid: "invisible")
        mockTabManager.tabs = [visibleTab, invisibleTab]
        api.markTabAsInvisible(invisibleTab)
        
        // When
        let visibleTabs = api.getVisibleTabs()
        
        // Then
        XCTAssertEqual(visibleTabs.count, 1)
        XCTAssertTrue(visibleTabs.contains(visibleTab))
        XCTAssertFalse(visibleTabs.contains(invisibleTab))
    }
    
    func testGetInvisibleTabs() {
        // Given
        let visibleTab = createMockTab(uuid: "visible")
        let invisibleTab = createMockTab(uuid: "invisible")
        mockTabManager.tabs = [visibleTab, invisibleTab]
        api.markTabAsInvisible(invisibleTab)
        
        // When
        let invisibleTabs = api.getInvisibleTabs()
        
        // Then
        XCTAssertEqual(invisibleTabs.count, 1)
        XCTAssertTrue(invisibleTabs.contains(invisibleTab))
        XCTAssertFalse(invisibleTabs.contains(visibleTab))
    }
    
    func testGetVisibleNormalTabs() {
        // Given
        let normalTab = createMockTab(uuid: "normal", isPrivate: false)
        let privateTab = createMockTab(uuid: "private", isPrivate: true)
        mockTabManager.tabs = [normalTab, privateTab]
        
        // When
        let visibleNormalTabs = api.getVisibleNormalTabs()
        
        // Then
        XCTAssertEqual(visibleNormalTabs.count, 1)
        XCTAssertTrue(visibleNormalTabs.contains(normalTab))
        XCTAssertFalse(visibleNormalTabs.contains(privateTab))
    }
    
    func testGetVisiblePrivateTabs() {
        // Given
        let normalTab = createMockTab(uuid: "normal", isPrivate: false)
        let privateTab = createMockTab(uuid: "private", isPrivate: true)
        mockTabManager.tabs = [normalTab, privateTab]
        
        // When
        let visiblePrivateTabs = api.getVisiblePrivateTabs()
        
        // Then
        XCTAssertEqual(visiblePrivateTabs.count, 1)
        XCTAssertTrue(visiblePrivateTabs.contains(privateTab))
        XCTAssertFalse(visiblePrivateTabs.contains(normalTab))
    }

    // MARK: - Count Tests
    
    func testTabCounts() {
        // Given
        let tab1 = createMockTab(uuid: "tab1")
        let tab2 = createMockTab(uuid: "tab2")
        mockTabManager.tabs = [tab1, tab2]
        api.markTabAsInvisible(tab1)

        // When/Then
        XCTAssertEqual(api.totalTabsCount, 2)
        XCTAssertEqual(api.visibleTabsCount, 1)
        XCTAssertEqual(api.invisibleTabsCount, 1)
    }

    func testTrackedTabCount() {
        // Given
        let tab1 = createMockTab(uuid: "tab1")
        let tab2 = createMockTab(uuid: "tab2")

        // When
        api.setupAutoCloseForTab(tab1)
        api.setupAutoCloseForTab(tab2)

        // Then
        XCTAssertEqual(api.trackedTabsCount, 2)
        XCTAssertEqual(api.getTrackedTabCount(), 2)
    }

    // MARK: - Cleanup Tests

    func testCleanupAllTracking() {
        // Given
        let tab1 = createMockTab(uuid: "tab1")
        let tab2 = createMockTab(uuid: "tab2")
        api.markTabAsInvisible(tab1)
        api.markTabAsInvisible(tab2)
        api.setupAutoCloseForTab(tab1)
        api.setupAutoCloseForTab(tab2)

        // When
        api.cleanupAllTracking()

        // Then
        XCTAssertEqual(api.invisibleTabsCount, 0)
        XCTAssertEqual(api.trackedTabsCount, 0)
    }

    func testCleanupRemovedTabs() {
        // Given
        let existingTab = createMockTab(uuid: "existing")
        let removedTab = createMockTab(uuid: "removed")
        mockTabManager.tabs = [existingTab] // Only existing tab remains
        api.markTabAsInvisible(removedTab) // This tab was removed from tab manager
        api.setupAutoCloseForTab(removedTab)
        
        // When
        api.cleanupRemovedTabs()
        
        // Then - Should clean up tracking for removed tabs
        XCTAssertEqual(api.trackedTabsCount, 0, "Should cleanup tracking for removed tabs")
    }
    
    // MARK: - Integration Tests
    
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

        NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)
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

        NotificationCenter.default.post(name: .EcosiaAuthStateChanged, object: nil)
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(api.trackedTabsCount, 0, "Should cleanup tracking")
    }
    
    // MARK: - Error Handling Tests
    
    func testMarkTabAsInvisibleWithNilTabManager() {
        // Given
        api.setTabManager(nil)
        let tab = createMockTab()
        
        // When
        let result = api.markTabAsInvisible(tab)
        
        // Then - Should still work as it delegates to InvisibleTabManager
        XCTAssertTrue(result)
    }
    
    func testGetVisibleTabsWithNilTabManager() {
        // Given
        api.setTabManager(nil)
        
        // When
        let visibleTabs = api.getVisibleTabs()
        
        // Then
        XCTAssertEqual(visibleTabs.count, 0)
    }
    
    func testTabCountsWithNilTabManager() {
        // Given
        api.setTabManager(nil)

        // When/Then
        XCTAssertEqual(api.totalTabsCount, 0)
        XCTAssertEqual(api.visibleTabsCount, 0)
    }

    // MARK: - Tab Creation Tests (Would need BrowserViewController)

    func testCreateInvisibleTabWithoutBrowserViewController() {
        // Given - API is not initialized with BrowserViewController
        let url = URL(string: "https://example.com")!
        
        // When
        let tab = api.createInvisibleTab(for: url)
        
        // Then
        XCTAssertNil(tab, "Should return nil when BrowserViewController is not set")
    }
    
    func testCreateInvisibleAuthTabWithoutBrowserViewController() {
        // Given - API is not initialized with BrowserViewController
        let url = URL(string: "https://auth.example.com")!
        
        // When
        let tab = api.createInvisibleAuthTab(for: url)
        
        // Then
        XCTAssertNil(tab, "Should return nil when BrowserViewController is not set")
    }

    func testCreateInvisibleTabsWithoutBrowserViewController() {
        // Given - API is not initialized with BrowserViewController
        let urls = [
            URL(string: "https://example1.com")!,
            URL(string: "https://example2.com")!
        ]
        
        // When
        let tabs = api.createInvisibleTabs(for: urls)
        
        // Then
        XCTAssertEqual(tabs.count, 0, "Should return empty array when BrowserViewController is not set")
    }
    
    func testCreateInvisibleTabsWithTooManyUrls() {
        // Given - More URLs than max concurrent tabs
        let maxTabs = InvisibleTabAPI.Configuration.maxConcurrentTabs
        let urls = (0...(maxTabs + 1)).compactMap { URL(string: "https://example\($0).com") }

        // When
        let tabs = api.createInvisibleTabs(for: urls)
        
        // Then
        XCTAssertEqual(tabs.count, 0, "Should return empty array when URL count exceeds max")
    }
    
    // MARK: - Utility Tests
    
    func testIsTabInvisible() {
        // Given
        let visibleTab = createMockTab(uuid: "visible")
        let invisibleTab = createMockTab(uuid: "invisible")
        api.markTabAsInvisible(invisibleTab)

        // When/Then
        XCTAssertFalse(api.isTabInvisible(visibleTab))
        XCTAssertTrue(api.isTabInvisible(invisibleTab))
    }

    func testGetInvisibleTabSummary() {
        // When
        let summary = api.getInvisibleTabSummary()
        
        // Then
        XCTAssertTrue(summary.contains("InvisibleTabAPI"), "Summary should mention the API")
    }
    
    func testPrintInvisibleTabSummary() {
        // When/Then - Should not crash
        api.printInvisibleTabSummary()
    }

    // MARK: - Reset Tests

    func testReset() {
        // Given
        let tab = createMockTab()
        api.markTabAsInvisible(tab)
        api.setupAutoCloseForTab(tab)

        // When
        api.reset()
        
        // Then - Should not crash
        // Note: Reset clears browser view controller reference but doesn't affect managers
        XCTAssertEqual(api.getInvisibleTabSummary(), "InvisibleTabAPI - BrowserViewController not initialized")
    }
}

// MARK: - Mock Classes

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
