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

    // Ecosia: Embeds the AI-ready Omnibox pinned to the bottom of the NTP view.
    // Replaces the standard URL bar while the homepage is visible. Submission and
    // suggestions are wired through the browser's existing navigation pipeline.
    func setupNTPSearchBar(delegate: NTPSearchBarDelegate) {
        let searchBar = NTPSearchBarView()
        searchBar.delegate = delegate
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        let bottomConstraint = searchBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -.ecosia.space._1l
        )
        let horizontalInset = Self.ntpSearchBarHorizontalInset(for: traitCollection)
        let leadingConstraint = searchBar.leadingAnchor.constraint(
            equalTo: view.leadingAnchor,
            constant: horizontalInset
        )
        let trailingConstraint = searchBar.trailingAnchor.constraint(
            equalTo: view.trailingAnchor,
            constant: -horizontalInset
        )
        // The pill self-sizes between min and max to accommodate multi-line
        // input — content inside drives the actual height.
        let minHeightConstraint = searchBar.heightAnchor.constraint(
            greaterThanOrEqualToConstant: NTPSearchBarView.minHeight
        )
        let maxHeightConstraint = searchBar.heightAnchor.constraint(
            lessThanOrEqualToConstant: NTPSearchBarView.maxHeight
        )
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            bottomConstraint,
            minHeightConstraint,
            maxHeightConstraint
        ])

        searchBar.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        setNTPSearchBar(searchBar)
        setNTPSearchBarBottomConstraint(bottomConstraint)
        setNTPSearchBarLeadingConstraint(leadingConstraint)
        setNTPSearchBarTrailingConstraint(trailingConstraint)

        // Swipe-down on the NTP content drags the keyboard with it — when the
        // keyboard fully dismisses, the omnibox loses focus naturally.
        homepageCollectionView?.keyboardDismissMode = .interactive

        searchBar.onContentChange = { [weak self] text in
            self?.handleOmniboxContentChange(text)
        }

        installOmniboxCloseButton()
        installOmniboxTapOutsideDismiss()

        KeyboardHelper.defaultHelper.addDelegate(self)
    }

    private func installOmniboxCloseButton() {
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 18
        button.alpha = 0
        button.isHidden = true
        button.accessibilityLabel = String.localized(.close)
        button.accessibilityIdentifier = "NTPOmniboxCloseButton"
        button.addTarget(self, action: #selector(handleOmniboxCloseButtonTapped), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: .ecosia.space._m),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.ecosia.space._m),
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])

        let theme = themeManager.getCurrentTheme(for: windowUUID).colors
        button.backgroundColor = theme.ecosia.backgroundElevation2
        button.tintColor = theme.ecosia.textPrimary

        setNTPOmniboxCloseButton(button)
    }

    private func installOmniboxTapOutsideDismiss() {
        let recognizer = UITapGestureRecognizer(target: self,
                                                action: #selector(handleTapOutsideOmnibox(_:)))
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
    }

    private func handleOmniboxContentChange(_ text: String) {
        guard let button = ntpOmniboxCloseButton else { return }
        let shouldShow = !text.isEmpty
        guard shouldShow != !button.isHidden else { return }
        if shouldShow {
            button.isHidden = false
            UIView.animate(withDuration: 0.2) { button.alpha = 1 }
        } else {
            UIView.animate(withDuration: 0.2,
                           animations: { button.alpha = 0 },
                           completion: { _ in button.isHidden = true })
        }
    }

    @objc private func handleOmniboxCloseButtonTapped() {
        guard let bar = ntpSearchBar else { return }
        bar.text = ""
        if bar.isFirstResponder {
            _ = bar.resignFirstResponder()
        }
        // The bar's `didCancel` callback no longer hides the overlay (that
        // would tear it down on every keyboard drag-dismiss too), so always
        // request the explicit dismiss here. After a drag-dismiss the bar
        // isn't first responder either, but the request still tears the
        // suggestions overlay down.
        bar.delegate?.ntpSearchBarRequestsOverlayDismiss()
    }

    @objc private func handleTapOutsideOmnibox(_ gesture: UITapGestureRecognizer) {
        guard let bar = ntpSearchBar else { return }
        let location = gesture.location(in: view)
        guard !bar.frame.contains(location) else { return }
        if bar.isFirstResponder {
            _ = bar.resignFirstResponder()
        }
        // Always request the explicit overlay dismiss — `didCancel` no
        // longer hides the overlay (so keyboard drag-dismiss leaves the
        // list visible), and after a drag-dismiss the bar isn't first
        // responder so `resignFirstResponder` above is a no-op.
        bar.delegate?.ntpSearchBarRequestsOverlayDismiss()
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

    /// Re-applies the iPad horizontal inset to the omnibox after a rotation or
    /// size-class change (e.g. iPad split-screen resize). On iPhone-class
    /// surfaces the value collapses back to the default `_m` margin.
    func updateNTPSearchBarHorizontalInset() {
        let inset = Self.ntpSearchBarHorizontalInset(for: traitCollection)
        ntpSearchBarLeadingConstraint?.constant = inset
        ntpSearchBarTrailingConstraint?.constant = -inset
    }

    /// 160pt of breathing room on iPad regular-width surfaces so the pill doesn't
    /// stretch the full width of a 1024pt display; everything else (iPhone, iPad
    /// narrow split-screen) uses the standard `_m` margin.
    fileprivate static func ntpSearchBarHorizontalInset(for traitCollection: UITraitCollection) -> CGFloat {
        let isWideIPad = traitCollection.userInterfaceIdiom == .pad
            && traitCollection.horizontalSizeClass == .regular
        return isWideIPad ? 160 : .ecosia.space._m
    }

    /// Called from `viewDidLayoutSubviews`. The omnibox cushion is now baked
    /// into the impact section's fill height (see `createEcosiaImpactLayout`),
    /// so no contentInset tuning is required — clear any inset left over
    /// from previous frames so it doesn't compound with the layout.
    func updateNTPCollectionViewBottomInsetForOmnibox() {
        guard let collectionView = homepageCollectionView else { return }
        if collectionView.contentInset.bottom != 0 {
            collectionView.contentInset.bottom = 0
            collectionView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    /// Called when view did disappear to clean up Ecosia resources
    func ecosiaViewDidDisappear() {
        // Defensive: if the user navigated away while the omnibox was editing,
        // tear down the suggestions overlay so the SearchLoader doesn't keep a
        // dangling reference to this view's autocomplete sink. `didCancel`
        // updates session state; `requestsOverlayDismiss` actually hides the
        // overlay (the cancel callback no longer does that on its own so
        // keyboard drag-dismiss can leave the list visible).
        ntpSearchBar?.delegate?.ntpSearchBarDidCancel()
        ntpSearchBar?.delegate?.ntpSearchBarRequestsOverlayDismiss()
        _ = ntpSearchBar?.resignFirstResponder()
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
// Ecosia: Keeps the omnibox glued just above the keyboard while editing.
extension HomepageViewController: KeyboardHelperDelegate {
    private static let restingBottomOffset: CGFloat = .ecosia.space._1l

    public func keyboardHelper(
        _ keyboardHelper: KeyboardHelper,
        keyboardWillShowWithState state: KeyboardState
    ) {
        let keyboardHeight = state.intersectionHeightForView(view)
        guard keyboardHeight > 0, let bottomConstraint = ntpSearchBarBottomConstraint else { return }
        let safeAreaBottom = view.safeAreaInsets.bottom
        bottomConstraint.constant = -(keyboardHeight - safeAreaBottom + Self.restingBottomOffset)
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
        bottomConstraint.constant = -Self.restingBottomOffset
        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))
        ) {
            self.view.layoutIfNeeded()
        }
    }
}
