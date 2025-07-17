// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Configuration for tab creation and lifecycle
public struct TabConfig {
    public let urls: [URL]
    public let isPrivate: Bool
    public let autoClose: Bool
    public let autoCloseTimeout: TimeInterval
    public let maxConcurrentTabs: Int
    
    public init(
        urls: [URL],
        isPrivate: Bool = false,
        autoClose: Bool = true,
        autoCloseTimeout: TimeInterval = 10.0,
        maxConcurrentTabs: Int = 5
    ) {
        self.urls = urls
        self.isPrivate = isPrivate
        self.autoClose = autoClose
        self.autoCloseTimeout = autoCloseTimeout
        self.maxConcurrentTabs = maxConcurrentTabs
    }
}

/// Trigger conditions for tab auto-close
public enum CloseTrigger {
    case authStateChange(AuthState)
    case pageLoadComplete
    case timeout
    case manual
}

/// Filter for tab operations
public struct TabFilter {
    public let tabUUIDs: [String]?
    public let isInvisible: Bool?
    public let autoCloseEnabled: Bool?
    
    public init(tabUUIDs: [String]? = nil, isInvisible: Bool? = nil, autoCloseEnabled: Bool? = nil) {
        self.tabUUIDs = tabUUIDs
        self.isInvisible = isInvisible
        self.autoCloseEnabled = autoCloseEnabled
    }
}

/// Result of tab lifecycle operations
public enum TabLifecycleResult {
    case success([Client.Tab])
    case partialSuccess([Client.Tab], warnings: [String])
    case failure(TabLifecycleError)
}

/// Tab lifecycle operation errors
public enum TabLifecycleError: Error, Equatable {
    case tabCreationFailed(String)
    case autoCloseSetupFailed(String)
    case tabManagerUnavailable
    case invalidConfiguration(String)
    case tooManyConcurrentTabs(Int)
}

/// Protocol for tab lifecycle management operations
public protocol TabLifecycleManaging {
    func createInvisibleTabs(config: TabConfig, completion: (([Client.Tab]) -> Void)?) -> TabLifecycleResult
    func setupAutoClose(tabs: [Client.Tab], trigger: CloseTrigger, timeout: TimeInterval)
    func cleanupTabs(matching filter: TabFilter)
    func cancelAutoClose(for tabUUIDs: [String])
    func getInvisibleTabs() -> [Client.Tab]
}

/// Centralized manager for tab creation, auto-close, and cleanup operations
/// Consolidates logic previously scattered across multiple classes
public final class TabLifecycleManager: TabLifecycleManaging {
    
    // MARK: - Properties
    
    /// Weak reference to browser view controller for tab operations
    private weak var browserViewController: BrowserViewController?
    
    /// Weak reference to tab manager
    private weak var tabManager: TabManager?
    
    /// Reference to invisible tab manager for visibility tracking
    private let invisibleTabManager: InvisibleTabManaging
    
    /// Reference to auto-close manager for cleanup operations
    private let autoCloseManager: TabAutoCloseManager
    
    /// Queue for thread-safe operations
    private let operationQueue = DispatchQueue(label: "com.ecosia.tabLifecycle", attributes: .concurrent)
    
    // MARK: - Initialization
    
    /// Initializes the tab lifecycle manager with dependencies
    /// - Parameters:
    ///   - browserViewController: Browser view controller for tab operations
    ///   - tabManager: Tab manager for tab operations
    ///   - invisibleTabManager: Manager for invisible tab tracking
    ///   - autoCloseManager: Manager for auto-close operations
    public init(
        browserViewController: BrowserViewController,
        tabManager: TabManager? = nil,
        invisibleTabManager: InvisibleTabManaging = InvisibleTabManager.shared,
        autoCloseManager: TabAutoCloseManager = TabAutoCloseManager.shared
    ) {
        self.browserViewController = browserViewController
        self.tabManager = tabManager ?? browserViewController.tabManager
        self.invisibleTabManager = invisibleTabManager
        self.autoCloseManager = autoCloseManager
        
        // Initialize auto-close manager with tab manager
        autoCloseManager.setTabManager(self.tabManager)
        
        EcosiaLogger.invisibleTabs.info("TabLifecycleManager initialized")
    }
    
    // MARK: - Tab Creation
    
    public func createInvisibleTabs(config: TabConfig, completion: (([Client.Tab]) -> Void)?) -> TabLifecycleResult {
        // Validate configuration
        guard !config.urls.isEmpty else {
            return .failure(.invalidConfiguration("No URLs provided"))
        }
        
        guard config.urls.count <= config.maxConcurrentTabs else {
            return .failure(.tooManyConcurrentTabs(config.urls.count))
        }
        
        guard let tabManager = tabManager else {
            return .failure(.tabManagerUnavailable)
        }
        
        var createdTabs: [Client.Tab] = []
        var warnings: [String] = []
        
        EcosiaLogger.invisibleTabs.info("Creating \(config.urls.count) invisible tabs")
        
        for url in config.urls {
            do {
                let tab = try createSingleTab(url: url, isPrivate: config.isPrivate, tabManager: tabManager)
                
                // Mark as invisible
                invisibleTabManager.markTabAsInvisible(tab)
                
                // Setup auto-close if requested
                if config.autoClose {
                    setupAutoCloseForTab(tab, timeout: config.autoCloseTimeout)
                }
                
                createdTabs.append(tab)
                
            } catch {
                warnings.append("Failed to create tab for \(url): \(error)")
                EcosiaLogger.invisibleTabs.error("Failed to create tab for \(url): \(error)")
            }
        }
        
        // Call completion callback
        completion?(createdTabs)
        
        EcosiaLogger.invisibleTabs.info("Created \(createdTabs.count) invisible tabs successfully")
        
        if warnings.isEmpty {
            return .success(createdTabs)
        } else {
            return .partialSuccess(createdTabs, warnings: warnings)
        }
    }
    
