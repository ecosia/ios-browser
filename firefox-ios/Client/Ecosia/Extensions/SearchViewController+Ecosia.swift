// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Ecosia

// MARK: - Table View Style
extension SearchViewController {
    /* Use .insetGrouped so sections display with rounded corners and edge margins,
       matching the visual style of Settings screens (e.g. HomePageSettingViewController).
     */
    override var tableViewStyle: UITableView.Style { .insetGrouped }
}

// MARK: - AI Search Autocomplete Extensions
extension SearchViewController {

    // MARK: - Helper Methods

    func suggestionsCount() -> Int? {
        let max = 4 // Taken from Firefox code (it was hardcoded there)
        guard let count = viewModel.suggestions?.count else {
            return nil
        }
        return min(count, max)
    }

    /// Check if current row is the AI Search item
    func isAISearchRow(_ indexPath: IndexPath) -> Bool {
        guard SearchListSection(rawValue: indexPath.section) == .searchSuggestions else { return false }
        let shouldShowAISearch = AISearchMVPExperiment.isEnabled && !viewModel.searchQuery.isEmpty
        guard shouldShowAISearch, let lastIndex = suggestionsCount() else { return false }
        return indexPath.row == lastIndex // Item after last suggestion (0-based index)
    }

    /// Calculate number of rows including AI Search item if enabled
    func numberOfRowsForSearchSuggestions() -> Int {
        guard let count = suggestionsCount() else { return 0 }
        let shouldShowAISearch = AISearchMVPExperiment.isEnabled && !viewModel.searchQuery.isEmpty
        return shouldShowAISearch ? count + 1 : count
    }

    // MARK: - AI Search Navigation

    /// Handle AI Search navigation when item is selected
    func handleAISearchSelection(_ indexPath: IndexPath) {
        let url = Environment.current.urlProvider.aiSearch(origin: .autocomplete)
        let finalURL = url.appendingQueryItems([URLQueryItem(name: "q", value: viewModel.searchQuery)])

        searchDelegate?.searchViewController(self, didSelectURL: finalURL, searchTerm: viewModel.searchQuery)
        Analytics.shared.aiSearchAutocompleteForQuery(viewModel.searchQuery)
    }

    // MARK: - AI Search Cell Configuration

    /// Configure AI Search cell appearance
    func configureAISearchCell(_ cell: OneLineTableViewCell) -> OneLineTableViewCell {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        cell.titleLabel.text = viewModel.searchQuery

        let aiSearchImage = UIImage(named: "searchLarge")?.withRenderingMode(.alwaysTemplate)
        cell.leftImageView.contentMode = .center
        cell.leftImageView.layer.borderWidth = 0
        cell.leftImageView.manuallySetImage(aiSearchImage ?? UIImage())
        cell.leftImageView.tintColor = theme.colors.ecosia.buttonBackgroundPrimary
        cell.leftImageView.backgroundColor = nil

        let standardImageSize: CGFloat = OneLineTableViewCell.UX.leftImageViewSize
        let dynamicImageSize = min(UIFontMetrics.default.scaledValue(for: standardImageSize), 2 * standardImageSize)
        cell.leftImageView.widthAnchor.constraint(equalToConstant: dynamicImageSize).isActive = true
        cell.leftImageView.heightAnchor.constraint(equalToConstant: dynamicImageSize).isActive = true

        let twinkleImageView = UIImageView()
        twinkleImageView.image = .ecosia(named: "ai-sparkle")?.withRenderingMode(.alwaysTemplate)
        twinkleImageView.tintColor = theme.colors.ecosia.textInversePrimary
        twinkleImageView.contentMode = .scaleAspectFit

        let aiSearchLabel = UILabel()
        aiSearchLabel.text = String.localized(.aiSearch)
        aiSearchLabel.textColor = theme.colors.ecosia.textInversePrimary
        aiSearchLabel.font = .preferredFont(forTextStyle: .caption1)
        aiSearchLabel.sizeToFit()

        let twinkleSize: CGFloat = .ecosia.space._m
        let internalPadding: CGFloat = .ecosia.space._1s
        let spacing: CGFloat = .ecosia.space._2s

        // Create the actual pill container matching titleLabel height
        let pillContainer = UIView()
        pillContainer.backgroundColor = theme.colors.ecosia.buttonBackgroundPrimary

        let pillWidth = internalPadding + twinkleSize + spacing + aiSearchLabel.frame.width + internalPadding
        // Ensure layout is up-to-date before reading frames
        cell.layoutIfNeeded()
        let pillHeight = aiSearchLabel.frame.height + .ecosia.space._1s

        // Calculate Y position to center pill with leftImageView
        let leftImageCenterY = cell.leftImageView.frame.midY
        let pillY = leftImageCenterY - (pillHeight / 2)

        pillContainer.frame = CGRect(x: 0, y: 0, width: pillWidth, height: pillHeight)
        pillContainer.layer.cornerRadius = pillHeight / 2

        twinkleImageView.frame = CGRect(x: internalPadding, y: (pillHeight - twinkleSize) / 2, width: twinkleSize, height: twinkleSize)
        aiSearchLabel.frame = CGRect(x: internalPadding + twinkleSize + spacing, y: (pillHeight - aiSearchLabel.frame.height) / 2, width: aiSearchLabel.frame.width, height: aiSearchLabel.frame.height)

        pillContainer.addSubview(twinkleImageView)
        pillContainer.addSubview(aiSearchLabel)

        /* Wrap the pill in a transparent container so the pill sits flush to the left
           of the wrapper while the trailing gap (10 pt) creates visual separation from the
           cell's right edge.
         */
        let trailingGap: CGFloat = 10
        let accessoryWrapper = UIView(frame: CGRect(x: 0, y: pillY, width: pillWidth + trailingGap, height: pillHeight))
        accessoryWrapper.backgroundColor = .clear
        accessoryWrapper.addSubview(pillContainer)
        cell.accessoryView = accessoryWrapper

        return cell
    }

    // MARK: - AI Search Highlighting

    /// Handle AI Search highlighting
    func handleAISearchHighlight(_ indexPath: IndexPath) {
        searchDelegate?.searchViewController(self, didHighlightText: viewModel.searchQuery, search: false)
    }

    // MARK: - Safe Array Access

    /// Safely access suggestions array with bounds checking
    func safeSuggestion(at index: Int) -> String? {
        guard let suggestions = viewModel.suggestions,
              index < min(suggestions.count, 4) else { return nil }
        return suggestions[index]
    }

    /// Check if index is valid for suggestions array access
    func isValidSuggestionIndex(_ index: Int) -> Bool {
        guard let suggestions = viewModel.suggestions else { return false }
        return index < min(suggestions.count, 4)
    }
}
