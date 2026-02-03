// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

extension HomepageDiffableDataSource {
    
    /// Ecosia: Builds and appends Ecosia-specific sections to the snapshot
    func appendEcosiaSections(
        to snapshot: inout NSDiffableDataSourceSnapshot<HomeSection, HomeItem>,
        adapter: EcosiaHomepageAdapter
    ) {
        let ecosiaSections = adapter.getEcosiaSections()
        
        for section in ecosiaSections {
            snapshot.appendSections([section])
            let items = adapter.getItems(for: section)
            snapshot.appendItems(items, toSection: section)
        }
    }
}
