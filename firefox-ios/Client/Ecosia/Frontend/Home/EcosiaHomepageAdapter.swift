// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Ecosia

/// Adapter that bridges Firefox's new homepage architecture with Ecosia's custom NTP sections.
/// This minimizes changes to Firefox code by encapsulating all Ecosia-specific logic.
@MainActor
final class EcosiaHomepageAdapter {

    // MARK: - Properties

    private let profile: Profile
    private let windowUUID: WindowUUID
    private let tabManager: TabManager
    private let referrals: Referrals
    private var theme: Theme
    private let auth: EcosiaAuth

    // View Models for Ecosia sections
    private(set) var headerViewModel: NTPHeaderViewModel?
    private(set) var libraryViewModel: NTPLibraryCellViewModel?
    private(set) var impactViewModel: NTPImpactCellViewModel?
    private(set) var customizationViewModel: NTPCustomizationCellViewModel?

    // Delegates
    weak var headerDelegate: NTPHeaderDelegate?
    weak var libraryDelegate: NTPLibraryDelegate?
    weak var impactDelegate: NTPImpactCellDelegate?
    weak var customizationDelegate: NTPCustomizationCellDelegate?

    // MARK: - Initialization

    init(profile: Profile,
         windowUUID: WindowUUID,
         tabManager: TabManager,
         referrals: Referrals,
         theme: Theme,
         auth: EcosiaAuth) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        self.referrals = referrals
        self.theme = theme
        self.auth = auth

        setupViewModels()
    }

    private func setupViewModels() {
        // Header (iOS 16+ only)
        if #available(iOS 16.0, *) {
            headerViewModel = NTPHeaderViewModel(
                profile: profile,
                theme: theme,
                windowUUID: windowUUID,
                auth: auth,
                delegate: headerDelegate
            )
        }

        // Library shortcuts
        libraryViewModel = NTPLibraryCellViewModel(
            delegate: libraryDelegate,
            theme: theme
        )

        // Climate impact
        impactViewModel = NTPImpactCellViewModel(
            referrals: referrals,
            theme: theme
        )
        impactViewModel?.delegate = impactDelegate

        // Customization
        customizationViewModel = NTPCustomizationCellViewModel(
            delegate: customizationDelegate,
            theme: theme
        )
    }

    // MARK: - Public Methods

    func updateTheme(_ theme: Theme) {
        self.theme = theme
        headerViewModel?.theme = theme
        libraryViewModel?.theme = theme
        impactViewModel?.theme = theme
        customizationViewModel?.theme = theme
    }

    func updateDelegates(
        header: NTPHeaderDelegate?,
        library: NTPLibraryDelegate?,
        impact: NTPImpactCellDelegate?,
        customization: NTPCustomizationCellDelegate?
    ) {
        self.headerDelegate = header
        self.libraryDelegate = library
        self.impactDelegate = impact
        self.customizationDelegate = customization

        headerViewModel?.delegate = header
        libraryViewModel?.delegate = library
        impactViewModel?.delegate = impact
        customizationViewModel?.delegate = customization
    }

    /// Returns the ordered list of Ecosia sections that should be displayed.
    /// Section order matches the Figma design: header → [library] → impact → [topSites inserted by snapshot] → news
    func getEcosiaSections() -> [HomepageSection] {
        var sections: [HomepageSection] = []

        if shouldShowHeader() {
            sections.append(.ecosiaHeader)
        }

        // Logo moved into the NTPHeader cell — no separate logo section needed.

        // Library shortcuts (Bookmarks, History, Reading List, Downloads) — hidden for now

        // Climate impact section (always present for the rotating title;
        // individual impact rows are hidden via NTPImpactCell when the toggle is off).
        sections.append(.ecosiaImpact)

        // Top sites are inserted by HomepageDiffableDataSource after topSitesInsertionAnchor

        // Customization button removed — pencil icon in header handles this

        return sections
    }

    /// The section after which top sites should be inserted.
    /// The impact section is always present (rotating title), so top sites follow it.
    var topSitesInsertionAnchor: HomepageSection {
        return .ecosiaImpact
    }

    /// Returns the items for a given Ecosia section
    func getItems(for section: HomepageSection) -> [HomepageItem] {
        switch section {
        case .ecosiaHeader:
            return [.ecosiaHeader]
        case .ecosiaLogo:
            return [.ecosiaLogo]
        case .ecosiaLibrary:
            return [.ecosiaLibrary]
        case .ecosiaImpact:
            guard impactViewModel != nil else { return [] }
            return [.ecosiaImpact(sectionIndex: 0, showRows: User.shared.showClimateImpact)]
        case .ecosiaNTPCustomization:
            return [.ecosiaNTPCustomization]
        default:
            return []
        }
    }

    // MARK: - Section Visibility

    private func shouldShowHeader() -> Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        return false
    }

    // MARK: - Lifecycle

    func viewWillAppear() {
        impactViewModel?.start()
    }

    func viewDidDisappear() {
        impactViewModel?.stop()
    }

    func refreshData(for traitCollection: UITraitCollection, size: CGSize) {
    }

    // MARK: - Ecosia: NTP Background

    /// Provides the wallpaper configuration for the NTP background
    func getNTPBackgroundConfiguration() -> WallpaperConfiguration {

        let wallpaperManager = WallpaperManager()
        let currentWallpaper = wallpaperManager.currentWallpaper

        var portraitImage: UIImage?
        var landscapeImage: UIImage?

        // Try to load bundled asset first if available
        if let bundledAssetName = currentWallpaper.bundledAssetName {
            portraitImage = UIImage(named: bundledAssetName)
            landscapeImage = UIImage(named: bundledAssetName)
        }

        // If no bundled asset, try to load downloaded images
        if portraitImage == nil || landscapeImage == nil {
            let storageUtility = WallpaperStorageUtility()
            portraitImage = try? storageUtility.fetchImageNamed(currentWallpaper.portraitID)
            landscapeImage = try? storageUtility.fetchImageNamed(currentWallpaper.landscapeID)
        }

        // Fallback to default bundled background if nothing loaded
        if portraitImage == nil {
            // Ecosia: load from Ecosia framework bundle where the asset now lives
            portraitImage = .ecosia(named: "ntpBackground")
            landscapeImage = .ecosia(named: "ntpBackground")
        }

        return WallpaperConfiguration(
            id: currentWallpaper.id,
            landscapeImage: landscapeImage,
            portraitImage: portraitImage,
            textColor: currentWallpaper.textColor,
            cardColor: currentWallpaper.cardColor,
            logoTextColor: currentWallpaper.logoTextColor,
            hasImage: portraitImage != nil || landscapeImage != nil
        )
    }
}
