// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

// MARK: - Ecosia Cell Configuration

extension HomepageViewController {
    
    // MARK: - Ecosia Adapter Access
    
    var ecosiaAdapter: EcosiaHomepageAdapter? {
        // This will be set as a property on HomepageViewController
        return objc_getAssociatedObject(self, &AssociatedKeys.ecosiaAdapter) as? EcosiaHomepageAdapter
    }
    
    func setEcosiaAdapter(_ adapter: EcosiaHomepageAdapter) {
        objc_setAssociatedObject(self, &AssociatedKeys.ecosiaAdapter, adapter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    // MARK: - Cell Configuration Methods
    
    func configureEcosiaHeaderCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cv = homepageCollectionView else { return UICollectionViewCell() }
        if #available(iOS 16.0, *) {
            guard let headerCell = cv.dequeueReusableCell(
                cellType: NTPHeader.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }
            
            if let viewModel = ecosiaAdapter?.headerViewModel {
                headerCell.configure(with: viewModel, windowUUID: windowUUID)
            }
            return headerCell
        }
        return UICollectionViewCell()
    }
    
    func configureEcosiaLogoCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cv = homepageCollectionView,
              let logoCell = cv.dequeueReusableCell(
            cellType: NTPLogoCell.self,
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }
        
        logoCell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return logoCell
    }
    
    func configureEcosiaLibraryCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cv = homepageCollectionView,
              let libraryCell = cv.dequeueReusableCell(
            cellType: NTPLibraryCell.self,
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }
        
        libraryCell.delegate = ecosiaAdapter?.libraryDelegate
        libraryCell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return libraryCell
    }
    
    func configureEcosiaImpactCell(at indexPath: IndexPath, sectionIndex: Int) -> UICollectionViewCell {
        guard let cv = homepageCollectionView,
              let impactCell = cv.dequeueReusableCell(
            cellType: NTPImpactCell.self,
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }
        
        if let viewModel = ecosiaAdapter?.impactViewModel,
           sectionIndex < viewModel.infoItemSections.count {
            let items = viewModel.infoItemSections[sectionIndex]
            impactCell.configure(
                items: items,
                delegate: ecosiaAdapter?.impactDelegate,
                theme: themeManager.getCurrentTheme(for: windowUUID)
            )
            viewModel.registerCell(impactCell, forSectionIndex: sectionIndex)
        }
        return impactCell
    }
    
    func configureEcosiaNewsCell(at indexPath: IndexPath, itemIndex: Int = 0) -> UICollectionViewCell {
        guard let cv = homepageCollectionView,
              let newsCell = cv.dequeueReusableCell(
            cellType: NTPNewsCell.self,
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        if let viewModel = ecosiaAdapter?.newsViewModel,
           itemIndex < viewModel.items.count {
            let itemCount = min(3, viewModel.items.count)
            newsCell.configure(
                viewModel.items[itemIndex],
                images: Images(.init(configuration: .ephemeral)),
                row: itemIndex,
                totalCount: itemCount
            )
            newsCell.applyTheme(theme: theme)
        } else {
            newsCell.applyTheme(theme: theme)
        }
        return newsCell
    }
    
    func configureEcosiaNTPCustomizationCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cv = homepageCollectionView,
              let customizationCell = cv.dequeueReusableCell(
            cellType: NTPCustomizationCell.self,
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }
        
        customizationCell.delegate = ecosiaAdapter?.customizationDelegate
        customizationCell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return customizationCell
    }

    /// Ecosia: Configures the section header for the Ecosia News section (layout requires a header).
    /// Uses NTP typography: .title3.bold for section title (same as DefaultBrowser, other NTP headlines).
    func configureEcosiaNewsSectionHeader(with sectionLabelCell: LabelButtonHeaderView) -> LabelButtonHeaderView {
        let state = SectionHeaderConfiguration(
            title: String.localized(.ecosiaNews),
            a11yIdentifier: "ecosia.ntp.section.news",
            isButtonHidden: false,
            buttonA11yIdentifier: "see_all",
            buttonTitle: String.localized(.seeAll)
        )
        let moreButtonAction: (@MainActor (UIButton) -> Void)? = { [weak self] _ in
            self?.ecosiaAdapter?.newsDelegate?.openSeeAllNews()
        }
        sectionLabelCell.configure(state: state, moreButtonAction: moreButtonAction, textColor: nil, theme: themeManager.getCurrentTheme(for: windowUUID))
        sectionLabelCell.titleLabel.font = .preferredFont(forTextStyle: .title3).bold()
        sectionLabelCell.titleLabel.adjustsFontForContentSizeCategory = true
        return sectionLabelCell
    }
}

// MARK: - Associated Keys

private struct AssociatedKeys {
    /// Ecosia: Used only as opaque key for objc_getAssociatedObject; no shared mutable state.
    nonisolated(unsafe) static var ecosiaAdapter: UInt8 = 0
}
