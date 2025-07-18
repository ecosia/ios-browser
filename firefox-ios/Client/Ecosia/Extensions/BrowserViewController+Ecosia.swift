// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Ecosia

// MARK: HomepageViewControllerDelegate
extension BrowserViewController: HomepageViewControllerDelegate {
    func homeDidTapSearchButton(_ home: HomepageViewController) {
        urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
    }
}

// MARK: DefaultBrowserDelegate
extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowserViewController) {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
//        homepageViewController?.reloadTooltip()
    }
}

// MARK: WhatsNewViewDelegate
extension BrowserViewController: WhatsNewViewDelegate {
    func whatsNewViewDidShow(_ viewController: WhatsNewViewController) {
        whatsNewDataProvider.markPreviousVersionsAsSeen()
//        homepageViewController?.reloadTooltip()
    }
}

// MARK: PageActionsShortcutsDelegate
extension BrowserViewController: PageActionsShortcutsDelegate {
    func pageOptionsOpenHome() {
        tabToolbarDidPressHome(toolbar, button: .init())
        dismiss(animated: true)
        Analytics.shared.menuClick(.home)
    }

    func pageOptionsNewTab() {
        openBlankNewTab(focusLocationField: false)
        dismiss(animated: true)
        Analytics.shared.menuClick(.newTab)
    }

    func pageOptionsSettings() {
        homePanelDidRequestToOpenSettings(at: .general)
        dismiss(animated: true)
        Analytics.shared.menuClick(.settings)
    }

    func pageOptionsShare() {
        dismiss(animated: true) {
            guard let item = self.menuHelper?.getSharingAction().items.first,
                  let handler = item.tapHandler else { return }
            handler(item)
        }
    }
}

// MARK: URL Bar
extension BrowserViewController {

    func updateURLBarFollowingPrivateModeUI() {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        urlBar.applyUIMode(isPrivate: isPrivate, theme: themeManager.getCurrentTheme(for: windowUUID))
    }
}

// MARK: Present intro
extension BrowserViewController {

    func presentIntroViewController(_ alwaysShow: Bool = false) {
        if showLoadingScreen(for: .shared) {
            presentLoadingScreen()
        } else if User.shared.firstTime {
            handleFirstTimeUserActions()
        }
    }

    private func presentLoadingScreen() {
        present(LoadingScreen(profile: profile, referrals: referrals, windowUUID: windowUUID, referralCode: User.shared.referrals.pendingClaim), animated: true)
    }

    private func handleFirstTimeUserActions() {
        User.shared.firstTime = false
        User.shared.migrated = true
        User.shared.hideBookmarksImportExportTooltip()
        toolbarContextHintVC.deactivateHintForNewUsers()
    }

    private func showLoadingScreen(for user: User) -> Bool {
        user.referrals.pendingClaim != nil
    }
}

// MARK: Claim Referral
extension BrowserViewController {

    func openBlankNewTabAndClaimReferral(code: String) {
        User.shared.referrals.pendingClaim = code

        // on first start, browser is not in view hierarchy yet
        guard !User.shared.firstTime else { return }
        popToBVC()
        openURLInNewTab(nil, isPrivate: false)
        // Intro logic will trigger claiming referral
        presentIntroViewController()
    }
}

// MARK: Authentication URL Detection
extension BrowserViewController {
    /// Detects authentication URLs and triggers native auth flows.
    /// This is simpler than the WebAuthURLDetector as it's called directly from navigation delegate
    func detectAndHandleAuthURL(_ url: URL) {
        guard url.isEcosia() else { return }
        
        let path = url.path.lowercased()
        let urlProvider = Environment.current.urlProvider
        
        if urlProvider.signInPaths.contains(where: { path.contains($0) }) {
            handleSignInDetection(url)
        } else if urlProvider.signOutPaths.contains(where: { path.contains($0) }) {
            handleSignOutDetection(url)
        }
    }
    
    private func handleSignInDetection(_ url: URL) {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for sign-in detection")
            return
        }
        
        // Only trigger if user is not already logged in
        guard !ecosiaAuth.isLoggedIn else {
            EcosiaLogger.auth.debug("User already logged in, skipping sign-in detection for: \(url)")
            return
        }
        
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-in URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native authentication flow")
        
        ecosiaAuth.login()
            .onNativeAuthCompleted {
                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native authentication completed from navigation detection")
            }
            .onAuthFlowCompleted { success in
                if success {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete authentication flow successful from navigation")
                } else {
                    EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Authentication flow completed with issues from navigation")
                }
            }
            .onError { error in
                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Authentication failed from navigation: \(error)")
            }
    }
    
    private func handleSignOutDetection(_ url: URL) {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for sign-out detection")
            return
        }
        
        // Only trigger if user is currently logged in
        guard ecosiaAuth.isLoggedIn else {
            EcosiaLogger.auth.debug("User not logged in, skipping sign-out detection for: \(url)")
            return
        }
        
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-out URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native logout flow")
        
        ecosiaAuth.logout()
            .onNativeAuthCompleted {
                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native logout completed from navigation detection")
            }
            .onAuthFlowCompleted { success in
                if success {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete logout flow successful from navigation")
                } else {
                    EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Logout flow completed with issues from navigation")
                }
            }
            .onError { error in
                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed from navigation: \(error)")
            }
    }
}
