// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Internal API for invisible tab management
/// Provides a clean interface for creating and managing invisible tabs across the app
final class InvisibleTabAPI {

    // MARK: - Singleton

    /// Shared instance for app-wide invisible tab management
    static let shared = InvisibleTabAPI()

    // MARK: - Properties

    /// Weak reference to browser view controller for tab operations
    private static weak var browserViewController: BrowserViewController?

    /// Weak reference to tab manager for tab operations
    private weak var tabManager: TabManager?

    /// Configuration for invisible tab behavior
    struct Configuration {
        /// Default timeout for auto-close fallback
        static var defaultTimeout: TimeInterval = TabAutoCloseConfig.fallbackTimeout

        /// Maximum concurrent invisible tabs
        static var maxConcurrentTabs: Int = TabAutoCloseConfig.maxConcurrentAutoCloseTabs

        /// Whether to enable debug logging
        static var debugLogging: Bool = true
    }

    // MARK: - Initialization

    /// Private initializer for singleton pattern
    private init() {}

    /// Initializes the API with a browser view controller
    /// - Parameter browserViewController: The browser view controller to use for tab operations
    static func initialize(with browserViewController: BrowserViewController) {
        self.browserViewController = browserViewController

        // Initialize shared instance
        shared.tabManager = browserViewController.tabManager

        // Initialize auto-close manager with tab manager
        TabAutoCloseManager.shared.setTabManager(browserViewController.tabManager)

        if Configuration.debugLogging {
            print("🔧 InvisibleTabAPI - Initialized with BrowserViewController")
        }
    }

    // MARK: - Instance Methods for Testing

    /// Sets the tab manager for instance operations
    /// - Parameter tabManager: The tab manager to use, or nil to clear
    func setTabManager(_ tabManager: TabManager?) {
        self.tabManager = tabManager
        if let tabManager = tabManager {
            TabAutoCloseManager.shared.setTabManager(tabManager)
        }
    }

    /// Marks a tab as invisible (instance method)
    /// - Parameter tab: The tab to mark as invisible
    /// - Returns: True if successful, false otherwise
    func markTabAsInvisible(_ tab: Tab) -> Bool {
        // For now, always enabled - can be made configurable later
        InvisibleTabManager.shared.markTabAsInvisible(tab)
        return true
    }

    /// Marks a tab as visible (instance method)
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
    func setupAutoCloseForTab(_ tab: Tab, timeout: TimeInterval? = nil, on notification: Notification.Name? = nil) -> Bool {
        guard let tabManager = tabManager else {
            return false
        }

        let actualTimeout = timeout ?? TabAutoCloseConfig.fallbackTimeout
        let actualNotification = notification ?? .EcosiaAuthStateChanged

        TabAutoCloseManager.shared.setupAutoCloseForTab(tab,
                                                        on: actualNotification,
                                                        timeout: actualTimeout)
        return true
    }

    /// Sets up auto-close for multiple tabs
    /// - Parameters:
    ///   - tabs: The tabs to set up auto-close for
    ///   - timeout: Optional timeout override
    ///   - notification: Optional notification name override
    /// - Returns: True if successful, false otherwise
    func setupAutoCloseForTabs(_ tabs: [Tab], timeout: TimeInterval? = nil, on notification: Notification.Name? = nil) -> Bool {
        guard let tabManager = tabManager else {
            return false
        }

        let actualTimeout = timeout ?? TabAutoCloseConfig.fallbackTimeout
        let actualNotification = notification ?? .EcosiaAuthStateChanged

        TabAutoCloseManager.shared.setupAutoCloseForTabs(tabs,
                                                         on: actualNotification,
                                                         timeout: actualTimeout)
        return true
    }

