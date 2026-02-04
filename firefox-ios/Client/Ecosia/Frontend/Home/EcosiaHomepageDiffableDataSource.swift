// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Ecosia

/// Ecosia-owned diffable data source for the homepage. Uses only Ecosia sections and cells.
final class EcosiaHomepageDiffableDataSource: HomepageDiffableDataSource {

    weak var ecosiaAdapter: EcosiaHomepageAdapter?

    override class var cellTypesToRegister: [ReusableCell.Type] {
        var types: [ReusableCell.Type] = [
            NTPLogoCell.self,
            NTPLibraryCell.self,
            NTPImpactCell.self,
            NTPNewsCell.self,
            NTPCustomizationCell.self
        ]
        if #available(iOS 16.0, *) {
            types.insert(NTPHeader.self, at: 0)
        }
        return types
    }

    override func updateSnapshot(
        state: HomepageState,
        jumpBackInDisplayConfig: JumpBackInSectionLayoutConfiguration
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        if let adapter = ecosiaAdapter {
            appendEcosiaSections(to: &snapshot, adapter: adapter)
        }
        apply(snapshot, animatingDifferences: false)
    }
}
