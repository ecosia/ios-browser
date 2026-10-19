// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation
import TabDataStore

extension Array where Element == TabData {
    /// Drops tabs restored onto an intercepted Ecosia auth URL.
    ///
    /// A visible tab never commits an intercepted auth URL, because detection cancels that navigation,
    /// so a restored one is an invisible auth tab orphaned by a kill mid-flow. Restoring it would report
    /// an inconsistency and force a logout on every selection and reload. Used by both tab restore paths
    /// (`TabManagerImplementation`'s legacy one and `DefaultTabRestorer`).
    func removingEcosiaAuthTabs(interceptor: EcosiaURLInterceptor = EcosiaURLInterceptor()) -> [TabData] {
        filter { tabData in
            guard let url = URL(string: tabData.siteUrl) else { return true }
            return !interceptor.shouldIntercept(url)
        }
    }
}
