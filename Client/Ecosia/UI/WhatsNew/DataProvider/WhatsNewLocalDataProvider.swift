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
    
    /// A computed property to determine whether the "What's New" page should be displayed.
    /// - Returns: `true` if the What's New page should be shown; otherwise, `false`.
    var shouldShowWhatsNewPage: Bool {
        
        // Check if we are in the upgrade scenario
        guard EcosiaInstallType.get() == .upgrade else {
            markAllPreviousVersionsAsSeen()
            return false
        }
        
        // Get a list of version strings from the data provider.
        let dataProviderVersionsString = getVersionRange().map { $0.description }
        
        // Check if there are saved "What's New" item versions in the user settings.
        guard let savedWhatsNewItemVersionsString = user.whatsNewItemsVersionsShown else { return true }
        
        // Determine if there are any new items to show based on saved versions.
        let isNeedingItemsToShow = savedWhatsNewItemVersionsString.allSatisfy { dataProviderVersionsString.contains($0) } == false
        
        // Return true if it's an upgrade and there are new items to show.
        return isNeedingItemsToShow
    }

    /// The current app version provider from which the Ecosia App Version is retrieved
    private(set) var versionProvider: AppVersionInfoProvider
    /// The `User` instance. Mainly utilized to pass the correct instance in tests. Production code rely on its `.shared` instance.
    private(set) var user: User

    /// Default initializer.
    /// - Parameters:
    ///   - versionProvider: The current app version provider. Defaults to `DefaultAppVersionInfoProvider`
    ///   - user: An instance of the `User` object to improve reliability on tests. Defaults to its shared instance `.shared`
    init(versionProvider: AppVersionInfoProvider = DefaultAppVersionInfoProvider(),
         user: User = .shared) {
        self.versionProvider = versionProvider
        self.user = user
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
        
        // Ensure `fromVersion` is available; otherwise, return an empty version range.
        guard let fromVersion else { return [] }

        // Gather all versions
        let allVersions = Array(whatsNewItems.keys).sorted()

        // Gather first item in `allVersions` array
        guard let firstItemInAllVersions = allVersions.first else { return [] }
        
        // Ensure the `toVersion` is bigger than the smallest version in `whatsNewItems`
        guard toVersion > firstItemInAllVersions else { return [] }

        // Find the closest previous version or use the first one if `from` is older than all versions.
        let fromIndex = allVersions.lastIndex { $0 <= fromVersion } ?? 0

        // Find the index of `to` version or the last version if `to` is newer than all versions.
        let toIndex = allVersions.firstIndex { $0 >= toVersion } ?? (allVersions.count - 1)
        
        // Return the range.
        return Array(allVersions[fromIndex...toIndex])
    }
}

extension WhatsNewLocalDataProvider {
    
    private func markAllPreviousVersionsAsSeen() {
        let previousVersions = whatsNewItems.keys
            .filter { $0 <= toVersion }
            .map { $0.description }
        user.updateWhatsNewItemsVersionsAppending(previousVersions)
    }
    
}