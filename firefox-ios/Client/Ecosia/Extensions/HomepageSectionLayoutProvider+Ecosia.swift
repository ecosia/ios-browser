// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

extension HomepageSectionLayoutProvider {
    
    /// Ecosia: Creates layout for Ecosia-specific sections
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
        case .ecosiaNews:
            return createEcosiaNewsLayout(for: environment)
        case .ecosiaNTPCustomization:
            return createEcosiaNTPCustomizationLayout(for: traitCollection)
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
        let insets = getEcosiaSectionInsets(traitCollection, topSpacing: NTPHeaderViewModel.UX.topInset, bottomSpacing: 0)
        section.contentInsets = insets
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
        
        let logoVerticalPadding: CGFloat = 24
        let insets = getEcosiaSectionInsets(traitCollection, topSpacing: logoVerticalPadding, bottomSpacing: logoVerticalPadding)
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
        // Dimensions from NTPImpactCellViewModel: item/group estimated(200) per row; footer from NTPImpactDividerFooter.UX.
        // Use estimated container height so the section sizes to content and doesn’t leave a large gap above News.
        let rowHeight: CGFloat = 200
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(rowHeight)
        )
        let firstItem = NSCollectionLayoutItem(layoutSize: itemSize)
        let firstGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: itemSize,
            subitem: firstItem,
            count: 1
        )
        let secondItem = NSCollectionLayoutItem(layoutSize: itemSize)
        let secondGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: itemSize,
            subitem: secondItem,
            count: 1
        )
        let containerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(rowHeight * 2)
        )
        let containerGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: containerSize,
            subitems: [firstGroup, secondGroup]
        )
        let section = NSCollectionLayoutSection(group: containerGroup)
        section.interGroupSpacing = 0
        let insets = getEcosiaSectionInsets(traitCollection, topSpacing: 0, bottomSpacing: 0)
        section.contentInsets = insets
        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(NTPImpactDividerFooter.UX.estimatedHeight)
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [footer]
        return section
    }
    
    /// News section layout and constraints aligned with NewsController (same dimensions, fonts via NTPNewsCell, and content insets).
    private func createEcosiaNewsLayout(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let traitCollection = environment.traitCollection
        // Same as NewsController: item and group estimated(100), horizontal group count 1 per row; we show 3 rows
        let itemEstimatedHeight: CGFloat = 100
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(itemEstimatedHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(itemEstimatedHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0
        // Content insets: horizontal same as NewsController (maxWidth centering); bottom 32 to match NTP sectionInsets(.news) so there is distance to the customize cell
        var newsInsets = newsSectionContentInsets(environment: environment)
        newsInsets.bottom = 32
        section.contentInsets = newsInsets
        // Header same as NewsController: fractionalWidth(1), estimated(100)
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100.0)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
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
    
    // MARK: - Helper Methods

    /// Content insets for the news section matching NewsController (same effective width and centering via maxWidth).
    private func newsSectionContentInsets(environment: NSCollectionLayoutEnvironment) -> NSDirectionalEdgeInsets {
        let width = environment.container.contentSize.width
        let minimumInset: CGFloat = 16
        let baseMaxWidth = width - (minimumInset * 2)
        let maxWidth: CGFloat
        if environment.traitCollection.userInterfaceIdiom == .pad {
            maxWidth = min(baseMaxWidth, 544)
        } else if environment.traitCollection.verticalSizeClass == .compact {
            maxWidth = min(baseMaxWidth, 375)
        } else {
            maxWidth = baseMaxWidth
        }
        let horizontal = max(0, (width - maxWidth) / 2)
        return NSDirectionalEdgeInsets(top: 0, leading: horizontal, bottom: 0, trailing: horizontal)
    }

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
        
        // Center layout in iPhone landscape or regular size class
        if traitCollection.horizontalSizeClass == .regular ||
           (orientation.isLandscape && traitCollection.userInterfaceIdiom == .phone) {
            horizontal = window.bounds.width / 4
        }
        
        return NSDirectionalEdgeInsets(
            top: topSpacing,
            leading: horizontal,
            bottom: bottomSpacing,
            trailing: horizontal
        )
    }
}
