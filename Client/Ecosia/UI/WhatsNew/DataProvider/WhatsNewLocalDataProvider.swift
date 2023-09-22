// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

/// A local data provider for fetching What's New items based on app version updates.
final class WhatsNewLocalDataProvider: WhatsNewDataProvider {
    
    static let appVersionUpdateKey = "appVersionUpdateKey"
    
    /// The version from which the app was last updated. Optional in case this is the first run
    /// or previous upgrading from an implmention that didn't have this one in the first place.
    private let fromVersion = Version.saved(forKey: WhatsNewLocalDataProvider.appVersionUpdateKey)
    
    /// The current version of the app.
    private var toVersion: Version {
        Version(currentAppVersionProvider.version)!
    }
    
    /// This value can be used to determine if the user should be presented with the What's New page.
    ///
    /// - Returns: `true` if the What's New page should be shown; otherwise, `false`.
    var shouldShowWhatsNewPage: Bool {
        evaluateVersionNeedsUpdate()
        let dataProviderVersionsString = getVersionRange().map { $0.description }
        guard let savedWhatsNewItemVersionsString = User.shared.whatsNewItemsVersionsShown else { return true }
        return savedWhatsNewItemVersionsString.allSatisfy { dataProviderVersionsString.contains($0) } == false
    }
    
    /// The current app version provider is the DefaultAppVersionInfoProvider
    /// from which the Ecosia App Version is retrieved
    private let currentAppVersionProvider = DefaultAppVersionInfoProvider()
    
    /// Default initializer.
    init() {}
    
    /// The items we would like to attempt to show in the update sheet
    private let whatsNewItems: [Version: [WhatsNewItem]] = [
        Version("9.0.0")!: [
            WhatsNewItem(image: UIImage(named: "tree"),
                         title: .localized(.whatsNewFirstItemTitle),
                         subtitle: .localized(.whatsNewFirstItemDescription)),
            WhatsNewItem(image: UIImage(named: "customisation"),
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
        
        evaluateVersionNeedsUpdate()
        
        // Ensure fromVersion is available.
        guard let fromVersion else { return [] }
        
        // Get the version range and corresponding What's New items.
        let versionRange = getVersionRange()
        var items: [WhatsNewItem] = []
        for version in versionRange {
            if let newItems = whatsNewItems[version] {
                items.append(contentsOf: newItems)
            }
        }
        return items
    }
    
    /// Evaluates if the stored app version needs to be updated to the current version.
    ///
    /// This function checks two conditions:
    /// 1. If `fromVersion` is `nil`, indicating no version was previously stored.
    /// 2. If `fromVersion` exists but is lower than `toVersion`, suggesting an app update.
    ///
    /// In either case, the stored app version is updated to the current version using the key `appVersionUpdateKey`.
    ///
    /// - Note: This function relies on the existence of `fromVersion` and `toVersion` properties in its scope and
    /// the `Version` type's ability to update stored versions.
    private func evaluateVersionNeedsUpdate() {
        let isVersionNil = fromVersion == nil
        let isVersionLowerThanCurrent = fromVersion != nil && fromVersion! < toVersion
        let isVersionSameAsCurrent = fromVersion != nil && fromVersion! == toVersion
                
        if isVersionNil || (isVersionLowerThanCurrent && !isVersionSameAsCurrent) {
            Version.updateFromCurrent(forKey: Self.appVersionUpdateKey)
        }
    }
    
    /// Private helper to fetch version range.
    ///
    /// - Returns: An array of `Version` between from and to, inclusive.
    func getVersionRange() -> [Version] {
        
        evaluateVersionNeedsUpdate()
        
        // Ensure fromVersion is available.
        guard let fromVersion = self.fromVersion else { return [] }
        
        // If there's no update (i.e., the versions are the same), we shouldn't return any versions.
        guard fromVersion != toVersion else { return [] }
        
        // Gather all versions
        let allVersions = Array(whatsNewItems.keys).sorted()
        
        // Ensure the `toVersion` is equal to or bigger than the smallest version in `whatsNewItems`
        guard toVersion >= allVersions.first! else { return [] }

        // Find the closest previous version or use the first one if `from` is older than all versions.
        let fromIndex = allVersions.lastIndex { $0 <= fromVersion } ?? 0

        // Find the index of `to` version or the last version if `to` is newer than all versions.
        let toIndex = allVersions.firstIndex { $0 >= toVersion } ?? (allVersions.count - 1)
        
        // Return the range.
        return Array(allVersions[fromIndex...toIndex])
    }
}
