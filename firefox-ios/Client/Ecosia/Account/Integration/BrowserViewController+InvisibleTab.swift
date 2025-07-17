// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import WebKit
import Auth0
import Ecosia

/// Extension to integrate invisible tab functionality with BrowserViewController
/// Provides methods for creating and managing invisible tabs for authentication and other background operations
extension BrowserViewController {

    // MARK: - Invisible Tab Creation

    /// Creates an invisible tab for authentication or other background operations
    /// - Parameters:
    ///   - url: URL to load in the invisible tab
    ///   - isPrivate: Whether the tab should be private (default: false)
    ///   - autoClose: Whether to setup auto-close on authentication completion (default: true)
    /// - Returns: The created invisible tab
    func createInvisibleTab(for url: URL,
                            isPrivate: Bool = false,
                            autoClose: Bool = true) -> Tab {

        EcosiaLogger.invisibleTabs.info("Creating invisible tab for: \(url.absoluteString)")

        // Create the tab
        var newTab = Tab(profile: profile,
                         isPrivate: false,
                         windowUUID: tabManager.windowUUID)
        newTab.url = url
        newTab.isInvisible = true
        if let legacyTabManager = tabManager as? LegacyTabManager {
            legacyTabManager.configureTab(newTab,
                                          request: URLRequest(url: url),
                                          afterTab: nil,
                                          flushToDisk: true,
                                          zombie: false)
            EcosiaLogger.invisibleTabs.info("Tab added to LegacyTabManager, isInvisible: \(newTab.isInvisible)")
        } else {
            // Fallback for non-legacy tab managers - this shouldn't happen in current architecture
            newTab = tabManager.addTab(URLRequest(url: url), isPrivate: false)
            newTab.isInvisible = true
            EcosiaLogger.invisibleTabs.info("Tab added via fallback method, isInvisible: \(newTab.isInvisible)")
        }

        // Set up auto-close if requested
        if autoClose {
            setupAutoCloseForInvisibleTab(newTab)
        }

        // Initialize tab manager dependency in auto-close manager
        TabAutoCloseManager.shared.setTabManager(tabManager)
        return newTab
    }

    /// Creates an invisible tab for authentication purposes
    /// - Parameters:
    ///   - url: Authentication URL to load
    ///   - isPrivate: Whether the tab should be private (default: false)
    /// - Returns: The created invisible authentication tab
    func createInvisibleAuthTab(for url: URL, isPrivate: Bool = false) -> Tab {
        let tab = createInvisibleTab(for: url, isPrivate: isPrivate, autoClose: true)

        // Additional setup for authentication tabs
        setupAuthenticationTabBehavior(tab)

        return tab
    }

    /// Creates multiple invisible tabs for batch operations
    /// - Parameters:
    ///   - urls: Array of URLs to create tabs for
    ///   - isPrivate: Whether the tabs should be private (default: false)
    ///   - autoClose: Whether to setup auto-close for all tabs (default: true)
    /// - Returns: Array of created invisible tabs
    func createInvisibleTabs(for urls: [URL],
                            isPrivate: Bool = false,
                            autoClose: Bool = true) -> [Tab] {

        guard urls.count <= TabAutoCloseConfig.maxConcurrentAutoCloseTabs else {
            EcosiaLogger.invisibleTabs.notice("Too many URLs for concurrent invisible tabs: \(urls.count)")
            return []
        }

        var createdTabs: [Tab] = []

        for url in urls {
            let tab = createInvisibleTab(for: url, isPrivate: isPrivate, autoClose: autoClose)
            createdTabs.append(tab)
        }

        EcosiaLogger.invisibleTabs.info("Created \(createdTabs.count) invisible tabs")
        return createdTabs
    }

    // MARK: - Auto-Close Setup

    /// Sets up auto-close functionality for an invisible tab
    /// - Parameter tab: The invisible tab to setup auto-close for
    private func setupAutoCloseForInvisibleTab(_ tab: Tab) {
        guard tab.isInvisible else {
            EcosiaLogger.invisibleTabs.notice("Attempted to setup auto-close for visible tab")
            return
        }

        // Setup auto-close with authentication completion notification
        TabAutoCloseManager.shared.setupAutoCloseForTab(tab)

        EcosiaLogger.invisibleTabs.info("Auto-close setup for invisible tab: \(tab.tabUUID)")
    }

