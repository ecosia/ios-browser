// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// A local data provider for fetching What's New items based on app version updates.
final class WhatsNewLocalDataProvider: WhatsNewDataProvider {
    
    /// The version from which the app was last updated. Optional in case this is the first run
    /// or previous upgrading from an implmention that didn't have this one in the first place.
    private var fromVersion: Version?
    
    /// The current version of the app.
    private let toVersion = Version(AppInfo.ecosiaAppVersion)
    
    /// Default initializer.
    init() {}
    
    /// The items we would like to attempt to show in the update sheet
    private let whatsNewItems: [Version: [WhatsNewItem]] = [
        Version("9.0.0")!: [
            WhatsNewItem(imageURL: URL.localURLForImageset(name: "tree", withExtension: "pdf"),
                                       title: .localized(.whatsNewFirstItemTitle),
                                       subtitle: .localized(.whatsNewFirstItemDescription)),
            WhatsNewItem(imageURL: URL.localURLForImageset(name: "customisation", withExtension: "pdf"),
                                       title: .localized(.whatsNewSecondItemTitle),
                                       subtitle: .localized(.whatsNewSecondItemDescription))
        ]
    ]
            
    /// Fetches an array of What's New items to display.
    ///
    /// - Throws: An error if fetching fails.
    ///
    /// - Returns: An array of `WhatsNewItem` to display.
    func getData() throws -> [WhatsNewItem] {
                
        fromVersion = Version.retrievePreviousVersionElseSaveCurrent(toVersion)
        
        // Ensure both fromVersion and toVersion are available.
        guard let fromVersion, let toVersion else { return [] }
        
        // Get the version range and corresponding What's New items.
        let versionRange = getVersionRange(from: fromVersion, to: toVersion)
        var items: [WhatsNewItem] = []
        for version in versionRange {
            if let newItems = whatsNewItems[version] {
                items.append(contentsOf: newItems)
            }
        }
        return items
    }
    
    /// Private helper to fetch version range.
    ///
    /// - Parameters:
    ///   - from: Starting `Version`.
    ///   - to: Ending `Version`.
    ///
    /// - Returns: An array of `Version` between from and to, inclusive.
    private func getVersionRange(from: Version, to: Version) -> [Version] {
        let allVersions = Array(whatsNewItems.keys).sorted()
        guard let fromIndex = allVersions.firstIndex(of: from),
              let toIndex = allVersions.firstIndex(of: to) else {
            return []
        }
        return Array(allVersions[fromIndex...toIndex])
    }
}
