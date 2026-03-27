// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

// MARK: - Homepage / shared delegates

@MainActor
protocol HomepageViewControllerDelegate: AnyObject {
    func homeDidTapSearchButton(_ home: HomepageViewController)
}

@MainActor
protocol SharedHomepageCellDelegate: AnyObject {
    func openLink(url: URL)
}

@MainActor
extension BrowserViewController: SharedHomepageCellDelegate {
    func openLink(url: URL) {
        openURLInNewTab(url, isPrivate: false)
    }
}

protocol SharedHomepageCellLayoutDelegate: AnyObject {
    func invalidateLayout(at indexPaths: [IndexPath])
}

/*
 Ecosia: LegacyHomepageViewController NTP extensions removed.
 NTP delegate behaviour for the new homepage lives in the BrowserViewController
 extensions below. The new structure uses HomepageViewController + EcosiaHomepageAdapter
 with delegates set to BrowserViewController in setupEcosiaAdapter.
 */

// MARK: - Ecosia NTP Delegates (New Homepage – single source of truth)
@MainActor
extension BrowserViewController: @MainActor NTPTooltipDelegate {
    func ntpTooltipTapped(_ tooltip: NTPTooltip?) {
        handleNTPTooltipTapped(tooltip)
    }

    func ntpTooltipCloseTapped(_ tooltip: NTPTooltip?) {
        handleNTPTooltipTapped(tooltip)
    }

    func reloadTooltip() {
        (contentContainer.contentController as? HomepageViewController)?.refreshEcosiaSnapshot()
    }

    private func handleNTPTooltipTapped(_ tooltip: NTPTooltip?) {
        guard let ntpHighlight = NTPTooltip.highlight() else { return }

        UIView.animate(withDuration: 0.3) {
            tooltip?.alpha = 0
        } completion: { [weak self] _ in
            switch ntpHighlight {
            case .gotClaimed, .successfulInvite:
                User.shared.referrals.accept()
            case .referralSpotlight:
                Analytics.shared.referral(action: .open, label: .promo)
                User.shared.hideReferralSpotlight()
            case .collectiveImpactIntro:
                User.shared.hideImpactIntro()
            }
            self?.reloadTooltip()
        }
    }
}

@MainActor
extension BrowserViewController: NTPHeaderDelegate {
    func headerOpenAISearch() {
        guard let url = Environment.current.urlProvider.aiSearch(origin: .ntp) as? URL else { return }
        openURLInNewTab(url, isPrivate: false)
    }
}

@MainActor
extension BrowserViewController: NTPLibraryDelegate {
    func libraryCellOpenBookmarks() {
        showLibrary(panel: .bookmarks)
    }

    func libraryCellOpenHistory() {
        showLibrary(panel: .history)
    }

    func libraryCellOpenReadlist() {
        showLibrary(panel: .readingList)
    }

    func libraryCellOpenDownloads() {
        showLibrary(panel: .downloads)
    }
}

@MainActor
extension BrowserViewController: NTPImpactCellDelegate {
    func impactCellButtonClickedWithInfo(_ info: ClimateImpactInfo) {
        switch info {
        case .referral:
            guard let referrals else { return }
            let invite = MultiplyImpact(referrals: referrals, windowUUID: windowUUID)
            invite.delegate = self
            let nav = EcosiaNavigation(rootViewController: invite)
            present(nav, animated: true)
        default:
            return
        }
    }
}

@MainActor
extension BrowserViewController: NTPNewsCellDelegate {
    func openSeeAllNews() {
        guard let homepage = contentContainer.contentController as? HomepageViewController,
              let adapter = homepage.ecosiaAdapter,
              let newsViewModel = adapter.newsViewModel else { return }

        let news = NewsController(items: newsViewModel.items, windowUUID: windowUUID)
        news.delegate = self
        let nav = EcosiaNavigation(rootViewController: news)
        present(nav, animated: true)
        Analytics.shared.navigation(.open, label: .news)
    }
}

@MainActor
extension BrowserViewController: NTPCustomizationCellDelegate {
    func openNTPCustomizationSettings() {
        Analytics.shared.ntpCustomisation(.click, label: .customize)
        navigationHandler?.show(settings: .homePage)
    }
}
