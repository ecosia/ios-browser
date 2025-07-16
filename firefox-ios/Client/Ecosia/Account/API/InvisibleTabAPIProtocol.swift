// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Protocol for invisible tab management operations
/// Enables dependency injection and testing for invisible tab functionality
protocol InvisibleTabAPIProtocol {
    /// Creates invisible tabs for the given URLs
    /// - Parameters:
    ///   - urls: Array of URLs to open in invisible tabs
    ///   - isPrivate: Whether the tabs should be private
    ///   - autoClose: Whether tabs should auto-close after authentication
    ///   - completion: Optional completion callback with created tabs
    /// - Returns: Array of created tabs
    func createInvisibleTabs(for urls: [URL], isPrivate: Bool, autoClose: Bool, completion: (([Client.Tab]) -> Void)?) -> [Client.Tab]

    /// Gets the current list of invisible tabs
    /// - Returns: Array of invisible tabs
    func getInvisibleTabs() -> [Client.Tab]

    /// Gets the count of tracked invisible tabs
    /// - Returns: Number of tracked tabs
    func getTrackedTabCount() -> Int

    /// Cancels auto-close for specified tab UUIDs
    /// - Parameter tabUUIDs: Array of tab UUIDs to cancel auto-close for
    func cancelAutoCloseForTabs(_ tabUUIDs: [String])
}
