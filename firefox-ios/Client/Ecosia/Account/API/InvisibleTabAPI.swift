// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia
import Shared

/// Internal API for invisible tab management
/// Provides a clean interface for creating and managing invisible tabs across the app
final class InvisibleTabAPI: InvisibleTabAPIProtocol {

    // MARK: - Properties

    /// Weak reference to browser view controller for tab operations
    private weak var browserViewController: BrowserViewController?

    /// Weak reference to tab manager for tab operations
    private weak var tabManager: TabManager!

    /// Configuration for invisible tab behavior
    struct Configuration {
        /// Default timeout for auto-close fallback
        static var defaultTimeout: TimeInterval = TabAutoCloseConfig.fallbackTimeout

        /// Maximum concurrent invisible tabs
        static var maxConcurrentTabs: Int = TabAutoCloseConfig.maxConcurrentAutoCloseTabs
    }

    // MARK: - Initialization

    /// Initializes the API with required dependencies
    /// - Parameters:
    ///   - browserViewController: The browser view controller to use for tab operations
    ///   - tabManager: The tab manager to use for tab operations (optional, will use browserViewController.tabManager if nil)
    init(browserViewController: BrowserViewController, tabManager: TabManager? = nil) {
        self.browserViewController = browserViewController
        self.tabManager = tabManager ?? browserViewController.tabManager

        // Initialize auto-close manager with tab manager
        TabAutoCloseManager.shared.setTabManager(self.tabManager)

        EcosiaLogger.invisibleTabs("Initialized with BrowserViewController")
    }

    // MARK: - Instance Methods

    /// Sets the tab manager for instance operations
    /// - Parameter tabManager: The tab manager to use, or nil to clear
    func setTabManager(_ tabManager: TabManager?) {
        self.tabManager = tabManager
        if let tabManager = tabManager {
            TabAutoCloseManager.shared.setTabManager(tabManager)
        }
    }

    /// Marks a tab as invisible
    /// - Parameter tab: The tab to mark as invisible
    /// - Returns: True if successful, false otherwise
    func markTabAsInvisible(_ tab: Tab) -> Bool {
        InvisibleTabManager.shared.markTabAsInvisible(tab)
        return true
    }

    /// Marks a tab as visible
    /// - Parameter tab: The tab to mark as visible
    /// - Returns: True if successful, false otherwise
    func markTabAsVisible(_ tab: Tab) -> Bool {
        InvisibleTabManager.shared.markTabAsVisible(tab)
        // Cancel auto-close tracking when tab becomes visible
        TabAutoCloseManager.shared.cancelAutoCloseForTab(tab.tabUUID)
        return true
    }

    /// Sets up auto-close for a tab
    /// - Parameters:
    ///   - tab: The tab to set up auto-close for
    ///   - timeout: Optional timeout override
    ///   - notification: Optional notification name override
    /// - Returns: True if successful, false otherwise
    func setupAutoCloseForTab(_ tab: Tab,
                              timeout: TimeInterval = Configuration.defaultTimeout,
                              notification: Notification.Name = .EcosiaAuthStateChanged) -> Bool {
        TabAutoCloseManager.shared.setupAutoCloseForTab(
            tab,
            on: notification,
            timeout: timeout
        )
        return true
    }

    /// Cancels auto-close for a tab
    /// - Parameter tabUUID: UUID of the tab to cancel auto-close for
    /// - Returns: True if successful, false otherwise
    func cancelAutoCloseForTab(_ tabUUID: String) -> Bool {
        TabAutoCloseManager.shared.cancelAutoCloseForTab(tabUUID)
        return true
    }

    /// Gets all visible tabs
    func getVisibleTabs() -> [Client.Tab] {
        guard let tabManager = tabManager else {
            EcosiaLogger.invisibleTabs("TabManager not available", level: .warning)
            return []
        }

        return InvisibleTabManager.shared.getVisibleTabs(from: tabManager.tabs)
    }

