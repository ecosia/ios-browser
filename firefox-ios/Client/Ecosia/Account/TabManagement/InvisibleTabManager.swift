// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Centralized manager for invisible tab state and operations
/// Handles tracking invisible tabs and provides filtering capabilities
final class InvisibleTabManager: InvisibleTabManaging {

    // MARK: - Properties

    /// Singleton instance for app-wide invisible tab management
    static let shared = InvisibleTabManager()

    /// Set of tab UUIDs that are currently invisible
    private var _invisibleTabUUIDs = Set<String>()

    /// Queue for thread-safe access to invisible tab state
    private let accessQueue = DispatchQueue(label: "com.ecosia.invisibleTabs", attributes: .concurrent)

    /// Notification center for posting tab visibility changes
    private let notificationCenter: NotificationCenter

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    /// - Parameter notificationCenter: Notification center for posting changes, defaults to default center
    private init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Public Interface

    var invisibleTabUUIDs: Set<String> {
        return accessQueue.sync { _invisibleTabUUIDs }
    }

    var visibleTabCount: Int {
        // This implementation requires access to all tabs, which we'll handle via injection
        // For now, return 0 as this will be overridden by extensions
        return 0
    }

    var invisibleTabCount: Int {
        return invisibleTabUUIDs.count
    }

    // MARK: - Tab Management

    func markTabAsInvisible(_ tab: Tab) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            let wasInvisible = self._invisibleTabUUIDs.contains(tab.tabUUID)
            self._invisibleTabUUIDs.insert(tab.tabUUID)

            // Only post notification if state actually changed
            if !wasInvisible {
                DispatchQueue.main.async {
                    self.notificationCenter.post(
                        name: .TabBecameInvisible,
                        object: self,
                        userInfo: ["tabUUID": tab.tabUUID]
                    )
                }
                print("🔍 InvisibleTabManager - Tab marked as invisible: \(tab.tabUUID)")
            }
        }
    }

    func markTabAsVisible(_ tab: Tab) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            let wasInvisible = self._invisibleTabUUIDs.contains(tab.tabUUID)
            self._invisibleTabUUIDs.remove(tab.tabUUID)

            // Only post notification if state actually changed
            if wasInvisible {
                DispatchQueue.main.async {
                    self.notificationCenter.post(
                        name: .TabBecameVisible,
                        object: self,
                        userInfo: ["tabUUID": tab.tabUUID]
                    )
                }
                print("🔍 InvisibleTabManager - Tab marked as visible: \(tab.tabUUID)")
            }
        }
    }

    func isTabInvisible(_ tab: Tab) -> Bool {
        return accessQueue.sync { _invisibleTabUUIDs.contains(tab.tabUUID) }
    }

    func getVisibleTabs(from tabs: [Tab]) -> [Tab] {
        let invisibleUUIDs = invisibleTabUUIDs
        return tabs.filter { !invisibleUUIDs.contains($0.tabUUID) }
    }

    func getInvisibleTabs(from tabs: [Tab]) -> [Tab] {
        let invisibleUUIDs = invisibleTabUUIDs
        return tabs.filter { invisibleUUIDs.contains($0.tabUUID) }
    }

    // MARK: - Cleanup

    /// Removes tracking for tabs that no longer exist
    /// - Parameter existingTabUUIDs: Set of tab UUIDs that still exist
    func cleanupRemovedTabs(existingTabUUIDs: Set<String>) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            let removedTabs = self._invisibleTabUUIDs.subtracting(existingTabUUIDs)

            if !removedTabs.isEmpty {
                self._invisibleTabUUIDs = self._invisibleTabUUIDs.intersection(existingTabUUIDs)

                DispatchQueue.main.async {
                    for tabUUID in removedTabs {
                        self.notificationCenter.post(
                            name: .InvisibleTabRemoved,
                            object: self,
                            userInfo: ["tabUUID": tabUUID]
                        )
                    }
                }
                print("🔍 InvisibleTabManager - Cleaned up \(removedTabs.count) removed tabs")
            }
        }
    }

    /// Clears all invisible tab tracking (for testing or reset scenarios)
    func clearAllInvisibleTabs() {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            let clearedTabs = self._invisibleTabUUIDs
            self._invisibleTabUUIDs.removeAll()

            DispatchQueue.main.async {
                self.notificationCenter.post(
                    name: .AllInvisibleTabsCleared,
                    object: self,
                    userInfo: ["clearedCount": clearedTabs.count]
                )
            }
            print("🔍 InvisibleTabManager - Cleared all invisible tabs (\(clearedTabs.count) tabs)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a tab becomes invisible
    static let TabBecameInvisible = Notification.Name("TabBecameInvisible")

    /// Posted when a tab becomes visible
    static let TabBecameVisible = Notification.Name("TabBecameVisible")

    /// Posted when an invisible tab is removed from tracking
    static let InvisibleTabRemoved = Notification.Name("InvisibleTabRemoved")

    /// Posted when all invisible tabs are cleared
    static let AllInvisibleTabsCleared = Notification.Name("AllInvisibleTabsCleared")
}
