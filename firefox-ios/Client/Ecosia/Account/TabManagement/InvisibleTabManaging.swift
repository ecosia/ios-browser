// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Protocol for managing invisible tabs functionality
/// Provides a clean interface for marking tabs as invisible and filtering them from UI
protocol InvisibleTabManaging {
    /// Marks a tab as invisible (hidden from user interface)
    /// - Parameter tab: The tab to mark as invisible
    func markTabAsInvisible(_ tab: Tab)

    /// Marks a tab as visible (shown in user interface)
    /// - Parameter tab: The tab to mark as visible
    func markTabAsVisible(_ tab: Tab)

    /// Checks if a tab is currently invisible
    /// - Parameter tab: The tab to check
    /// - Returns: True if the tab is invisible, false otherwise
    func isTabInvisible(_ tab: Tab) -> Bool

    /// Filters a tab collection to return only visible tabs
    /// - Parameter tabs: Array of tabs to filter
    /// - Returns: Array containing only visible tabs
    func getVisibleTabs(from tabs: [Tab]) -> [Tab]

    /// Filters a tab collection to return only invisible tabs
    /// - Parameter tabs: Array of tabs to filter
    /// - Returns: Array containing only invisible tabs
    func getInvisibleTabs(from tabs: [Tab]) -> [Tab]

    /// Returns the count of visible tabs
    var visibleTabCount: Int { get }

    /// Returns the count of invisible tabs
    var invisibleTabCount: Int { get }

    /// Returns all currently invisible tab UUIDs
    var invisibleTabUUIDs: Set<String> { get }
}