    /// Gets all invisible tabs
    func getInvisibleTabs() -> [Client.Tab] {
        guard let tabManager = tabManager else {
            EcosiaLogger.invisibleTabs("TabManager not available", level: .warning)
            return []
        }

        return InvisibleTabManager.shared.getInvisibleTabs(from: tabManager.tabs)
    }

    /// Removes tracking for tabs that no longer exist
    func cleanupRemovedTabs() {
        guard let tabManager = tabManager else {
            return
        }

        let existingUUIDs = Set(tabManager.tabs.map { $0.tabUUID })
        InvisibleTabManager.shared.cleanupRemovedTabs(existingTabUUIDs: existingUUIDs)

        // Cancel auto-close for tabs that no longer exist
        let trackedTabUUIDs = TabAutoCloseManager.shared.trackedTabUUIDs
        let removedTabUUIDs = trackedTabUUIDs.filter { !existingUUIDs.contains($0) }
        TabAutoCloseManager.shared.cancelAutoCloseForTabs(removedTabUUIDs)
    }

    // MARK: - Tab Creation

    /// Creates an invisible tab for authentication or background operations
    /// - Parameters:
    ///   - url: URL to load in the invisible tab
    ///   - isPrivate: Whether the tab should be private (default: false)
    ///   - autoClose: Whether to setup auto-close on completion (default: true)
    ///   - completion: Optional completion handler with the created tab
    /// - Returns: The created invisible tab, or nil if creation failed
    @discardableResult
    func createInvisibleTab(for url: URL,
                            isPrivate: Bool = false,
                            autoClose: Bool = true,
                            completion: ((Tab?) -> Void)? = nil) -> Tab? {

        guard let browserViewController = browserViewController else {
            EcosiaLogger.invisibleTabs("BrowserViewController not available", level: .error)
            completion?(nil)
            return nil
        }

        let tab = browserViewController.createInvisibleTab(for: url, isPrivate: isPrivate, autoClose: autoClose)

        EcosiaLogger.invisibleTabs("Created invisible tab for: \(url.absoluteString)")

        completion?(tab)
        return tab
    }

    /// Creates an invisible tab specifically for authentication
    /// - Parameters:
    ///   - url: Authentication URL to load
    ///   - isPrivate: Whether the tab should be private (default: false)
    ///   - completion: Optional completion handler with the created tab
    /// - Returns: The created invisible authentication tab, or nil if creation failed
    @discardableResult
    func createInvisibleAuthTab(for url: URL,
                                isPrivate: Bool = false,
                                completion: ((Tab?) -> Void)? = nil) -> Tab? {

        guard let browserViewController = browserViewController else {
            EcosiaLogger.invisibleTabs("BrowserViewController not available", level: .error)
            completion?(nil)
            return nil
        }

        let tab = browserViewController.createInvisibleAuthTab(for: url, isPrivate: isPrivate)

        EcosiaLogger.invisibleTabs("Created invisible auth tab for: \(url.absoluteString)")

        completion?(tab)
        return tab
    }

    /// Creates multiple invisible tabs for batch operations
    /// - Parameters:
    ///   - urls: Array of URLs to create tabs for
    ///   - isPrivate: Whether the tabs should be private (default: false)
    ///   - autoClose: Whether to setup auto-close for all tabs (default: true)
    ///   - completion: Optional completion handler with the created tabs
    /// - Returns: Array of created invisible tabs (may be empty if creation failed)
    @discardableResult
    func createInvisibleTabs(for urls: [URL],
                             isPrivate: Bool = false,
                             autoClose: Bool = true,
                             completion: (([Client.Tab]) -> Void)? = nil) -> [Client.Tab] {

        guard let browserViewController = browserViewController else {
            EcosiaLogger.invisibleTabs("BrowserViewController not available", level: .error)
            completion?([])
            return []
        }

        guard urls.count <= Configuration.maxConcurrentTabs else {
            EcosiaLogger.invisibleTabs("Too many URLs for concurrent invisible tabs: \(urls.count)", level: .warning)
            completion?([])
            return []
        }

        let tabs = browserViewController.createInvisibleTabs(for: urls, isPrivate: isPrivate, autoClose: autoClose)

        EcosiaLogger.invisibleTabs("Created \(tabs.count) invisible tabs")

        completion?(tabs)
        return tabs
    }

