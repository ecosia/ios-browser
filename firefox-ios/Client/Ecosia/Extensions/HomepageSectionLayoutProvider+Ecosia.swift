// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

extension HomepageSectionLayoutProvider {

    /// Creates layout for Ecosia-specific sections
    func createEcosiaLayoutSection(
        for section: HomepageSection,
        with environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection? {
        let traitCollection = environment.traitCollection

        switch section {
        case .ecosiaHeader:
            return createEcosiaHeaderLayout(for: traitCollection)
        case .ecosiaLogo:
            return createEcosiaLogoLayout(for: traitCollection)
        case .ecosiaLibrary:
            return createEcosiaLibraryLayout(for: traitCollection)
        case .ecosiaImpact:
            return createEcosiaImpactLayout(for: environment)
        case .ecosiaNTPCustomization:
            return createEcosiaNTPCustomizationLayout(for: traitCollection)
        case .topSites(_, let numberOfTilesPerRow):
            return createEcosiaTopSitesLayout(for: environment, numberOfTilesPerRow: numberOfTilesPerRow)
        default:
            return nil
        }
    }

    // MARK: - Individual Section Layouts

    private func createEcosiaHeaderLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // Dimensions from NTPHeaderViewModel
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(64)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(64)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        // NTPHeaderView owns all internal padding via SwiftUI modifiers; no additional insets needed here.
        section.contentInsets = .zero
        return section
    }

