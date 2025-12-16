// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Shared
import Ecosia
import ObjectiveC

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

// MARK: Ecosia URL Detection and Handling

extension BrowserViewController {
    /// Detects Ecosia-specific URLs (auth, profile, etc.) and triggers native flows.
    /// - Returns: `true` if the URL was handled and navigation should be cancelled, `false` otherwise
    func detectAndHandleEcosiaURL(_ url: URL, for tab: Tab) -> Bool {
        guard !tab.isInvisible else { return false }

        let interceptor = EcosiaURLInterceptor()
        let interceptedType = interceptor.interceptedType(for: url)

        switch interceptedType {
        case .signUp:
            handleSignUpDetection(url, tab: tab)
            return true
        case .signIn:
            handleSignInDetection(url, tab: tab)
            return false
        case .signOut:
            handleSignOutDetection(url)
            return true
        case .profile:
            handleProfilePageDetection(url)
            return true
        case .none:
            return false
        }
    }

    private func handleSignUpDetection(_ url: URL, tab: Tab) {
        handleAuthenticationDetection(url: url, tab: tab, flowName: "sign-up")
    }

    private func handleSignInDetection(_ url: URL, tab: Tab) {
        capturePostAuthSearchURL(from: tab)
    }

    private func handleAuthenticationDetection(url: URL, tab: Tab, flowName: String) {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for \(flowName) detection")
            return
        }
        capturePostAuthSearchURL(from: tab)

        let flowLabel = flowName.capitalized
        let successDescription = flowName == "sign-in" ? "sign-in" : "sign-up"

        if !ecosiaAuth.isLoggedIn {
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] \(flowLabel) URL detected in navigation: \(url)")
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native authentication flow")

            ecosiaAuth
                .onNativeAuthCompleted {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native authentication completed from navigation detection")
                }
                .onAuthFlowCompleted { [weak self] success in
                    if success {
                        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete authentication flow successful from navigation")

                        DispatchQueue.main.async {
                            self?.loadPendingSearchURLOrReloadCurrentTab()
                            EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after successful \(successDescription)")
                        }
                    } else {
                        EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Authentication flow completed with issues from navigation")
                        self?.resetPendingSearchURL()
                    }
                }
                .onError { [weak self] error in
                    self?.resetPendingSearchURL()
                    EcosiaLogger.auth.error("🔐 [WEB-AUTH] Authentication failed from navigation: \(error)")
                }
                .login()
        } else {
            EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Inconsistent state detected: web thinks user is logged out but native doesn't")
            EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Failing entire process to avoid user getting locked")

            ecosiaAuth
                .onAuthFlowCompleted { _ in
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Logout completed to resolve inconsistency")
                    ecosiaAuth
                        .onAuthFlowCompleted { [weak self] success in
                            if success {
                                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Re-authentication successful after resolving inconsistency")

                                DispatchQueue.main.async {
                                    self?.loadPendingSearchURLOrReloadCurrentTab()
                                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after inconsistency resolution")
                                }
                            } else {
                                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Re-authentication failed after resolving inconsistency")
                                self?.resetPendingSearchURL()
                            }
                        }
                        .onError { [weak self] error in
                            self?.resetPendingSearchURL()
                            EcosiaLogger.auth.error("🔐 [WEB-AUTH] Re-authentication error after resolving inconsistency: \(error)")
                        }
                        .login()
                }
                .onError { error in
                    EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed while resolving inconsistency: \(error)")
                }
                .logout()
        }
    }

    private func handleSignOutDetection(_ url: URL) {
        guard let ecosiaAuth = ecosiaAuth else {
            EcosiaLogger.auth.notice("No EcosiaAuth instance available for sign-out detection")
            return
        }

        // Always perform logout on web-triggered sign-out to clear inconsistent state
        if !ecosiaAuth.isLoggedIn {
            EcosiaLogger.auth.info("🔐 [WEB-AUTH] User already logged out, but we perform logout anyways to clear inconsistent state for: \(url) as if it's triggered, it means the User sees the page and clicks logout. It may happen sometimes. Noticed especially on iPad.")
        }

        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Sign-out URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Triggering native logout flow")

        ecosiaAuth
            .onNativeAuthCompleted {
                EcosiaLogger.auth.info("🔐 [WEB-AUTH] Native logout completed from navigation detection")
            }
            .onAuthFlowCompleted { [weak self] success in
                if success {
                    EcosiaLogger.auth.info("🔐 [WEB-AUTH] Complete logout flow successful from navigation")

                    // Refresh the current page to reflect auth state changes
                    DispatchQueue.main.async {
                        self?.tabManager.selectedTab?.reload()
                        EcosiaLogger.auth.info("🔐 [WEB-AUTH] Page refreshed after successful sign-out")
                    }
                } else {
                    EcosiaLogger.auth.notice("🔐 [WEB-AUTH] Logout flow completed with issues from navigation")
                }
            }
            .onError { error in
                EcosiaLogger.auth.error("🔐 [WEB-AUTH] Logout failed from navigation: \(error)")
            }
            .logout()
    }

    private func handleProfilePageDetection(_ url: URL) {
        EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Profile URL detected in navigation: \(url)")
        EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Opening native profile modal")

        DispatchQueue.main.async { [weak self] in
            self?.presentProfileModal()
        }
    }
}

