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
    private(set) var newsViewModel: NTPNewsCellViewModel?
    private(set) var customizationViewModel: NTPCustomizationCellViewModel?
    
    // Delegates
    weak var headerDelegate: NTPHeaderDelegate?
    weak var libraryDelegate: NTPLibraryDelegate?
    weak var impactDelegate: NTPImpactCellDelegate?
    weak var newsDelegate: NTPNewsCellDelegate?
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
        
        // News
        newsViewModel = NTPNewsCellViewModel(
            delegate: newsDelegate,
            theme: theme
        )
        
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
        newsViewModel?.theme = theme
        customizationViewModel?.theme = theme
    }
    
    func updateDelegates(
        header: NTPHeaderDelegate?,
        library: NTPLibraryDelegate?,
        impact: NTPImpactCellDelegate?,
        news: NTPNewsCellDelegate?,
        customization: NTPCustomizationCellDelegate?
    ) {
        self.headerDelegate = header
        self.libraryDelegate = library
        self.impactDelegate = impact
        self.newsDelegate = news
        self.customizationDelegate = customization
        
        headerViewModel?.delegate = header
        libraryViewModel?.delegate = library
        impactViewModel?.delegate = impact
        newsViewModel?.delegate = news
        customizationViewModel?.delegate = customization
    }
    
    /// Returns the ordered list of Ecosia sections that should be displayed
    func getEcosiaSections() -> [HomepageSection] {
        var sections: [HomepageSection] = []
        
        if shouldShowHeader() {
            sections.append(.ecosiaHeader)
        }
        
        // Logo
        sections.append(.ecosiaLogo)
        
        // Library shortcuts
        sections.append(.ecosiaLibrary)
        
        // Climate impact (if enabled)
        if shouldShowImpact() {
            sections.append(.ecosiaImpact)
        }
        
        // News (if enabled)
        if shouldShowNews() {
            sections.append(.ecosiaNews)
        }
        
        // Customization
        sections.append(.ecosiaNTPCustomization)
        
        return sections
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
            // Impact section has multiple rows
            guard let impactViewModel = impactViewModel else { return [] }
            return impactViewModel.infoItemSections.enumerated().map { index, _ in
                .ecosiaImpact(sectionIndex: index)
            }
        case .ecosiaNews:
            return (0..<3).map { .ecosiaNewsCard(index: $0) }
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
    
    private func shouldShowImpact() -> Bool {
        return User.shared.showClimateImpact
    }
    
    private func shouldShowNews() -> Bool {
        return User.shared.showEcosiaNews
    }
    
    // MARK: - Lifecycle
    
    func viewWillAppear() {
        impactViewModel?.subscribeToProjections()
        // News automatically subscribes on init
    }
    
    func viewDidDisappear() {
        impactViewModel?.unsubscribeToProjections()
    }
    
    func refreshData(for traitCollection: UITraitCollection, size: CGSize) {
        newsViewModel?.refreshData(
            for: traitCollection,
            size: size,
            isPortrait: size.height > size.width,
            device: UIDevice.current.userInterfaceIdiom
        )
    }
    
    // MARK: - Ecosia: NTP Background

    /// Ecosia: Provides the wallpaper configuration for the NTP background
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

            do {
                portraitImage = try storageUtility.fetchImageNamed(currentWallpaper.portraitID)

                landscapeImage = try storageUtility.fetchImageNamed(currentWallpaper.landscapeID)
            } catch {
            }
        }

        // Fallback to default bundled background if nothing loaded
        if portraitImage == nil {
            portraitImage = UIImage(named: "ntpBackground")
            landscapeImage = UIImage(named: "ntpBackground")
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