    private func createEcosiaLogoLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        let insets = getEcosiaSectionInsets(traitCollection, topSpacing: 0, bottomSpacing: 24)
        section.contentInsets = insets
        return section
    }

    private func createEcosiaLibraryLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        let insets = getEcosiaSectionInsets(traitCollection, topSpacing: 0, bottomSpacing: 8)
        section.contentInsets = insets
        return section
    }

    private func createEcosiaImpactLayout(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let traitCollection = environment.traitCollection

        /* Size the impact section to fill the remaining card height so TopSites is
           always pinned at the bottom. Subtract the fixed-height surrounding sections:
             • ecosiaHeader:  estimated 64 pt (matches createEcosiaHeaderLayout)
             • topSites row: square tile + section top/bottom insets (see ecosiaTopSitesSectionHeight)
           Also subtract the embedded NTP omnibox footprint (min height +
           a single `_1l` cushion above) so the TopSites grid clears the
           omnibox on every form factor instead of being covered by it. The
           cushion below the pill is supplied by its own bottom constraint,
           so we only reserve space for the pill itself plus a single gap
           above it — this gives the impact cell more room than reserving
           cushions on both sides.
         */
        let topSitesSectionHeight = ecosiaTopSitesSectionHeight(for: environment)
        let headerSectionHeight: CGFloat = 64
        let omniboxFootprint: CGFloat = NTPSearchBarView.minHeight + .ecosia.space._1l
        let fillHeight = environment.container.contentSize.height
            - headerSectionHeight
            - topSitesSectionHeight
            - omniboxFootprint
        // Fall back to content-size estimate so the cell is never shorter than its content.
        let impactHeight = max(304, fillHeight)

        // Ecosia: Use `.estimated` instead of `.absolute` so the cell can
        // self-size up to its intrinsic content height when the calculated
        // `fillHeight` is briefly wrong (e.g. during a SERP→NTP back
        // transition while the URL bar is still in the layout chain).
        // Without this the cell renders at the stale absolute size and the
        // impact rows look vertically compressed; with `.estimated`
        // autolayout takes over and the cell stays at the content's
        // intrinsic height regardless of the section's pre-computed value.
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(impactHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: itemSize,
            subitem: item,
            count: 1
        )
        let section = NSCollectionLayoutSection(group: group)
        /* Apply insets only on iPad (regular size class) to constrain the card to a readable width.
           On iPhone landscape the tiles go side-by-side and become too narrow if we apply
           window.bounds.width/4, so we skip the insets there and let the cell fill the width.
         */
        let insets = traitCollection.horizontalSizeClass == .regular
            ? getEcosiaSectionInsets(traitCollection, topSpacing: 0, bottomSpacing: 0)
            : NSDirectionalEdgeInsets.zero
        section.contentInsets = insets
        return section
    }

    private func createEcosiaNTPCustomizationLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(NTPCustomizationCell.UX.buttonHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(NTPCustomizationCell.UX.buttonHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        let insets = getEcosiaSectionInsets(traitCollection, topSpacing: 0, bottomSpacing: 32)
        section.contentInsets = insets
        return section
    }

    /// Shortcuts (top sites) layout — a single row of label-less square tiles whose edges line up
    /// with the omnibox below. On wide containers (iPad, landscape) the row is capped and centered.
    private func createEcosiaTopSitesLayout(
        for environment: NSCollectionLayoutEnvironment,
        numberOfTilesPerRow: Int
    ) -> NSCollectionLayoutSection {
        let section = TopSitesSectionLayoutProvider.createTopSitesSectionLayout(
            for: environment.traitCollection,
            numberOfTilesPerRow: numberOfTilesPerRow
        )
        let edgeInset = ecosiaTopSitesHorizontalInset(for: environment, numberOfTilesPerRow: numberOfTilesPerRow)
        /* TopSites row uses 16 pt (EcosiaSpacing._m) top so the row sits
           noticeably below the impact tiles above it, and 24 pt bottom
           (EcosiaSpacing._1l) so the gap to the omnibox stays balanced.
         */
        let insets = NSDirectionalEdgeInsets(
            top: Self.ecosiaTopSitesTopInset,
            leading: edgeInset,
            bottom: Self.ecosiaTopSitesBottomInset,
            trailing: edgeInset
        )
        section.contentInsets = insets
        return section
    }

    private static let ecosiaTopSitesTopInset: CGFloat = .ecosia.space._m
    private static let ecosiaTopSitesBottomInset: CGFloat = .ecosia.space._1l

    private func ecosiaTopSitesHorizontalInset(
        for environment: NSCollectionLayoutEnvironment,
        numberOfTilesPerRow: Int
    ) -> CGFloat {
        let tiles = CGFloat(numberOfTilesPerRow)
        let spacing = HomepageSectionLayoutProvider.UX.standardSpacing
        let maxRowWidth = tiles * TopSiteCell.UX.ecosiaGlassMaxTileSize + (tiles - 1) * spacing
        let omniboxInset = HomepageViewController.ntpSearchBarHorizontalInset(for: environment.traitCollection)
        let containerWidth = environment.container.contentSize.width
        return max(omniboxInset, (containerWidth - maxRowWidth) / 2)
    }

    private func ecosiaTopSitesSectionHeight(for environment: NSCollectionLayoutEnvironment) -> CGFloat {
        let tiles = CGFloat(TopSitesSectionLayoutProvider.UX.maxCards)
        let spacing = HomepageSectionLayoutProvider.UX.standardSpacing
        let edgeInset = ecosiaTopSitesHorizontalInset(for: environment, numberOfTilesPerRow: Int(tiles))
        let rowWidth = environment.container.contentSize.width - 2 * edgeInset
        let tileSize = min(TopSiteCell.UX.ecosiaGlassMaxTileSize, (rowWidth - (tiles - 1) * spacing) / tiles)
        return max(0, tileSize) + Self.ecosiaTopSitesTopInset + Self.ecosiaTopSitesBottomInset
    }

    // MARK: - Helper Methods

    private func getEcosiaSectionInsets(
        _ traitCollection: UITraitCollection,
        topSpacing: CGFloat = 0,
        bottomSpacing: CGFloat = 32
    ) -> NSDirectionalEdgeInsets {
        let minimumInsets: CGFloat = 16

        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return NSDirectionalEdgeInsets(
                top: topSpacing,
                leading: minimumInsets,
                bottom: bottomSpacing,
                trailing: minimumInsets
            )
        }

        var horizontal: CGFloat = traitCollection.horizontalSizeClass == .regular ? 100 : 0
        let safeAreaInsets = window.safeAreaInsets.left
        horizontal += minimumInsets + safeAreaInsets

        let orientation: UIInterfaceOrientation = window.windowScene?.interfaceOrientation ?? .portrait

        /* Center layout in iPhone landscape or regular size class.
           Cap content width at 420pt so iPad landscape tiles don't stretch too far.
         */
        if traitCollection.horizontalSizeClass == .regular ||
           (orientation.isLandscape && traitCollection.userInterfaceIdiom == .phone) {
            let maxContentWidth: CGFloat = 420
            horizontal = max(window.bounds.width / 4, (window.bounds.width - maxContentWidth) / 2)
        }

        return NSDirectionalEdgeInsets(
            top: topSpacing,
            leading: horizontal,
            bottom: bottomSpacing,
            trailing: horizontal
        )
    }
}
