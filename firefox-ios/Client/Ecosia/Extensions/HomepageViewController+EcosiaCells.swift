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

    func configureEcosiaImpactCell(at indexPath: IndexPath, sectionIndex: Int, showRows: Bool) -> UICollectionViewCell {
        guard let cv = homepageCollectionView,
              let impactCell = cv.dequeueReusableCell(
            cellType: NTPImpactCell.self,
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }

        if let viewModel = ecosiaAdapter?.impactViewModel {
            let title = viewModel.rotatingTitle ?? RotatingTitlesService.fallbackTitles.first
            impactCell.configure(
                items: showRows ? viewModel.impactItems : [],
                title: title,
                delegate: ecosiaAdapter?.impactDelegate,
                theme: themeManager.getCurrentTheme(for: windowUUID)
            )
            viewModel.registerCell(impactCell, forSectionIndex: sectionIndex)
        }
        return impactCell
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

    // MARK: - NTP Search Bar Access

    // Ecosia: Stored via associated object so the pinned NTPSearchBarView can be themed later.
    var ntpSearchBar: NTPSearchBarView? {
        return objc_getAssociatedObject(self, &AssociatedKeys.ntpSearchBar) as? NTPSearchBarView
    }

    func setNTPSearchBar(_ view: NTPSearchBarView) {
        objc_setAssociatedObject(self, &AssociatedKeys.ntpSearchBar, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // Ecosia: Stored so it can be adjusted when the keyboard appears/disappears.
    var ntpSearchBarBottomConstraint: NSLayoutConstraint? {
        return objc_getAssociatedObject(self, &AssociatedKeys.ntpSearchBarBottomConstraint) as? NSLayoutConstraint
    }

    func setNTPSearchBarBottomConstraint(_ constraint: NSLayoutConstraint) {
        objc_setAssociatedObject(self, &AssociatedKeys.ntpSearchBarBottomConstraint, constraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Associated Keys

private struct AssociatedKeys {
    /// Used only as opaque key for objc_getAssociatedObject; no shared mutable state.
    nonisolated(unsafe) static var ecosiaAdapter: UInt8 = 0
    nonisolated(unsafe) static var ntpSearchBar: UInt8 = 0
    nonisolated(unsafe) static var ntpSearchBarBottomConstraint: UInt8 = 0
}
