// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// A local data provider for fetching What's New items based on app version updates.
final class WhatsNewLocalDataProvider: WhatsNewDataProvider {
    
    static let appVersionUpdateKey = "appVersionUpdateKey"
        
    /// The current app version provider is the DefaultAppVersionInfoProvider
    /// from which the Ecosia App Version is retrieved
    private let currentAppVersionProvider = DefaultAppVersionInfoProvider()
    
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
                        
        var fromVersion = Version.saved(forKey: Self.appVersionUpdateKey)
        var toVersion = Version(currentAppVersionProvider.version)!
        
        let isVersionNil = fromVersion == nil
        let isVersionLowerThanCurrent = fromVersion != nil && fromVersion! < toVersion
        
        if isVersionNil ||
            isVersionLowerThanCurrent {
            Version.updateFromCurrent(forKey: Self.appVersionUpdateKey)
        }
        
        // Ensure both fromVersion is available.
        guard let fromVersion = Version.saved(forKey: Self.appVersionUpdateKey) else { return [] }
        
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
        
        // Find the closest previous version or use the first one if `from` is older than all versions.
        let fromIndex = allVersions.lastIndex { $0 <= from } ?? 0

        // Find the index of `to` version or the last version if `to` is newer than all versions.
        let toIndex = allVersions.firstIndex { $0 >= to } ?? (allVersions.count - 1)
        
        // Return the range.
        return Array(allVersions[fromIndex...toIndex])
    }
}
