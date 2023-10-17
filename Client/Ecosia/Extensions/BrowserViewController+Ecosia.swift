/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Shared

extension BrowserViewController: HomepageViewControllerDelegate {
    func homeDidTapSearchButton(_ home: HomepageViewController) {
        urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
    }
}

extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowser) {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        homepageViewController?.reloadTooltip()
    }
}

extension BrowserViewController: WhatsNewViewDelegate {
    func whatsNewViewDidShow(_ viewController: WhatsNewViewController) {
        whatsNewDataProvider.markPreviousVersionsAsSeen()
        homepageViewController?.reloadTooltip()
    }
}

extension BrowserViewController: PageActionsShortcutsDelegate {
    func pageOptionsOpenHome() {
        tabToolbarDidPressHome(toolbar, button: .init())
        dismiss(animated: true)
        Analytics.shared.menuClick("home")
    }

    func pageOptionsNewTab() {
        openBlankNewTab(focusLocationField: false)
        dismiss(animated: true)
        Analytics.shared.menuClick("new_tab")
    }
    
    func pageOptionsSettings() {
        let settingsTableViewController = AppSettingsTableViewController(
            with: self.profile,
            and: self.tabManager,
            delegate: self)

        let controller = ThemedNavigationController(rootViewController: settingsTableViewController)
        // On iPhone iOS13 the WKWebview crashes while presenting file picker if its not full screen. Ref #6232
        if UIDevice.current.userInterfaceIdiom == .phone {
            controller.modalPresentationStyle = .fullScreen
        }
        controller.presentingModalViewControllerDelegate = self
        Analytics.shared.menuClick("settings")

        // Wait to present VC in an async dispatch queue to prevent a case where dismissal
        // of this popover on iPad seems to block the presentation of the modal VC.
        DispatchQueue.main.async { [weak self] in
            self?.showViewController(viewController: controller)
        }
    }

    func pageOptionsShare() {
        dismiss(animated: true) {
            guard let item = self.menuHelper?.getSharingAction().item,
                  let handler = item.tapHandler else { return }
            handler(item)
        }
    }
}
