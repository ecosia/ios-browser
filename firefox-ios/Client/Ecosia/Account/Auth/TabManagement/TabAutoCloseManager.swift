// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia
import Common

/// Configuration for tab auto-close behavior
struct TabAutoCloseConfig {
    /// Timeout for fallback closure if notification doesn't arrive
    static let fallbackTimeout: TimeInterval = 10.0

    /// Maximum number of invisible tabs that can be auto-closed simultaneously
    static let maxConcurrentAutoCloseTabs: Int = 5

    /// Debounce interval to prevent multiple rapid auto-close operations
    static let debounceInterval: TimeInterval = 0.5
}

/// Manager for automatic closing of invisible tabs based on notifications
/// Handles authentication completion notifications and fallback timeouts
/// Ecosia: @MainActor so TabManager and UI/tab ops stay on main thread; avoids sending non-Sendable TabManager.
@MainActor
final class InvisibleTabAutoCloseManager {

    // MARK: - Properties

    /// Singleton instance for app-wide auto-close management
    static let shared = InvisibleTabAutoCloseManager()

    /// Dictionary mapping tab UUIDs to their notification observers
    private var authTabObservers: [String: NSObjectProtocol] = [:]

    /// Dictionary mapping tab UUIDs to their fallback timeout tasks
    private var fallbackTimeouts: [String: Task<Void, Never>] = [:]

    /// Notification center for observing auth completion
    private let notificationCenter: NotificationCenter

    /// Weak reference to tab manager for tab removal operations
    private weak var tabManager: TabManager?

    /// Ecosia: Single observer for TabEvent.didChangeURL (replaces .OnLocationChange); nil until first setup
    private var didChangeURLObserver: NSObjectProtocol?

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    /// - Parameter notificationCenter: Notification center for observing, defaults to default center
    private init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    /// Injects tab manager dependency
    /// - Parameter tabManager: Tab manager to use for tab operations
    func setTabManager(_ tabManager: TabManager) {
        self.tabManager = tabManager
    }

    // MARK: - Auto-Close Setup

    /// Sets up automatic closing for a tab when authentication completes (by Tab)
    func setupAutoCloseForTab(_ tab: Tab,
                              on notification: Notification.Name = .EcosiaAuthStateChanged,
                              timeout: TimeInterval = TabAutoCloseConfig.fallbackTimeout) {
        guard tab.isInvisible else {
            EcosiaLogger.invisibleTabs.notice("Attempted to setup auto-close for visible tab: \(tab.tabUUID)")
            return
        }
        EcosiaLogger.invisibleTabs.info("Setting up auto-close for tab: \(tab.tabUUID)")
        cleanupObserver(for: tab.tabUUID)
        createObserver(for: tab.tabUUID, notification: notification, timeout: timeout)
    }

    /// Ecosia: Sets up automatic closing by tab UUID (used when caller only has TabUUID, e.g. InvisibleTabSession)
    func setupAutoCloseForTab(tabUUID: TabUUID,
                              on notification: Notification.Name = .EcosiaAuthStateChanged,
                              timeout: TimeInterval = TabAutoCloseConfig.fallbackTimeout) {
        EcosiaLogger.invisibleTabs.info("Setting up auto-close for tab: \(tabUUID)")
        cleanupObserver(for: tabUUID)
        createObserver(for: tabUUID, notification: notification, timeout: timeout)
    }

    /// Sets up automatic closing for multiple tabs
    /// - Parameters:
    ///   - tabs: Array of tabs to setup auto-close for
    ///   - notification: The notification name to observe for completion
    ///   - timeout: Custom timeout for fallback closure
    func setupAutoCloseForTabs(_ tabs: [Tab],
                               on notification: Notification.Name = .EcosiaAuthStateChanged,
                               timeout: TimeInterval = TabAutoCloseConfig.fallbackTimeout) {

        let invisibleTabs = tabs.filter { $0.isInvisible }

        guard invisibleTabs.count <= TabAutoCloseConfig.maxConcurrentAutoCloseTabs else {
            EcosiaLogger.invisibleTabs.notice("Too many tabs for concurrent auto-close: \(invisibleTabs.count)")
            return
        }

        for tab in invisibleTabs {
            setupAutoCloseForTab(tab, on: notification, timeout: timeout)
        }
    }

