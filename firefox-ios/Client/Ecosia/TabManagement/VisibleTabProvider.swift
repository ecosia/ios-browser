// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Utility class for providing filtered tab collections and helper methods
/// Centralizes logic for working with visible tabs across the app
final class VisibleTabProvider {
    
    /// Returns only visible tabs from the provided tab collection
    /// - Parameter tabs: Array of tabs to filter
    /// - Returns: Array containing only visible tabs
    static func getVisibleTabs(from tabs: [Tab]) -> [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: tabs)
    }
    
    /// Returns only invisible tabs from the provided tab collection
    /// - Parameter tabs: Array of tabs to filter
    /// - Returns: Array containing only invisible tabs
    static func getInvisibleTabs(from tabs: [Tab]) -> [Tab] {
        return InvisibleTabManager.shared.getInvisibleTabs(from: tabs)
    }
    
    /// Returns the count of visible tabs in the provided collection
    /// - Parameter tabs: Array of tabs to count
    /// - Returns: Number of visible tabs
    static func getVisibleCount(from tabs: [Tab]) -> Int {
        return getVisibleTabs(from: tabs).count
    }
    
    /// Returns the count of invisible tabs in the provided collection
    /// - Parameter tabs: Array of tabs to count
    /// - Returns: Number of invisible tabs
    static func getInvisibleCount(from tabs: [Tab]) -> Int {
        return getInvisibleTabs(from: tabs).count
    }
    
    /// Filters tabs based on visibility and additional conditions
    /// - Parameters:
    ///   - tabs: Array of tabs to filter
    ///   - includeInvisible: Whether to include invisible tabs in the result
    ///   - additionalFilter: Additional filter condition to apply
    /// - Returns: Filtered array of tabs
    static func filterTabs(from tabs: [Tab], 
                          includeInvisible: Bool = false,
                          additionalFilter: ((Tab) -> Bool)? = nil) -> [Tab] {
        var filteredTabs = includeInvisible ? tabs : getVisibleTabs(from: tabs)
        
        if let filter = additionalFilter {
            filteredTabs = filteredTabs.filter(filter)
        }
        
        return filteredTabs
    }
    
    /// Groups tabs by their visibility status
    /// - Parameter tabs: Array of tabs to group
    /// - Returns: Dictionary with 'visible' and 'invisible' keys containing respective tab arrays
    static func groupTabsByVisibility(from tabs: [Tab]) -> [String: [Tab]] {
        return [
            "visible": getVisibleTabs(from: tabs),
            "invisible": getInvisibleTabs(from: tabs)
        ]
    }
    
    /// Finds the first visible tab matching the given condition
    /// - Parameters:
    ///   - tabs: Array of tabs to search
    ///   - condition: Condition to match
    /// - Returns: First visible tab matching the condition, or nil if none found
    static func firstVisibleTab(from tabs: [Tab], where condition: (Tab) -> Bool) -> Tab? {
        return getVisibleTabs(from: tabs).first(where: condition)
    }
    
    /// Finds the last visible tab matching the given condition
    /// - Parameters:
    ///   - tabs: Array of tabs to search
    ///   - condition: Condition to match
    /// - Returns: Last visible tab matching the condition, or nil if none found
    static func lastVisibleTab(from tabs: [Tab], where condition: (Tab) -> Bool) -> Tab? {
        return getVisibleTabs(from: tabs).last(where: condition)
    }
    
    /// Checks if any tabs in the collection are invisible
    /// - Parameter tabs: Array of tabs to check
    /// - Returns: True if at least one tab is invisible, false otherwise
    static func hasInvisibleTabs(in tabs: [Tab]) -> Bool {
        return getInvisibleCount(from: tabs) > 0
    }
    
    /// Checks if all tabs in the collection are visible
    /// - Parameter tabs: Array of tabs to check
    /// - Returns: True if all tabs are visible, false otherwise
    static func allTabsAreVisible(in tabs: [Tab]) -> Bool {
        return getInvisibleCount(from: tabs) == 0
    }
    
    /// Returns a summary of tab visibility for debugging/logging purposes
    /// - Parameter tabs: Array of tabs to analyze
    /// - Returns: String describing the visibility breakdown
    static func getVisibilitySummary(for tabs: [Tab]) -> String {
        let visibleCount = getVisibleCount(from: tabs)
        let invisibleCount = getInvisibleCount(from: tabs)
        let total = tabs.count
        
        return "Tabs: \(total) total, \(visibleCount) visible, \(invisibleCount) invisible"
    }
} 