// MARK: Post-auth search helpers

private var postAuthSearchRedirectStateKey: UInt8 = 0

extension BrowserViewController {
    private var postAuthSearchRedirectState: PostAuthSearchRedirectState {
        if let state = objc_getAssociatedObject(self, &postAuthSearchRedirectStateKey) as? PostAuthSearchRedirectState {
            return state
        }
        let state = PostAuthSearchRedirectState()
        objc_setAssociatedObject(self, &postAuthSearchRedirectStateKey, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }

    func capturePostAuthSearchURL(from tab: Tab) {
        let searchURLString = tab.metadataManager?.tabGroupData.tabAssociatedSearchUrl
        postAuthSearchRedirectState.capture(searchURLString: searchURLString)
    }

    func loadPendingSearchURLOrReloadCurrentTab() {
        guard let tab = tabManager.selectedTab else { return }
        if let url = postAuthSearchRedirectState.consumePendingURL() {
            tab.loadRequest(URLRequest(url: url))
        } else {
            tab.reload()
        }
    }

    func resetPendingSearchURL() {
        postAuthSearchRedirectState.reset()
    }

    func restorePostAuthSearchIfNeeded(for currentURL: URL?, tab: Tab) {
        guard postAuthSearchRedirectState.hasPendingURL,
              shouldRestorePostAuthSearch(for: currentURL)
        else {
            return
        }

        loadPendingSearchURLOrReloadCurrentTab()
    }

    private func shouldRestorePostAuthSearch(for currentURL: URL?) -> Bool {
        guard let url = currentURL else { return false }
        let rootURL = Environment.current.urlProvider.root
        guard url.host == rootURL.host else { return false }

        let normalizedPath = url.path.isEmpty ? "/" : url.path
        return normalizedPath == "/"
    }
}

// MARK: Profile Modal Presentation
extension BrowserViewController {
    /// Presents the profile page as a modal, similar to EcosiaAccountImpactView
    func presentProfileModal() {
        guard #available(iOS 16.0, *) else {
            EcosiaLogger.auth.notice("Profile modal requires iOS 16.0+")
            return
        }

        let profileView = EcosiaWebViewModal(
            url: Environment.current.urlProvider.profileURL,
            windowUUID: windowUUID,
            userAgent: UserAgentBuilder.ecosiaMobileUserAgent().userAgent(),
            onLoadComplete: {
                Analytics.shared.accountProfileViewed()
            },
            onDismiss: {
                Analytics.shared.accountProfileDismissed()
            }
        )

        let hostingController = UIHostingController(rootView: profileView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        present(hostingController, animated: true) {
            EcosiaLogger.auth.info("🔐 [WEB-PROFILE] Profile modal presented successfully")
        }
    }
}