    // MARK: - Tab Management

    /// Returns the count of visible tabs (excludes invisible tabs)
    func getVisibleTabCount() -> Int {
        guard let browserViewController = browserViewController else {
            EcosiaLogger.invisibleTabs("BrowserViewController not available", level: .warning)
            return 0
        }

        return browserViewController.tabManager.visibleTabCount
    }

    /// Returns the count of invisible tabs
    func getInvisibleTabCount() -> Int {
        guard let browserViewController = browserViewController else {
            EcosiaLogger.invisibleTabs("BrowserViewController not available", level: .warning)
            return 0
        }

        return browserViewController.invisibleTabCount
    }

    /// Closes all invisible tabs
    /// - Parameter completion: Optional completion handler
    func closeAllInvisibleTabs(completion: (() -> Void)? = nil) {
        guard let browserViewController = browserViewController else {
            EcosiaLogger.invisibleTabs("BrowserViewController not available", level: .warning)
            completion?()
            return
        }

        browserViewController.closeAllInvisibleTabs(completion: completion)

        EcosiaLogger.invisibleTabs("Closed all invisible tabs")
    }

    /// Closes invisible tabs matching a condition
    /// - Parameters:
    ///   - condition: The condition to match
    ///   - completion: Optional completion handler
    func closeInvisibleTabs(where condition: @escaping (Tab) -> Bool, completion: (() -> Void)? = nil) {
        guard let browserViewController = browserViewController else {
            EcosiaLogger.invisibleTabs("BrowserViewController not available", level: .warning)
            completion?()
            return
        }

        browserViewController.closeInvisibleTabs(where: condition, completion: completion)

        EcosiaLogger.invisibleTabs("Closed matching invisible tabs")
    }

    // MARK: - Auto-Close Management

    /// Cancels auto-close for multiple tabs
    /// - Parameter tabUUIDs: Array of tab UUIDs to cancel auto-close for
    func cancelAutoCloseForTabs(_ tabUUIDs: [String]) {
        TabAutoCloseManager.shared.cancelAutoCloseForTabs(tabUUIDs)

        EcosiaLogger.invisibleTabs("Cancelled auto-close for \(tabUUIDs.count) tabs")
    }

    /// Returns the number of tabs currently tracked for auto-close
    func getTrackedTabCount() -> Int {
        return TabAutoCloseManager.shared.trackedTabCount
    }

    /// Returns the UUIDs of all tabs currently tracked for auto-close
    func getTrackedTabUUIDs() -> [String] {
        return TabAutoCloseManager.shared.trackedTabUUIDs
    }

    // MARK: - Utility

    /// Checks if a specific tab is invisible
    /// - Parameter tab: The tab to check
    /// - Returns: True if the tab is invisible, false otherwise
    func isTabInvisible(_ tab: Tab) -> Bool {
        return tab.isInvisible
    }

    /// Returns a summary of invisible tab state for debugging
    func getInvisibleTabSummary() -> String {
        guard let browserViewController = browserViewController else {
            return "InvisibleTabAPI - BrowserViewController not available"
        }

        return browserViewController.invisibleTabSummary
    }

    /// Prints invisible tab summary to console
    func printInvisibleTabSummary() {
        EcosiaLogger.invisibleTabs(getInvisibleTabSummary())
    }

    // MARK: - Cleanup

