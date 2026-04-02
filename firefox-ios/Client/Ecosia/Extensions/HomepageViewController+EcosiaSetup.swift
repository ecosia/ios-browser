// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
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
            NTPHeader.self,
            NTPLibraryCell.self,
            TopSiteCell.self,
            EmptyTopSiteCell.self,
            NTPImpactCell.self,
            NTPCustomizationCell.self
        ]

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

        let bottomConstraint = searchBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -8
        )
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomConstraint,
            searchBar.heightAnchor.constraint(equalToConstant: 52)
        ])

        searchBar.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        setNTPSearchBar(searchBar)
        setNTPSearchBarBottomConstraint(bottomConstraint)

        KeyboardHelper.defaultHelper.addDelegate(self)
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
            NTPHeader.self,
            NTPLibraryCell.self,
            TopSiteCell.self,
            EmptyTopSiteCell.self,
            NTPImpactCell.self,
            NTPCustomizationCell.self
        ]
        homepageCellTypesToRegister = ecosiaCellTypes
        onDataSourceConfigured = { [weak self] dataSource in
            dataSource.ecosiaAdapter = self?.ecosiaAdapter
        }
        dataSource?.ecosiaAdapter = adapter

        // Ecosia: Refresh the NTP snapshot when homepage prefs change (e.g. Climate
        // Impact toggle) so the *current* NTP reflects the change immediately — not
        // only new tabs whose viewWillAppear fires fresh.
        notificationCenter.addObserver(
            self,
            selector: #selector(homePanelPrefsDidChange),
            name: .HomePanelPrefsChanged,
            object: nil
        )
    }

    @objc private func homePanelPrefsDidChange(_ notification: Notification) {
        refreshEcosiaSnapshot(animated: true)
    }

    /// Called when view will appear to refresh Ecosia data
    func ecosiaViewWillAppear() {
        // Remove Firefox's default 24pt top content inset — the safe area already
        // positions the content correctly, and NTPHeaderView owns its own vertical padding.
        homepageCollectionView?.contentInset.top = 0
        homepageCollectionView?.scrollIndicatorInsets.top = 0
        updateEcosiaScrollability(for: view.bounds.size)
        // Ecosia: Force 1 row of shortcuts regardless of user preference — NTP shows
        // exactly 1 row × 4 tiles per the design spec.
        store.dispatch(TopSitesAction(
            numberOfRows: 1,
            windowUUID: windowUUID,
            actionType: TopSitesActionType.updatedNumberOfRows
        ))
        // Ecosia: Remove the navigation toolbar separator on NTP — the wallpaper itself
        // acts as a visual separator; the border is only needed on SERP.
        store.dispatch(ToolbarAction(
            displayNavBorder: false,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.borderPositionChanged
        ))

        ecosiaAdapter?.viewWillAppear()
        ecosiaAdapter?.refreshData(
            for: traitCollection,
            size: view.bounds.size
        )

        // Ecosia: Force snapshot rebuild so changes to User-backed flags
        // (e.g. showClimateImpact, showTopSites) that live outside Redux
        // are picked up when returning from the settings screen.
        dataSource?.updateSnapshot(
            state: homepageState,
            jumpBackInDisplayConfig: getJumpBackInDisplayConfig()
        )
    }

    /// Enables scrolling in iPhone landscape (compact vertical size class) where the NTP
    /// content is taller than the available height; disables it otherwise so the card
    /// appears static in portrait and on iPad.
    func updateEcosiaScrollability(for size: CGSize) {
        let isPhoneLandscape = size.width > size.height && traitCollection.userInterfaceIdiom == .phone
        homepageCollectionView?.isScrollEnabled = isPhoneLandscape
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
    func refreshEcosiaSnapshot(animated: Bool = false) {
        guard let dataSource else { return }
        dataSource.updateSnapshot(
            state: homepageState,
            jumpBackInDisplayConfig: getJumpBackInDisplayConfig(),
            animated: animated
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

// MARK: - KeyboardHelperDelegate
// Ecosia: Adjusts the NTP search bar's bottom constraint when the keyboard appears so
// the bar stays visible just above the keyboard.
extension HomepageViewController: KeyboardHelperDelegate {
    public func keyboardHelper(
        _ keyboardHelper: KeyboardHelper,
        keyboardWillShowWithState state: KeyboardState
    ) {
        let keyboardHeight = state.intersectionHeightForView(view)
        guard keyboardHeight > 0, let bottomConstraint = ntpSearchBarBottomConstraint else { return }
        let safeAreaBottom = view.safeAreaInsets.bottom
        bottomConstraint.constant = -(keyboardHeight - safeAreaBottom + 8)
        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))
        ) {
            self.view.layoutIfNeeded()
        }
    }

    public func keyboardHelper(
        _ keyboardHelper: KeyboardHelper,
        keyboardWillHideWithState state: KeyboardState
    ) {
        guard let bottomConstraint = ntpSearchBarBottomConstraint else { return }
        bottomConstraint.constant = -8
        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))
        ) {
            self.view.layoutIfNeeded()
        }
    }
}
