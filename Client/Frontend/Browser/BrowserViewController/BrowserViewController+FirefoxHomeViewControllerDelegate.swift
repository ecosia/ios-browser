/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

extension BrowserViewController: FirefoxHomeViewControllerDelegate {
    func home(_ home: FirefoxHomeViewController, didScroll searchPos: CGFloat, offset: CGFloat) {

        guard !urlBar.inOverlayMode,
              (urlBar.currentURL.flatMap({ InternalURL($0)?.isAboutHomeURL }) ?? false || urlBar.currentURL == nil) else {
            header.alpha = 1
            return
        }

        let dy = max(0, offset + 4 - searchPos)
        let alpha = min(1.0, dy/4)
        header.alpha = alpha
    }

    func homeDidTapSearchButton(_ home: FirefoxHomeViewController) {
        urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
    }

    func home(_ home: FirefoxHomeViewController, willBegin drag: CGPoint) {
        guard urlBar.inOverlayMode else { return }
        urlBar.leaveOverlayMode(didCancel: true)
    }

    func homeDidPressPersonalCounter(_ home: FirefoxHomeViewController) {
        present(ecosiaNavigation, animated: true, completion: nil)
    }
}
