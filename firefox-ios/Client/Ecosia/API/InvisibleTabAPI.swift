// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Internal API for invisible tab management
/// Provides a clean interface for creating and managing invisible tabs across the app
final class InvisibleTabAPI {
    
    // MARK: - Properties
    
    /// Weak reference to browser view controller for tab operations
    private static weak var browserViewController: BrowserViewController?
    
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
    
    /// Initializes the API with a browser view controller
    /// - Parameter browserViewController: The browser view controller to use for tab operations
    static func initialize(with browserViewController: BrowserViewController) {
        self.browserViewController = browserViewController
        
        // Initialize auto-close manager with tab manager
        TabAutoCloseManager.shared.setTabManager(browserViewController.tabManager)
        
        if Configuration.debugLogging {
            print("🔧 InvisibleTabAPI - Initialized with BrowserViewController")
        }
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