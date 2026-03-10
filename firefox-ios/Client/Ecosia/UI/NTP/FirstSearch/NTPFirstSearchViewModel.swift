// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Ecosia

@MainActor
protocol NTPFirstSearchCellViewModelDelegate: AnyObject {
    func searchWithQuery(_ query: String)
}

/// View model for the Product Tour NTP section that appears during onboarding
@MainActor
class NTPFirstSearchCellViewModel {

    internal var theme: Theme
    let windowUUID: WindowUUID
    // Safety: set once at init, accessed in nonisolated deinit only for removeObserver.
    private nonisolated(unsafe) var productTourManager: ProductTourManager
    weak var delegate: NTPFirstSearchCellViewModelDelegate?
    weak var dataModelDelegate: HomepageDataModelDelegate?

    var shouldShow: Bool {
        return productTourManager.shouldShowProductTourHomepage
            && !productTourManager.isSignInFlowActive
    }

    init(theme: Theme,
         windowUUID: WindowUUID,
         productTourManager: ProductTourManager = ProductTourManager.shared) {
        self.theme = theme
        self.windowUUID = windowUUID
        self.productTourManager = productTourManager

        productTourManager.addObserver(self)
    }

    deinit {
        productTourManager.removeObserver(self)
    }

    // MARK: - Cell Configuration

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPFirstSearchCell else { return cell }
        cell.configure(
            title: .localized(.ntpFirstSearchTitle),
            description: .localized(.ntpFirstSearchDescription),
            suggestions: LocalizedSearchSuggestions.suggestions(),
            windowUUID: windowUUID
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
        let suggestions = LocalizedSearchSuggestions.suggestions()
        if let pillIndex = suggestions.firstIndex(of: suggestion) {
            let languageRegionIdentifier = LocalizedSearchSuggestions.currentRegionLanguageAnalyticsIdentifier()
            Analytics.shared.firstSearchCardSuggestionClick(
                pillNumber: pillIndex + 1,
                languageRegionIdentifier: languageRegionIdentifier
            )
        }
        delegate?.searchWithQuery(suggestion)
    }
}

/* Ecosia: Removed legacy protocol conformances - now using EcosiaHomepageAdapter
// MARK: - HomepageSectionHandler

extension NTPFirstSearchCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPFirstSearchCell else { return cell }
        cell.configure(
            title: .localized(.ntpFirstSearchTitle),
            description: .localized(.ntpFirstSearchDescription),
            suggestions: LocalizedSearchSuggestions.suggestions(),
            windowUUID: windowUUID
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
}
*/

// MARK: - ProductTourObserver

extension NTPFirstSearchCellViewModel: ProductTourObserver {
    func productTour(didReceiveEvent event: ProductTourEvent) {
        dataModelDelegate?.reloadView()
    }
}
