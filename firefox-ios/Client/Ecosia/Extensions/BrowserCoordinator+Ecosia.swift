// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia

extension BrowserCoordinator {

    /// Ecosia: Injects Referrals and EcosiaAuth into the browser view controller so that
    /// showHomepage can run setupEcosiaAdapter and the Ecosia NTP data source is used.
    /// Call once after the coordinator's browserViewController is created.
    func configureEcosiaServicesIfNeeded() {
        guard browserViewController.referrals == nil else { return }
        browserViewController.referrals = Referrals()
        _ = EcosiaAuth(browserViewController: browserViewController)
    }
}
