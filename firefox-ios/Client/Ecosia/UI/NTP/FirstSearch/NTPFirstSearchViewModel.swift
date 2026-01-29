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

    struct UX {
        static let welcomeTitle = "Welcome to Your New Tab"
        static let welcomeDescription = "Start your search journey here. This is where you'll find everything you need."
    }

    // MARK: - HomepageViewModelProtocol Properties

    var sectionType: HomepageSectionType = .firstSearch
    var headerViewModel: LabelButtonHeaderViewModel = LabelButtonHeaderViewModel.emptyHeader
    let isEnabled: Bool = true

    internal var theme: Theme
    private var productTourManager: ProductTourManager
    weak var delegate: NTPFirstSearchViewModelDelegate?
    weak var dataModelDelegate: HomepageDataModelDelegate?

    // MARK: - Computed Properties

    var shouldShow: Bool {
        return productTourManager.shouldShowProductTourHomepage
    }

    // MARK: - Initialization

    init(theme: Theme, productTourManager: ProductTourManager = ProductTourManager.shared) {
        self.theme = theme
        self.productTourManager = productTourManager

        // Register as observer for product tour state changes
        productTourManager.addObserver(self)
    }

    deinit {
        productTourManager.removeObserver(self)
    }

    // MARK: - HomepageViewModelProtocol Methods

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

    func updatePrivacyConcernedSection(isPrivate: Bool) {
        // Product tour content is not affected by privacy mode
    }
}

// MARK: - HomepageSectionHandler

extension NTPFirstSearchViewModel: HomepageSectionHandler {

    func configure(_ collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(cellType: NTPFirstSearchCell.self, for: indexPath)
        cell?.configure(
            title: "Get started with Ecosia",
            description: "Try a search and discover how you're helping fight climate change by using Ecosia.",
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
        // This method is used by some legacy sections, but we handle configuration in the main configure method
        return cell
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {
        // Product tour NTP cell doesn't have a tap action currently
        // Could be extended in the future to show onboarding tips or advance tour state
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        // No long press action for product tour NTP cell
    }

    // MARK: - Private Action Handlers

    private func handleCloseAction() {
        Analytics.shared.firstSearchCardDismiss()
        productTourManager.completeTour()
        dataModelDelegate?.reloadView()
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
        // TODO: Delay to reload after url loading so it doesn't flash
        dataModelDelegate?.reloadView()
    }
}
