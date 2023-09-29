// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

/// A local data provider for fetching What's New items based on app version updates.
final class WhatsNewLocalDataProvider: WhatsNewDataProvider {
        
    /// The version from which the app was last updated.
    private var fromVersion: Version? {
        Version(EcosiaInstallType.persistedCurrentVersion())
    }
    
    /// The current version of the app.
    private var toVersion: Version {
        Version(versionProvider.version)!
    }
    
    /// This value can be used to determine if the user should be presented with the What's New page.
    ///
    /// - Returns: `true` if the What's New page should be shown; otherwise, `false`.
    var shouldShowWhatsNewPage: Bool {
        return EcosiaInstallType.get() == .upgrade
    }

    /// The current app version provider from which the Ecosia App Version is retrieved
    private var versionProvider: AppVersionInfoProvider
    
    /// Default initializer.
    /// - Parameters:
    ///   - versionProvider: The current app version provider. Defaults to `DefaultAppVersionInfoProvider`
    init(versionProvider: AppVersionInfoProvider = DefaultAppVersionInfoProvider()) {
        self.versionProvider = versionProvider
    }
    
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
        
    /// Private helper to fetch version range.
    ///
    /// - Returns: An array of `Version` between from and to, inclusive.
    func getVersionRange() -> [Version] {
                
        // Ensure this is an upgrade scenario; otherwise, return an empty version range.
        guard EcosiaInstallType.get() == .upgrade else { return [] }

        // Ensure `fromVersion` is available; otherwise, return an empty version range.
        guard let fromVersion else { return [] }

        // Gather all versions
        let allVersions = Array(whatsNewItems.keys).sorted()
                
        // At this point in the logic, we are still in the upgrade scenario
        // however, if the fromVersion and the toVersion will result being the same
        // we will assume that we have upgraded to a version that didn't have this logic in place before
        // There is no need to enforce the check for `EcosiaInstallType.get() == .buildUpdate`
        // As we currently checked the `.upgrade` scenario above.
        if fromVersion == toVersion {
            return allVersions.filter { $0 == toVersion } ?? []
        }
                
        // Gather first item in `allVersions` array
        guard let firstItemInAllVersions = allVersions.first else { return [] }
        
        // Ensure the `toVersion` is equal to or bigger than the smallest version in `whatsNewItems`
        guard toVersion >= firstItemInAllVersions else { return [] }

        // Find the closest previous version or use the first one if `from` is older than all versions.
        let fromIndex = allVersions.lastIndex { $0 <= fromVersion } ?? 0

        // Find the index of `to` version or the last version if `to` is newer than all versions.
        let toIndex = allVersions.firstIndex { $0 >= toVersion } ?? (allVersions.count - 1)
        
        // Return the range.
        return Array(allVersions[fromIndex...toIndex])
    }
}
