// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Ecosia

protocol NTPFirstSearchViewModelDelegate: AnyObject {
    func searchWithQuery(_ query: String)
}

/// View model for the Product Tour NTP section that appears during onboarding
class NTPFirstSearchViewModel: HomepageViewModelProtocol, FeatureFlaggable {

    var sectionType: HomepageSectionType = .firstSearch
    var headerViewModel = LabelButtonHeaderViewModel.emptyHeader
    let isEnabled: Bool = true

    internal var theme: Theme
    private var productTourManager: ProductTourManager
    weak var delegate: NTPFirstSearchViewModelDelegate?
    weak var dataModelDelegate: HomepageDataModelDelegate?

    var shouldShow: Bool {
        return productTourManager.shouldShowProductTourHomepage
    }

    init(theme: Theme, productTourManager: ProductTourManager = ProductTourManager.shared) {
        self.theme = theme
        self.productTourManager = productTourManager

        productTourManager.addObserver(self)
    }

    deinit {
        productTourManager.removeObserver(self)
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(300)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(300)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: HomepageViewModel.UX.spacingBetweenSections,
            leading: leadingInset,
            bottom: 0,
            trailing: leadingInset
        )

        return section
    }

    func numberOfItemsInSection() -> Int {
        return shouldShow ? 1 : 0
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

// MARK: - HomepageSectionHandler

extension NTPFirstSearchViewModel: HomepageSectionHandler {

    func configure(_ collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(cellType: NTPFirstSearchCell.self, for: indexPath)
        cell?.configure(
            title: .localized(.ntpFirstSearchTitle),
            description: .localized(.ntpFirstSearchDescription),
            suggestions: LocalizedSearchSuggestions.suggestions()
        )
        cell?.onCloseButtonTapped = { [weak self] in
            self?.handleCloseAction()
        }
        cell?.onSearchSuggestionTapped = { [weak self] suggestion in
            self?.handleSearchSuggestion(suggestion)
        }
        cell?.applyTheme(theme: theme)
        return cell ?? UICollectionViewCell()
    }

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPFirstSearchCell else { return cell }
        cell.configure(
            title: .localized(.ntpFirstSearchTitle),
            description: .localized(.ntpFirstSearchDescription),
            suggestions: LocalizedSearchSuggestions.suggestions()
        )
        cell.onCloseButtonTapped = { [weak self] in
            self?.handleCloseAction()
        }
        cell.onSearchSuggestionTapped = { [weak self] suggestion in
            self?.handleSearchSuggestion(suggestion)
        }
        cell.applyTheme(theme: theme)
        return cell
    }

    // MARK: - Private Action Handlers

    private func handleCloseAction() {
        Analytics.shared.firstSearchCardDismiss()
        productTourManager.completeTour()
    }

    private func handleSearchSuggestion(_ suggestion: String) {
        // Find the index of the suggestion to track as pill number
        let suggestions = LocalizedSearchSuggestions.suggestions()
        if let pillIndex = suggestions.firstIndex(of: suggestion) {
            Analytics.shared.firstSearchCardSuggestionClick(pillNumber: pillIndex + 1) // 1-based indexing for analytics
        }
        delegate?.searchWithQuery(suggestion)
    }
}

// MARK: - ProductTourObserver

extension NTPFirstSearchViewModel: ProductTourObserver {
    func productTourStateDidChange(_ state: ProductTourState) {
        dataModelDelegate?.reloadView()
    }
}
