// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia
import Redux

extension HomepageViewController: @MainActor HomepageDataModelDelegate {

    func reloadView() {
        refreshEcosiaSnapshot()
    }

    /// Ecosia: Opens the selected news article in a new tab and records analytics
    func handleEcosiaNewsSelection(at indexPath: IndexPath) {
        guard let items = ecosiaAdapter?.newsViewModel?.items,
              indexPath.item < items.count else { return }
        let newsItem = items[indexPath.item]
        let destination = NavigationDestination(
            .newTab,
            url: newsItem.targetUrl,
            isPrivate: false,
            selectNewTab: true
        )
        store.dispatch(NavigationBrowserAction(
            navigationDestination: destination,
            windowUUID: windowUUID,
            actionType: NavigationBrowserActionType.tapOnCell
        ))
        Analytics.shared.navigationOpenNews(newsItem.trackingName)
    }

    /// Ecosia: Registers all Ecosia cell types on the collection view. Call from configureCollectionView so Ecosia cells (e.g. NTPHeader) are always available regardless of setup order.
    func registerEcosiaCells(on collectionView: UICollectionView) {
        var types: [ReusableCell.Type] = [
            NTPLogoCell.self,
            NTPLibraryCell.self,
            TopSiteCell.self,
            EmptyTopSiteCell.self,
            NTPImpactCell.self,
            NTPNewsCell.self,
            NTPCustomizationCell.self
        ]
        if #available(iOS 16.0, *) {
            types.insert(NTPHeader.self, at: 0)
        }
        types.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
    }

    /// Ecosia: Sets up the Ecosia homepage adapter and integrates it with the view controller
    func setupEcosiaAdapter(
        profile: Profile,
        tabManager: TabManager,
        referrals: Referrals,
        auth: EcosiaAuth,
        browserViewController: BrowserViewController
    ) {
        let adapter = EcosiaHomepageAdapter(
            profile: profile,
            windowUUID: windowUUID,
            tabManager: tabManager,
            referrals: referrals,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            auth: auth
        )
        
        // Set delegates
        adapter.updateDelegates(
            header: browserViewController,
            library: browserViewController,
            impact: browserViewController,
            news: browserViewController,
            customization: browserViewController
        )
        
        // Store adapter
        setEcosiaAdapter(adapter)

        // So News can refresh the snapshot when items load
        adapter.newsViewModel?.dataModelDelegate = self

        // Register Ecosia cell types (including top sites after library) and attach adapter
        var ecosiaCellTypes: [ReusableCell.Type] = [
            NTPLogoCell.self,
            NTPLibraryCell.self,
            TopSiteCell.self,
            EmptyTopSiteCell.self,
            NTPImpactCell.self,
            NTPNewsCell.self,
            NTPCustomizationCell.self
        ]
        if #available(iOS 16.0, *) {
            ecosiaCellTypes.insert(NTPHeader.self, at: 0)
        }
        homepageCellTypesToRegister = ecosiaCellTypes
        onDataSourceConfigured = { [weak self] dataSource in
            dataSource.ecosiaAdapter = self?.ecosiaAdapter
        }
        dataSource?.ecosiaAdapter = adapter
    }
    
    /// Ecosia: Called when view will appear to refresh Ecosia data
    func ecosiaViewWillAppear() {
        ecosiaAdapter?.viewWillAppear()
        ecosiaAdapter?.refreshData(
            for: traitCollection,
            size: view.bounds.size
        )
    }
    
    /// Ecosia: Called when view did disappear to clean up Ecosia resources
    func ecosiaViewDidDisappear() {
        ecosiaAdapter?.viewDidDisappear()
    }
    
    /// Ecosia: Updates theme for Ecosia sections
    func updateEcosiaTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        ecosiaAdapter?.updateTheme(theme)
    }

    /// Ecosia: Refreshes the Ecosia snapshot (e.g. after tooltip accept, or when news loads) so the UI updates
    func refreshEcosiaSnapshot() {
        guard let dataSource else { return }
        dataSource.updateSnapshot(
            state: homepageState,
            jumpBackInDisplayConfig: getJumpBackInDisplayConfig()
        )
        // Force News cells to reconfigure via data source (do not mutate collection view directly)
        var snapshot = dataSource.snapshot()
        if snapshot.indexOfSection(.ecosiaNews) != nil {
            let newsItems = snapshot.itemIdentifiers(inSection: .ecosiaNews)
            if !newsItems.isEmpty {
                snapshot.reloadItems(newsItems)
                dataSource.apply(snapshot)
            }
        }
        // Invalidate layout so self-sizing (e.g. news tiles) recalculates and avoids excess empty space
        homepageCollectionView?.collectionViewLayout.invalidateLayout()
    }
    
    /// Ecosia: Returns wallpaper state with Ecosia NTP background
    func getEcosiaNTPWallpaperState() -> WallpaperState? {
        guard let adapter = ecosiaAdapter else {
            return nil
        }
        let wallpaperConfig = adapter.getNTPBackgroundConfiguration()
        let state = WallpaperState(windowUUID: windowUUID, wallpaperConfiguration: wallpaperConfig)
        return state
    }
}
