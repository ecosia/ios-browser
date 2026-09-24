// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class InvisibleTabManager {

    // MARK: - Singleton

    /// Thread-safe singleton using DispatchQueue for synchronization
    /// Safety: All mutable state is protected by concurrent DispatchQueue with barrier writes
    nonisolated(unsafe) static let shared = InvisibleTabManager()

    // MARK: - Private Properties

    private let queue = DispatchQueue(label: "ecosia.invisible.tabs", attributes: .concurrent)
    /// Keyed by tab, valued by owning window: the registry is process-wide but `cleanupRemovedTabs` is
    /// called per window, so entries must be attributable to a window to avoid one window's cleanup
    /// dropping another window's in-flight auth tab.
    private var _invisibleTabWindows: [TabUUID: WindowUUID] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Interface

    /// Array of invisible tab UUIDs
    var invisibleTabUUIDs: [TabUUID] {
        return queue.sync {
            Array(_invisibleTabWindows.keys)
        }
    }

    /// Check if a tab is invisible
    /// - Parameter tab: The tab to check
    /// - Returns: True if the tab is invisible
    func isTabInvisible(_ tab: Tab) -> Bool {
        return queue.sync {
            _invisibleTabWindows[tab.tabUUID] != nil
        }
    }

    /// Mark a tab as invisible
    /// - Parameter tab: The tab to mark as invisible
    func markTabAsInvisible(_ tab: Tab) {
        queue.sync(flags: .barrier) {
            _invisibleTabWindows[tab.tabUUID] = tab.windowUUID
        }
    }

    /// Mark a tab as visible
    /// - Parameter tab: The tab to mark as visible
    func markTabAsVisible(_ tab: Tab) {
        queue.sync(flags: .barrier) {
            _invisibleTabWindows.removeValue(forKey: tab.tabUUID)
        }
    }

    /// Get visible tabs from a collection
    /// - Parameter tabs: Collection of tabs to filter
    /// - Returns: Array of visible tabs
    func getVisibleTabs(from tabs: [Tab]) -> [Tab] {
        return queue.sync {
            tabs.filter { _invisibleTabWindows[$0.tabUUID] == nil }
        }
    }

    /// Get invisible tabs from a collection
    /// - Parameter tabs: Collection of tabs to filter
    /// - Returns: Array of invisible tabs
    func getInvisibleTabs(from tabs: [Tab]) -> [Tab] {
        return queue.sync {
            tabs.filter { _invisibleTabWindows[$0.tabUUID] != nil }
        }
    }

    /// Clean up tracking for removed tabs
    /// - Parameters:
    ///   - existingTabUUIDs: Set of tab UUIDs that still exist
    ///   - windowUUID: Window the caller owns; entries from other windows are left untouched
    func cleanupRemovedTabs(existingTabUUIDs: Set<TabUUID>, in windowUUID: WindowUUID) {
        queue.sync(flags: .barrier) {
            _invisibleTabWindows = _invisibleTabWindows.filter {
                $0.value != windowUUID || existingTabUUIDs.contains($0.key)
            }
        }
    }

    /// Clear all invisible tabs (useful for testing)
    func clearAllInvisibleTabs() {
        queue.sync(flags: .barrier) {
            _invisibleTabWindows.removeAll()
        }
    }
}
