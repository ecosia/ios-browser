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
            return createEcosiaImpactLayout(for: traitCollection)
        case .ecosiaNTPCustomization:
            return createEcosiaNTPCustomizationLayout(for: traitCollection)
        // Match shortcuts width to the other Ecosia sections (MOB-4150)
        case .topSites(_, let numberOfTilesPerRow):
            return createEcosiaTopSitesLayout(for: traitCollection, numberOfTilesPerRow: numberOfTilesPerRow)
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
        // No section insets — NTPHeaderView owns all internal padding via SwiftUI modifiers.
        // Horizontal: .ecosia.space._m (16pt) on each side.
        // Vertical:   .ecosia.space._m (16pt) top & bottom, giving a 72pt cell height.
        // The collection view is a child of the wallpaper card so card-edge alignment is
        // handled by containment, not by section content insets.
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

        // Top spacing is 0 — the header's SwiftUI .padding(.vertical, _m) provides ~16pt
        // of visual gap above the wordmark. Bottom spacing separates the logo from the impact tiles.
        let insets = getEcosiaSectionInsets(traitCollection, topSpacing: 0, bottomSpacing: 24)
        section.contentInsets = insets

        return section
    }

    private func createEcosiaLibraryLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // Dimensions from NTPLibaryCellViewModel: item fills group height, group estimated(100)
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

    private func createEcosiaImpactLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // NTPImpactCell is a SINGLE cell whose minimum height is NTPImpactCell.UX.minimumCellHeight.
        // The large minimum height lets the cell fill the wallpaper card, pushing shortcuts toward
        // the bottom. The estimated value here is a hint; the real height is set by the cell.
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(450)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: itemSize,
            subitem: item,
            count: 1
        )
        let section = NSCollectionLayoutSection(group: group)
        // Apply insets only on iPad (regular size class) to constrain the card to a readable width.
        // On iPhone landscape the tiles go side-by-side and become too narrow if we apply
        // window.bounds.width/4, so we skip the insets there and let the cell fill the width.
        let insets = traitCollection.horizontalSizeClass == .regular
            ? getEcosiaSectionInsets(traitCollection, topSpacing: 0, bottomSpacing: 0)
            : NSDirectionalEdgeInsets.zero
        section.contentInsets = insets
        return section
    }

    private func createEcosiaNTPCustomizationLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // Dimensions from NTPCustomizationCellViewModel (NTPCustomizationCell.UX.buttonHeight)
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

    /// Shortcuts (top sites) layout — uses the same insets as all other Ecosia sections so the grid
    /// is the same width as impact, news, and library on every device, including iPad.
    private func createEcosiaTopSitesLayout(
        for traitCollection: UITraitCollection,
        numberOfTilesPerRow: Int
    ) -> NSCollectionLayoutSection {
        let section = TopSitesSectionLayoutProvider.createTopSitesSectionLayout(
            for: traitCollection,
            numberOfTilesPerRow: numberOfTilesPerRow
        )
        // Shortcuts use the same 12pt horizontal inset as the impact tiles so all sections
        // share a consistent left/right edge within the wallpaper card (Figma: space-s = 12pt).
        let edgeInset: CGFloat = traitCollection.horizontalSizeClass == .regular ? 100 : .ecosia.space._s
        // Equal top and bottom insets vertically center the shortcut grid in the remaining
        // card space below the impact tiles.
        let insets = NSDirectionalEdgeInsets(
            top: CGFloat.ecosia.space._m,
            leading: edgeInset,
            bottom: CGFloat.ecosia.space._m,
            trailing: edgeInset
        )
        section.contentInsets = insets
        // No section header — Figma shortcuts section has no title label above the tiles
        return section
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

        // Center layout in iPhone landscape or regular size class.
        // Cap content width at 420pt so iPad landscape tiles don't stretch too far.
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