    /// Sets up authentication-specific behavior for invisible tabs
    /// - Parameter tab: The invisible authentication tab
    private func setupAuthenticationTabBehavior(_ tab: Tab) {
        // TODO: Set session token cookie if available
        // This will be implemented when Auth0 integration is complete
        /*
        if let url = tab.url, let webView = tab.webView {
            // Auth0 session setup will go here
        }
        */

        // Additional auth-specific setup can be added here
        EcosiaLogger.invisibleTabs.info("Authentication behavior setup for tab: \(tab.tabUUID)")
    }

    // MARK: - Invisible Tab Management

    /// Returns all currently invisible tabs
    var invisibleTabs: [Tab] {
        return tabManager.invisibleTabs
    }

    /// Returns the count of invisible tabs
    var invisibleTabCount: Int {
        return tabManager.invisibleTabCount
    }

    /// Closes all invisible tabs
    /// - Parameter completion: Optional completion handler
    func closeAllInvisibleTabs(completion: (() -> Void)? = nil) {
        let invisibleTabs = self.invisibleTabs

        guard !invisibleTabs.isEmpty else {
            EcosiaLogger.invisibleTabs.info("No invisible tabs to close")
            completion?()
            return
        }

        EcosiaLogger.invisibleTabs.info("Closing \(invisibleTabs.count) invisible tabs")

        // Cancel auto-close for all tabs
        let tabUUIDs = invisibleTabs.map { $0.tabUUID }
        TabAutoCloseManager.shared.cancelAutoCloseForTabs(tabUUIDs)

        // Close tabs
        for tab in invisibleTabs {
            tabManager.removeTab(tab)
        }

        // Clean up tracking
        tabManager.cleanupInvisibleTabTracking()

                    EcosiaLogger.invisibleTabs.info("All invisible tabs closed")
        completion?()
    }

    /// Finds invisible tabs matching a condition
    /// - Parameter condition: The condition to match
    /// - Returns: Array of invisible tabs matching the condition
    func findInvisibleTabs(where condition: (Tab) -> Bool) -> [Tab] {
        return invisibleTabs.filter(condition)
    }

    /// Closes invisible tabs matching a condition
    /// - Parameters:
    ///   - condition: The condition to match
    ///   - completion: Optional completion handler
    func closeInvisibleTabs(where condition: (Tab) -> Bool, completion: (() -> Void)? = nil) {
        let tabsToClose = findInvisibleTabs(where: condition)

        guard !tabsToClose.isEmpty else {
            EcosiaLogger.invisibleTabs.info("No invisible tabs match the condition")
            completion?()
            return
        }

        EcosiaLogger.invisibleTabs.info("Closing \(tabsToClose.count) matching invisible tabs")

        // Cancel auto-close for matching tabs
        let tabUUIDs = tabsToClose.map { $0.tabUUID }
        TabAutoCloseManager.shared.cancelAutoCloseForTabs(tabUUIDs)

        // Close tabs
        for tab in tabsToClose {
            tabManager.removeTab(tab)
        }

        // Clean up tracking
        tabManager.cleanupInvisibleTabTracking()

                    EcosiaLogger.invisibleTabs.info("Matching invisible tabs closed")
        completion?()
    }

    // MARK: - Cleanup

    /// Cleans up all invisible tab resources
    /// Should be called when BrowserViewController is deallocated
    func cleanupInvisibleTabResources() {
        // Clean up auto-close observers
        TabAutoCloseManager.shared.cleanupAllObservers()

        // Clean up invisible tab tracking
        tabManager.cleanupInvisibleTabTracking()

        EcosiaLogger.invisibleTabs.info("Invisible tab resources cleaned up")
    }

    // MARK: - Debugging

    /// Returns a summary of invisible tab state for debugging
    var invisibleTabSummary: String {
        let invisibleTabs = self.invisibleTabs
        let trackedCount = TabAutoCloseManager.shared.trackedTabCount

        return """
        Invisible Tabs Summary:
        - Total invisible tabs: \(invisibleTabs.count)
        - Tracked for auto-close: \(trackedCount)
        - Tab UUIDs: \(invisibleTabs.map { $0.tabUUID })
        """
    }

    /// Prints invisible tab summary to console
    func printInvisibleTabSummary() {
        EcosiaLogger.invisibleTabs.info("\(self.invisibleTabSummary)")
    }
}
