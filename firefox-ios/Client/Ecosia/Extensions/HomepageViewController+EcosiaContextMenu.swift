// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import Storage
import UIKit

// Ecosia: Native UIContextMenuConfiguration for NTP top sites, aligning with the iOS 26 Liquid Glass design.
// The PhotonActionSheet flow is preserved for all other homepage sections (Jump Back In, Bookmarks, Pocket).

extension HomepageViewController {

    // MARK: - UICollectionViewDelegate Native Context Menu (Top Sites)

    // Ecosia: Returns a native UIContextMenuConfiguration for top site cells, replacing the PhotonActionSheet
    // with the iOS 26 Liquid Glass context menu style.
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let section = dataSource?.sectionIdentifier(for: indexPath.section),
              case .topSites = section,
              let item = dataSource?.itemIdentifier(for: indexPath),
              let site = getSiteForContextMenu(for: item),
              let sourceCell = collectionView.cellForItem(at: indexPath) as? TopSiteCell
        else { return nil }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSIndexPath,
            previewProvider: nil,
            actionProvider: { [weak self] _ in
                guard let self else { return nil }
                return self.makeTopSiteContextMenu(for: site, sourceView: sourceCell)
            }
        )
    }

    // Ecosia: Targets the favicon container for the highlight preview, giving a focused zoom-in effect.
    func collectionView(
        _ collectionView: UICollectionView,
        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return topSiteTargetedPreview(in: collectionView, for: configuration)
    }

    // Ecosia: Targets the favicon container for the dismiss animation, keeping visual consistency on menu close.
    func collectionView(
        _ collectionView: UICollectionView,
        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return topSiteTargetedPreview(in: collectionView, for: configuration)
    }

    // Ecosia: Builds a UITargetedPreview anchored on the top site cell's favicon container.
    private func topSiteTargetedPreview(
        in collectionView: UICollectionView,
        for configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? NSIndexPath,
              let cell = collectionView.cellForItem(at: indexPath as IndexPath) as? TopSiteCell
        else { return nil }

        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell.previewTargetView, parameters: parameters)
    }

    // Ecosia: Builds the native UIMenu for a top site, grouping actions with inline separators per the iOS 26 HIG.
    @MainActor
    func makeTopSiteContextMenu(for site: Site, sourceView: UIView) -> UIMenu {
        guard let siteURL = site.url.asURL else { return UIMenu(children: []) }
        let windowUUID = windowUUID

        let openInNewTab = UIAction(
            title: .OpenInNewTabContextMenuTitle,
            image: UIImage(systemName: "plus")
        ) { _ in
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(
                        .newTab,
                        url: siteURL,
                        isPrivate: false,
                        selectNewTab: false
                    ),
                    windowUUID: windowUUID,
                    actionType: NavigationBrowserActionType.tapOnOpenInNewTab
                )
            )
        }

        let openInPrivateTab = UIAction(
            title: .OpenInNewPrivateTabContextMenuTitle,
            image: UIImage(systemName: "moon.circle")
        ) { _ in
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(
                        .newTab,
                        url: siteURL,
                        isPrivate: true,
                        selectNewTab: false
                    ),
                    windowUUID: windowUUID,
                    actionType: NavigationBrowserActionType.tapOnOpenInNewTab
                )
            )
            store.dispatch(
                ContextMenuAction(
                    menuType: .topSite,
                    windowUUID: windowUUID,
                    actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab
                )
            )
        }

        let navigationGroup = UIMenu(options: .displayInline, children: [openInNewTab, openInPrivateTab])

        let shareConfig = ShareSheetConfiguration(
            shareType: .site(url: siteURL),
            shareMessage: nil,
            sourceView: sourceView,
            sourceRect: nil,
            toastContainer: ecosiaToastContainer,
            popoverArrowDirection: [.up, .down, .left]
        )
        let share = UIAction(
            title: .ShareContextMenuTitle,
            image: UIImage(systemName: "square.and.arrow.up")
        ) { _ in
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(.shareSheet(shareConfig)),
                    windowUUID: windowUUID,
                    actionType: NavigationBrowserActionType.tapOnShareSheet
                )
            )
        }

        switch site.type {
        case .sponsoredSite:
            return makeTopSiteSponsoredContextMenu(
                windowUUID: windowUUID,
                navigationGroup: navigationGroup,
                shareAction: share
            )
        case .pinnedSite:
            let unpin = UIAction(
                title: .UnpinTopsiteActionTitle2,
                image: UIImage(systemName: "pin.slash")
            ) { _ in
                store.dispatch(ContextMenuAction(
                    site: site,
                    windowUUID: windowUUID,
                    actionType: ContextMenuActionType.tappedOnUnpinTopSite
                ))
            }
            let remove = UIAction(
                title: .RemoveContextMenuTitle,
                image: UIImage(systemName: "xmark"),
                attributes: .destructive
            ) { _ in
                store.dispatch(ContextMenuAction(
                    site: site,
                    windowUUID: windowUUID,
                    actionType: ContextMenuActionType.tappedOnRemoveTopSite
                ))
            }
            return UIMenu(children: [
                UIMenu(options: .displayInline, children: [unpin]),
                navigationGroup,
                UIMenu(options: .displayInline, children: [remove]),
                share
            ])
        default:
            let pin = UIAction(
                title: .PinTopsiteActionTitle2,
                image: UIImage(systemName: "pin")
            ) { _ in
                store.dispatch(ContextMenuAction(
                    site: site,
                    windowUUID: windowUUID,
                    actionType: ContextMenuActionType.tappedOnPinTopSite
                ))
            }
            let remove = UIAction(
                title: .RemoveContextMenuTitle,
                image: UIImage(systemName: "xmark"),
                attributes: .destructive
            ) { _ in
                store.dispatch(ContextMenuAction(
                    site: site,
                    windowUUID: windowUUID,
                    actionType: ContextMenuActionType.tappedOnRemoveTopSite
                ))
            }
            return UIMenu(children: [
                UIMenu(options: .displayInline, children: [pin]),
                navigationGroup,
                UIMenu(options: .displayInline, children: [remove]),
                share
            ])
        }
    }

    // Ecosia: Builds the native UIMenu for a sponsored top site, omitting pin/unpin and adding settings and sponsored-content actions.
    @MainActor
    func makeTopSiteSponsoredContextMenu(
        windowUUID: WindowUUID,
        navigationGroup: UIMenu,
        shareAction: UIAction
    ) -> UIMenu {
        let settings = UIAction(
            title: .FirefoxHomepage.ContextualMenu.Settings,
            image: UIImage(systemName: "gearshape")
        ) { _ in
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(.settings(.topSites)),
                    windowUUID: windowUUID,
                    actionType: NavigationBrowserActionType.tapOnSettingsSection
                )
            )
            store.dispatch(ContextMenuAction(
                windowUUID: windowUUID,
                actionType: ContextMenuActionType.tappedOnSettingsAction
            ))
        }

        let sponsoredContent = UIAction(
            title: .FirefoxHomepage.ContextualMenu.SponsoredContent,
            image: UIImage(systemName: "questionmark.circle")
        ) { [weak self] _ in
            guard let sponsorURL = SupportUtils.URLForTopic("sponsor-privacy") else {
                self?.ecosiaLogger.log(
                    "Unable to retrieve URL for sponsor-privacy, return early",
                    level: .warning,
                    category: .homepage
                )
                return
            }
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(
                        .newTab,
                        url: sponsorURL,
                        isPrivate: false,
                        selectNewTab: true
                    ),
                    windowUUID: windowUUID,
                    actionType: NavigationBrowserActionType.tapOnOpenInNewTab
                )
            )
            store.dispatch(ContextMenuAction(
                windowUUID: windowUUID,
                actionType: ContextMenuActionType.tappedOnSponsoredAction
            ))
        }

        return UIMenu(children: [
            navigationGroup,
            UIMenu(options: .displayInline, children: [settings, sponsoredContent]),
            shareAction
        ])
    }
}
