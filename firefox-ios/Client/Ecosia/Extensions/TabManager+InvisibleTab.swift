// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extension to add invisible tab filtering capabilities to existing TabManager
/// Provides filtered tab collections that exclude invisible tabs
///
/// Safety: All properties are nonisolated because InvisibleTabManager is thread-safe via DispatchQueue
extension TabManager {

    /// Returns the count of visible tabs only (excludes invisible tabs)
    /// This should be used for UI display purposes instead of the raw `count` property
    nonisolated var visibleTabCount: Int {
        return InvisibleTabManager.shared.getVisibleTabs(from: tabs).count
    }

    /// Returns the count of invisible tabs only
    nonisolated var invisibleTabCount: Int {
        return InvisibleTabManager.shared.getInvisibleTabs(from: tabs).count
    }

    /// Returns only visible normal tabs (excludes private and invisible tabs)
    /// This is the filtered equivalent of `normalTabs`
    nonisolated var visibleNormalTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: normalTabs)
    }

    /// Returns only visible private tabs (excludes invisible tabs)
    /// This is the filtered equivalent of `privateTabs`
    nonisolated var visiblePrivateTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: privateTabs)
    }

    /// Returns all invisible tabs
    nonisolated var invisibleTabs: [Tab] {
        return InvisibleTabManager.shared.getInvisibleTabs(from: tabs)
    }

    /// Returns all visible tabs (the opposite of invisibleTabs)
    nonisolated var visibleTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: tabs)
    }

    /// Cleanup invisible tab tracking when tabs are removed
    /// This should be called when tabs are removed to prevent memory leaks
    nonisolated func cleanupInvisibleTabTracking() {
        let existingTabUUIDs = Set(tabs.map { $0.tabUUID })
        InvisibleTabManager.shared.cleanupRemovedTabs(existingTabUUIDs: existingTabUUIDs)
    }
}