    // MARK: - Auto-Close Management
    
    public func setupAutoClose(tabs: [Client.Tab], trigger: CloseTrigger, timeout: TimeInterval) {
        let invisibleTabs = tabs.filter { $0.isInvisible }
        
        guard !invisibleTabs.isEmpty else {
            EcosiaLogger.invisibleTabs.notice("No invisible tabs to setup auto-close for")
            return
        }
        
        EcosiaLogger.invisibleTabs.info("Setting up auto-close for \(invisibleTabs.count) tabs")
        
        for tab in invisibleTabs {
            setupAutoCloseForTab(tab, timeout: timeout)
        }
    }
    
    public func cancelAutoClose(for tabUUIDs: [String]) {
        EcosiaLogger.invisibleTabs.info("Cancelling auto-close for \(tabUUIDs.count) tabs")
        
        for uuid in tabUUIDs {
            autoCloseManager.cancelAutoCloseForTab(uuid)
        }
    }
    
    // MARK: - Tab Cleanup
    
    public func cleanupTabs(matching filter: TabFilter) {
        operationQueue.async { [weak self] in
            self?.performTabCleanup(with: filter)
        }
    }
    
    // MARK: - Tab Queries
    
    public func getInvisibleTabs() -> [Client.Tab] {
        guard let tabManager = tabManager else {
            return []
        }
        
        let invisibleUUIDs = invisibleTabManager.invisibleTabUUIDs
        return tabManager.tabs.filter { invisibleUUIDs.contains($0.tabUUID) }
    }
    
    // MARK: - Private Implementation
    
    private func createSingleTab(url: URL, isPrivate: Bool, tabManager: TabManager) throws -> Client.Tab {
        let tab = tabManager.addTab(
            PrivilegedRequest(url: url),
            afterTab: nil,
            flushToDisk: false,
            zombie: false,
            isPrivate: isPrivate
        )
        
        guard let createdTab = tab else {
            throw TabLifecycleError.tabCreationFailed("Failed to create tab for URL: \(url)")
        }
        
        return createdTab
    }
    
    private func setupAutoCloseForTab(_ tab: Client.Tab, timeout: TimeInterval) {
        autoCloseManager.setupAutoCloseForTab(
            tab,
            on: .EcosiaAuthStateChanged,
            timeout: timeout
        )
    }
    
    private func performTabCleanup(with filter: TabFilter) {
        guard let tabManager = tabManager else {
            EcosiaLogger.invisibleTabs.error("TabManager unavailable for cleanup")
            return
        }
        
        let tabsToCleanup = getTabsMatchingFilter(filter, from: tabManager.tabs)
        
        DispatchQueue.main.async { [weak self] in
            for tab in tabsToCleanup {
                self?.cleanupSingleTab(tab, tabManager: tabManager)
            }
            
            EcosiaLogger.invisibleTabs.info("Cleaned up \(tabsToCleanup.count) tabs")
        }
    }
    
    private func getTabsMatchingFilter(_ filter: TabFilter, from tabs: [Client.Tab]) -> [Client.Tab] {
        return tabs.filter { tab in
            // Filter by tab UUIDs if specified
            if let targetUUIDs = filter.tabUUIDs {
                guard targetUUIDs.contains(tab.tabUUID) else { return false }
            }
            
            // Filter by invisibility if specified
            if let isInvisible = filter.isInvisible {
                let isTabInvisible = invisibleTabManager.invisibleTabUUIDs.contains(tab.tabUUID)
                guard isTabInvisible == isInvisible else { return false }
            }
            
            // Filter by auto-close enabled if specified
            if let autoCloseEnabled = filter.autoCloseEnabled {
                let hasAutoClose = autoCloseManager.isAutoCloseEnabled(for: tab.tabUUID)
                guard hasAutoClose == autoCloseEnabled else { return false }
            }
            
            return true
        }
    }
    
    private func cleanupSingleTab(_ tab: Client.Tab, tabManager: TabManager) {
        // Cancel auto-close
        autoCloseManager.cancelAutoCloseForTab(tab.tabUUID)
        
        // Mark as visible (removes from invisible tracking)
        invisibleTabManager.markTabAsVisible(tab)
        
        // Remove the tab
        tabManager.removeTab(tab)
        
        EcosiaLogger.invisibleTabs.debug("Cleaned up tab: \(tab.tabUUID)")
    }
}

// MARK: - TabAutoCloseManager Extension

extension TabAutoCloseManager {
    /// Checks if auto-close is enabled for a specific tab
    /// - Parameter tabUUID: UUID of the tab to check
    /// - Returns: True if auto-close is enabled, false otherwise
    func isAutoCloseEnabled(for tabUUID: String) -> Bool {
        // This would need to be implemented in TabAutoCloseManager
        // For now, return false as a safe default
        return false
    }
} 