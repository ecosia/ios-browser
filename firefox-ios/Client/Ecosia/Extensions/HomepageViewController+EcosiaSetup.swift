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

    /// Registers all Ecosia cell types on the collection view. Call from configureCollectionView so Ecosia cells (e.g. NTPHeader) are always available regardless of setup order.
    func registerEcosiaCells(on collectionView: UICollectionView) {
        // NTPLogoCell removed — logo is now part of NTPHeader.
        var types: [ReusableCell.Type] = [
            NTPLibraryCell.self,
            TopSiteCell.self,
            EmptyTopSiteCell.self,
            NTPImpactCell.self,
            NTPCustomizationCell.self
        ]
        if #available(iOS 16.0, *) {
            types.insert(NTPHeader.self, at: 0)
        }
        types.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
    }

    // Ecosia: Embeds a custom search bar pinned to the bottom of the NTP view.
    // The bar owns a real UITextField wired directly to the browser's navigation
    // logic — no toolbar duplication required (Approach 1 spike).
    func setupNTPSearchBar(delegate: NTPSearchBarDelegate) {
        let searchBar = NTPSearchBarView()
        searchBar.delegate = delegate
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 52)
        ])

        searchBar.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        setNTPSearchBar(searchBar)
    }

    /// Sets up the Ecosia homepage adapter and integrates it with the view controller
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
            customization: browserViewController
        )

        // Store adapter
        setEcosiaAdapter(adapter)

        // Ecosia: Add the embedded NTP search bar (Approach 1 spike)
        setupNTPSearchBar(delegate: browserViewController)

        // Register Ecosia cell types; NTPLogoCell removed — logo now lives in NTPHeader.
        var ecosiaCellTypes: [ReusableCell.Type] = [
            NTPLibraryCell.self,
            TopSiteCell.self,
            EmptyTopSiteCell.self,
            NTPImpactCell.self,
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

    /// Called when view will appear to refresh Ecosia data
    func ecosiaViewWillAppear() {
        // Remove Firefox's default 24pt top content inset — the safe area already
        // positions the content correctly, and NTPHeaderView owns its own vertical padding.
        homepageCollectionView?.contentInset.top = 0
        homepageCollectionView?.scrollIndicatorInsets.top = 0

        ecosiaAdapter?.viewWillAppear()
        ecosiaAdapter?.refreshData(
            for: traitCollection,
            size: view.bounds.size
        )
    }

    /// Called when view did disappear to clean up Ecosia resources
    func ecosiaViewDidDisappear() {
        ecosiaAdapter?.viewDidDisappear()
    }

    /// Updates theme for Ecosia sections
    func updateEcosiaTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        ecosiaAdapter?.updateTheme(theme)
        ntpSearchBar?.applyTheme(theme: theme)
    }

    /// Refreshes the Ecosia snapshot so the UI updates
    func refreshEcosiaSnapshot() {
        guard let dataSource else { return }
        dataSource.updateSnapshot(
            state: homepageState,
            jumpBackInDisplayConfig: getJumpBackInDisplayConfig()
        )
        homepageCollectionView?.collectionViewLayout.invalidateLayout()
    }

    /// Returns wallpaper state with Ecosia NTP background
    func getEcosiaNTPWallpaperState() -> WallpaperState? {
        guard let adapter = ecosiaAdapter else {
            return nil
        }
        let wallpaperConfig = adapter.getNTPBackgroundConfiguration()
        let state = WallpaperState(windowUUID: windowUUID, wallpaperConfiguration: wallpaperConfig)
        return state
    }
}