    /// Sets up auto-close for a tab with configuration object
    /// - Parameters:
    ///   - tab: The tab to setup auto-close for
    ///   - config: Configuration object with timeout and notification settings
    /// - Returns: True if successful, false otherwise
    func setupAutoCloseForTab(_ tab: Tab, config: InvisibleTabConfiguration) -> Bool {
        guard let tabManager = tabManager else {
            return false
        }

        guard config.isValid() else {
            return false
        }

        TabAutoCloseManager.shared.setupAutoCloseForTab(
            tab,
            on: config.authCompleteNotification,
            timeout: config.fallbackTimeout
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
    /// - Returns: Array of visible tabs
    func getVisibleTabs() -> [Tab] {
        guard let tabManager = tabManager else {
            return []
        }

        return VisibleTabProvider.getVisibleTabs(from: tabManager.tabs)
    }

    /// Gets all invisible tabs
    /// - Returns: Array of invisible tabs
    func getInvisibleTabs() -> [Tab] {
        guard let tabManager = tabManager else {
            return []
        }

        return VisibleTabProvider.getInvisibleTabs(from: tabManager.tabs)
    }

    /// Gets visible normal tabs
    /// - Returns: Array of visible normal tabs
    func getVisibleNormalTabs() -> [Tab] {
        guard let tabManager = tabManager else {
            return []
        }

        return VisibleTabProvider.getVisibleTabs(from: tabManager.tabs).filter { !$0.isPrivate }
    }

    /// Gets visible private tabs
    /// - Returns: Array of visible private tabs
    func getVisiblePrivateTabs() -> [Tab] {
        guard let tabManager = tabManager else {
            return []
        }

        return VisibleTabProvider.getVisibleTabs(from: tabManager.tabs).filter { $0.isPrivate }
    }

    /// Gets total tab count
    var totalTabsCount: Int {
        return tabManager?.tabs.count ?? 0
    }

    /// Gets visible tab count
    var visibleTabsCount: Int {
        return getVisibleTabs().count
    }

    /// Gets invisible tab count
    var invisibleTabsCount: Int {
        return getInvisibleTabs().count
    }

    /// Gets tracked tab count (for auto-close)
    var trackedTabsCount: Int {
        return TabAutoCloseManager.shared.trackedTabCount
    }

    /// Cleans up all tracking
    func cleanupAllTracking() {
        TabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()
    }

    /// Cleans up removed tabs
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
    static func createInvisibleTab(for url: URL,
                                         isPrivate: Bool = false,
                                         autoClose: Bool = true,
                                         completion: ((Tab?) -> Void)? = nil) -> Tab? {

        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            completion?(nil)
            return nil
        }

        let tab = browserViewController.createInvisibleTab(for: url, isPrivate: isPrivate, autoClose: autoClose)

        if Configuration.debugLogging {
            print("✅ InvisibleTabAPI - Created invisible tab for: \(url.absoluteString)")
        }

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
    static func createInvisibleAuthTab(for url: URL,
                                             isPrivate: Bool = false,
                                             completion: ((Tab?) -> Void)? = nil) -> Tab? {

        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            completion?(nil)
            return nil
        }

        let tab = browserViewController.createInvisibleAuthTab(for: url, isPrivate: isPrivate)

        if Configuration.debugLogging {
            print("🔐 InvisibleTabAPI - Created invisible auth tab for: \(url.absoluteString)")
        }

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
    static func createInvisibleTabs(for urls: [URL],
                                          isPrivate: Bool = false,
                                          autoClose: Bool = true,
                                          completion: (([Tab]) -> Void)? = nil) -> [Tab] {

        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            completion?([])
            return []
        }

        guard urls.count <= Configuration.maxConcurrentTabs else {
            print("⚠️ InvisibleTabAPI - Too many URLs for concurrent invisible tabs: \(urls.count)")
            completion?([])
            return []
        }

        let tabs = browserViewController.createInvisibleTabs(for: urls, isPrivate: isPrivate, autoClose: autoClose)

        if Configuration.debugLogging {
            print("✅ InvisibleTabAPI - Created \(tabs.count) invisible tabs")
        }

        completion?(tabs)
        return tabs
    }

    // MARK: - Tab Management

    /// Returns the count of visible tabs (excludes invisible tabs)
    static func getVisibleTabCount() -> Int {
        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            return 0
        }

        return browserViewController.tabManager.visibleTabCount
    }

    /// Returns the count of invisible tabs
    static func getInvisibleTabCount() -> Int {
        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            return 0
        }

