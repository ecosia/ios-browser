// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

extension LegacyHomepageViewController: ProductTourObserver {

    /// Configure product tour integration during view setup
    func configureProductTourIntegration() {
        ProductTourManager.shared.addObserver(self)
    }

    /// Clean up product tour integration
    func cleanupProductTourIntegration() {
        ProductTourManager.shared.removeObserver(self)
    }

    /// ProductTourObserver implementation
    func productTourStateDidChange(_ state: ProductTourState) {
        // Reload the homepage when product tour state changes
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.updateEnabledSections()
            self?.reloadView()
        }
    }
}