    // MARK: - Private Implementation

    /// Creates notification observer and fallback timeout for a tab (by tab UUID)
    private func createObserver(for tabUUID: TabUUID,
                                notification: Notification.Name,
                                timeout: TimeInterval) {
        ensureDidChangeURLObserver()

        let observer = notificationCenter.addObserver(
            forName: notification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.handleAuthenticationCompletion(for: tabUUID) }
        }

        authTabObservers[tabUUID] = observer

        let fallbackTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                EcosiaLogger.invisibleTabs.info("Fallback timeout reached for tab: \(tabUUID)")
                await self?.handleAuthenticationCompletion(for: tabUUID, isFallback: true)
            } catch {
                // Task was cancelled, which is expected
            }
        }

        fallbackTimeouts[tabUUID] = fallbackTask
        EcosiaLogger.invisibleTabs.info("Auto-close setup completed for tab: \(tabUUID)")
    }

    /// Ecosia: Single observer for TabEvent.didChangeURL (replaces .OnLocationChange)
    private func ensureDidChangeURLObserver() {
        guard didChangeURLObserver == nil else { return }
        let name = Notification.Name(TabEventLabel.didChangeURL.rawValue)
        didChangeURLObserver = notificationCenter.addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Ecosia: Extract on main queue to avoid sending non-Sendable Notification; then hop to MainActor for actor work
            guard let tab = notification.object as? Tab,
                  let payload = notification.userInfo?["payload"] as? TabEvent,
                  case .didChangeURL(let url) = payload else { return }
            let tabUUID = tab.tabUUID
            EcosiaLogger.invisibleTabs.debug("didChangeURL: \(url) for tab: \(tabUUID)")
            Task { @MainActor in
                await self?.handlePageLoadFromNotification(tabUUID: tabUUID, url: url)
            }
        }
    }

    /// Handles page load (didChangeURL) for a tracked tab
    private func handlePageLoadFromNotification(tabUUID: TabUUID, url: URL) {
        guard authTabObservers[tabUUID] != nil else { return }
        EcosiaLogger.invisibleTabs.info("Ecosia page load detected for invisible tab: \(url)")
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await self?.handleAuthenticationCompletion(for: tabUUID)
        }
    }

    /// Handles authentication completion by closing the tab
    private func handleAuthenticationCompletion(for tabUUID: String, isFallback: Bool = false) {
        cleanupObserver(for: tabUUID)
        closeTab(with: tabUUID, isFallback: isFallback)
    }

    /// Closes a tab with the given UUID (uses instance tabManager; must be on MainActor).
    private func closeTab(with tabUUID: String, isFallback: Bool = false) {
        guard let tabManager = tabManager else {
            EcosiaLogger.invisibleTabs.notice("No tab manager available for closing tab: \(tabUUID)")
            return
        }

        guard let tab = tabManager.tabs.first(where: { $0.tabUUID == tabUUID }) else {
            EcosiaLogger.invisibleTabs.notice("Tab not found for closing: \(tabUUID)")
            return
        }

        // Only close if tab is still invisible
        guard tab.isInvisible else {
            EcosiaLogger.invisibleTabs.notice("Tab is no longer invisible, skipping close: \(tabUUID)")
            return
        }

        EcosiaLogger.invisibleTabs.info("Closing tab: \(tabUUID) \(isFallback ? "(fallback)" : "")")

        // Ecosia: TabManager protocol has removeTab(_ tabUUID: TabUUID) with no completion
        tabManager.removeTab(tab.tabUUID)
        selectAppropriateTabAfterRemoval(tabManager: tabManager)
        tabManager.cleanupInvisibleTabTracking()
        EcosiaLogger.invisibleTabs.info("Tab closed successfully: \(tabUUID)")
    }

    /// Selects an appropriate tab after removal if no tab is currently selected
    /// - Parameter tabManager: Tab manager to use for selection
    private func selectAppropriateTabAfterRemoval(tabManager: TabManager) {
        guard tabManager.selectedTab == nil else { return }

        // Try to select the last visible normal tab
        if let lastVisibleTab = tabManager.visibleNormalTabs.last {
            tabManager.selectTab(lastVisibleTab)
                            EcosiaLogger.invisibleTabs.info("Selected last visible normal tab")
        } else if let lastVisibleTab = tabManager.visibleTabs.last {
            tabManager.selectTab(lastVisibleTab)
                            EcosiaLogger.invisibleTabs.info("Selected last visible tab")
        }
    }

    /// Cleans up observer and timeout for a tab UUID
    /// - Parameter tabUUID: UUID of the tab to clean up
    private func cleanupObserver(for tabUUID: String) {
        // Remove auth notification observer
        if let observer = authTabObservers[tabUUID] {
            notificationCenter.removeObserver(observer)
            authTabObservers.removeValue(forKey: tabUUID)
        }

        // Remove page load notification observer
        if let pageLoadObserver = authTabObservers["\(tabUUID)_pageload"] {
            notificationCenter.removeObserver(pageLoadObserver)
            authTabObservers.removeValue(forKey: "\(tabUUID)_pageload")
        }

        // Cancel and remove fallback timeout
        if let task = fallbackTimeouts[tabUUID] {
            task.cancel()
            fallbackTimeouts.removeValue(forKey: tabUUID)
        }
    }

    // MARK: - Public Cleanup

    /// Cancels auto-close for a specific tab
    /// - Parameter tabUUID: UUID of the tab to cancel auto-close for
    func cancelAutoCloseForTab(_ tabUUID: String) {
        cleanupObserver(for: tabUUID)
        EcosiaLogger.invisibleTabs.info("Cancelled auto-close for tab: \(tabUUID)")
    }

    /// Cancels auto-close for multiple tabs
    /// - Parameter tabUUIDs: Array of tab UUIDs to cancel auto-close for
    func cancelAutoCloseForTabs(_ tabUUIDs: [String]) {
        for tabUUID in tabUUIDs {
            cancelAutoCloseForTab(tabUUID)
        }
    }

    /// Cleans up all observers and timeouts
    func cleanupAllObservers() {
        // Clean up all observers
        for (tabUUID, observer) in authTabObservers {
            notificationCenter.removeObserver(observer)
            EcosiaLogger.invisibleTabs.info("Cleaned up observer for tab: \(tabUUID)")
        }

        // Cancel all timeouts
        for (tabUUID, task) in fallbackTimeouts {
            task.cancel()
            EcosiaLogger.invisibleTabs.info("Cancelled timeout for tab: \(tabUUID)")
        }

        // Clear dictionaries
        authTabObservers.removeAll()
        fallbackTimeouts.removeAll()

        EcosiaLogger.invisibleTabs.info("All observers and timeouts cleaned up")
    }

    /// Returns the current number of tabs being tracked for auto-close
    var trackedTabCount: Int {
        /*
         Each tab has two observers (auth + pageload), but we only want
         to count tabs, not individual observers
         */
        authTabObservers.keys.filter { !$0.contains("_pageload") }.count
    }

    /// Returns the UUIDs of all tabs currently being tracked for auto-close
    var trackedTabUUIDs: [String] {
        /*
         Filter out the pageload observer keys to get just the tab UUIDs
         */
        Array(authTabObservers.keys.filter { !$0.contains("_pageload") })
    }
}