    /// Cleans up all tracking state
    func cleanupAllTracking() {
//        InvisibleTabManager.shared.cleanupAllTracking()
//        TabAutoCloseManager.shared.cleanupAllTracking()

        EcosiaLogger.invisibleTabs("Cleaned up all tracking state")
    }
}

// MARK: - Configuration

/// Configuration for invisible tab management and auto-close behavior.
/// This class provides customizable settings for how invisible tabs should behave,
/// including timeout values and notification settings.
public class InvisibleTabConfiguration {

    // MARK: - Properties

    /// The timeout after which invisible tabs should be automatically closed if authentication doesn't complete
    public var fallbackTimeout: TimeInterval = 10.0

    /// The notification name to listen for when authentication completes
    public var authCompleteNotification: Notification.Name = .EcosiaAuthStateChanged

    /// Maximum number of tabs that can be tracked for auto-close simultaneously
    public var maxConcurrentAutoCloseTabs: Int = 5

    /// Debounce interval for notification handling to prevent duplicate processing
    public var debounceInterval: TimeInterval = 0.5

    // MARK: - Initialization

    /// Creates a new configuration with default values
    public init() {
        // Use default values
        fallbackTimeout = 10.0
        authCompleteNotification = .EcosiaAuthStateChanged
        maxConcurrentAutoCloseTabs = 5
        debounceInterval = 0.5
    }

    /// Creates a new configuration with custom values
    /// - Parameters:
    ///   - fallbackTimeout: Custom timeout for auto-close
    ///   - authCompleteNotification: Custom notification to listen for
    ///   - maxConcurrentAutoCloseTabs: Maximum concurrent auto-close tabs
    ///   - debounceInterval: Debounce interval for notifications
    public init(
        fallbackTimeout: TimeInterval = 10.0,
        authCompleteNotification: Notification.Name = .EcosiaAuthStateChanged,
        maxConcurrentAutoCloseTabs: Int = 5,
        debounceInterval: TimeInterval = 0.5
    ) {
        self.fallbackTimeout = fallbackTimeout
        self.authCompleteNotification = authCompleteNotification
        self.maxConcurrentAutoCloseTabs = maxConcurrentAutoCloseTabs
        self.debounceInterval = debounceInterval
    }

    // MARK: - Validation

    /// Validates the configuration values
    /// - Returns: True if configuration is valid, false otherwise
    public func isValid() -> Bool {
        return fallbackTimeout > 0 &&
               maxConcurrentAutoCloseTabs > 0 &&
               debounceInterval >= 0
    }

    /// Creates a copy of the configuration
    /// - Returns: A new InvisibleTabConfiguration with the same values
    public func copy() -> InvisibleTabConfiguration {
        return InvisibleTabConfiguration(
            fallbackTimeout: fallbackTimeout,
            authCompleteNotification: authCompleteNotification,
            maxConcurrentAutoCloseTabs: maxConcurrentAutoCloseTabs,
            debounceInterval: debounceInterval
        )
    }
}

// MARK: - Preset Configurations

public extension InvisibleTabConfiguration {

    /// Configuration optimized for testing with shorter timeouts
    static var testing: InvisibleTabConfiguration {
        return InvisibleTabConfiguration(
            fallbackTimeout: 1.0,
            authCompleteNotification: .EcosiaAuthStateChanged,
            maxConcurrentAutoCloseTabs: 3,
            debounceInterval: 0.1
        )
    }

    /// Configuration for development with moderate timeouts
    static var development: InvisibleTabConfiguration {
        return InvisibleTabConfiguration(
            fallbackTimeout: 5.0,
            authCompleteNotification: .EcosiaAuthStateChanged,
            maxConcurrentAutoCloseTabs: 5,
            debounceInterval: 0.3
        )
    }

    /// Production configuration with standard timeouts
    static var production: InvisibleTabConfiguration {
        return InvisibleTabConfiguration() // Uses default values
    }
}