        return browserViewController.invisibleTabCount
    }

    /// Returns all invisible tabs
    static func getInvisibleTabs() -> [Tab] {
        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            return []
        }

        return browserViewController.invisibleTabs
    }

    /// Returns all visible tabs
    static func getVisibleTabs() -> [Tab] {
        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            return []
        }

        return browserViewController.tabManager.visibleTabs
    }

    /// Closes all invisible tabs
    /// - Parameter completion: Optional completion handler
    static func closeAllInvisibleTabs(completion: (() -> Void)? = nil) {
        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            completion?()
            return
        }

        browserViewController.closeAllInvisibleTabs(completion: completion)

        if Configuration.debugLogging {
            print("🗑️ InvisibleTabAPI - Closed all invisible tabs")
        }
    }

    /// Closes invisible tabs matching a condition
    /// - Parameters:
    ///   - condition: The condition to match
    ///   - completion: Optional completion handler
    static func closeInvisibleTabs(where condition: @escaping (Tab) -> Bool, completion: (() -> Void)? = nil) {
        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            completion?()
            return
        }

        browserViewController.closeInvisibleTabs(where: condition, completion: completion)

        if Configuration.debugLogging {
            print("🗑️ InvisibleTabAPI - Closed matching invisible tabs")
        }
    }

    // MARK: - Auto-Close Management

    /// Cancels auto-close for a specific tab
    /// - Parameter tabUUID: UUID of the tab to cancel auto-close for
    static func cancelAutoCloseForTab(_ tabUUID: String) {
        TabAutoCloseManager.shared.cancelAutoCloseForTab(tabUUID)

        if Configuration.debugLogging {
            print("🚫 InvisibleTabAPI - Cancelled auto-close for tab: \(tabUUID)")
        }
    }

    /// Cancels auto-close for multiple tabs
    /// - Parameter tabUUIDs: Array of tab UUIDs to cancel auto-close for
    static func cancelAutoCloseForTabs(_ tabUUIDs: [String]) {
        TabAutoCloseManager.shared.cancelAutoCloseForTabs(tabUUIDs)

        if Configuration.debugLogging {
            print("🚫 InvisibleTabAPI - Cancelled auto-close for \(tabUUIDs.count) tabs")
        }
    }

    /// Returns the number of tabs currently tracked for auto-close
    static func getTrackedTabCount() -> Int {
        return TabAutoCloseManager.shared.trackedTabCount
    }

    /// Returns the UUIDs of all tabs currently tracked for auto-close
    static func getTrackedTabUUIDs() -> [String] {
        return TabAutoCloseManager.shared.trackedTabUUIDs
    }

    // MARK: - Utility

    /// Checks if a specific tab is invisible
    /// - Parameter tab: The tab to check
    /// - Returns: True if the tab is invisible, false otherwise
    static func isTabInvisible(_ tab: Tab) -> Bool {
        return tab.isInvisible
    }

    /// Marks a tab as invisible
    /// - Parameter tab: The tab to mark as invisible
    static func markTabAsInvisible(_ tab: Tab) {
        tab.isInvisible = true

        if Configuration.debugLogging {
            print("👻 InvisibleTabAPI - Marked tab as invisible: \(tab.tabUUID)")
        }
    }

    /// Marks a tab as visible
    /// - Parameter tab: The tab to mark as visible
    static func markTabAsVisible(_ tab: Tab) {
        tab.isInvisible = false

        if Configuration.debugLogging {
            print("👁️ InvisibleTabAPI - Marked tab as visible: \(tab.tabUUID)")
        }
    }

    /// Returns a summary of invisible tab state for debugging
    static func getInvisibleTabSummary() -> String {
        guard let browserViewController = browserViewController else {
            return "InvisibleTabAPI - BrowserViewController not initialized"
        }

        return browserViewController.invisibleTabSummary
    }

    /// Prints invisible tab summary to console
    static func printInvisibleTabSummary() {
        print("🔍 " + getInvisibleTabSummary())
    }

    // MARK: - Cleanup

    /// Cleans up all invisible tab resources
    /// Should be called during app termination or when resetting tab state
    static func cleanup() {
        guard let browserViewController = browserViewController else {
            print("⚠️ InvisibleTabAPI - BrowserViewController not initialized")
            return
        }

        browserViewController.cleanupInvisibleTabResources()

        if Configuration.debugLogging {
            print("🧹 InvisibleTabAPI - Cleanup completed")
        }
    }

    /// Resets the API (primarily for testing)
    static func reset() {
        browserViewController = nil
        TabAutoCloseManager.shared.cleanupAllObservers()
        InvisibleTabManager.shared.clearAllInvisibleTabs()

        if Configuration.debugLogging {
            print("🔄 InvisibleTabAPI - Reset completed")
        }
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
