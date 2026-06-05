// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import Common
import Ecosia

// MARK: - Table View Style
extension SearchViewController {
    /* Ecosia: Use .insetGrouped so sections display with rounded corners and edge margins,
       matching the visual style of Settings screens (e.g. HomePageSettingViewController).
     */
    override var tableViewStyle: UITableView.Style { .insetGrouped }
}

// MARK: - Ecosia Suggest Header
extension SearchViewController {
    private static let ecosiaSuggestSections: [SearchListSection] = [
        .firefoxSuggestions,
        .openedTabs,
        .bookmarks,
        .remoteTabs,
        .history
    ]

    /* Ecosia: With `.insetGrouped`, the "Ecosia Suggest" header must sit on the first section
       that actually has rows. Firefox attaches it to `firefoxSuggestions`, but when
       remote suggestions are empty local results live in later sections — leaving a
       large gap between the header and the first item.
     */
    func ecosiaSuggestHeaderSection(in tableView: UITableView) -> Int? {
        guard viewModel.hasFirefoxSuggestions else { return nil }

        return Self.ecosiaSuggestSections.first { section in
            tableView.numberOfRows(inSection: section.rawValue) > 0
        }?.rawValue
    }

    func shouldShowEcosiaSuggestHeader(for section: Int, in tableView: UITableView) -> Bool {
        ecosiaSuggestHeaderSection(in: tableView) == section
    }

    /* Ecosia: Upstream uses `viewModel.shouldShowHeader(for:)` directly. With `.insetGrouped` we
       relocate the Suggest header and suppress the empty `firefoxSuggestions` section header.
     */
    func shouldShowSearchSectionHeader(for section: Int, in tableView: UITableView) -> Bool {
        if shouldShowEcosiaSuggestHeader(for: section, in: tableView) {
            return true
        }

        if SearchListSection(rawValue: section) == .firefoxSuggestions {
            return false
        }

        return viewModel.shouldShowHeader(for: section)
    }

    func configureEcosiaSuggestSectionHeader(_ headerView: SiteTableViewHeader) {
        headerView.configure(
            SiteTableViewHeaderModel(
                title: .Search.SuggestSectionTitle,
                accessory: .none
            )
        )
        applySearchSectionHeaderStyle(headerView)
    }

    /* Ecosia: Match Settings section headers: secondary text colour and no divider lines.
       SiteTableViewHeader enables top/bottom borders by default, which clash with
       `.insetGrouped` section spacing in the search overlay.
     */
    func applySearchSectionHeaderStyle(_ headerView: SiteTableViewHeader) {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        headerView.applyTheme(theme: theme)
        headerView.textLabel?.textColor = theme.colors.textSecondary
        headerView.showBorder(for: .top, false)
        headerView.showBorder(for: .bottom, false)
    }

    /* Ecosia: Branded open-tab badge for "Switch to tab" and synced-tab rows.
       Replaces Firefox's fixed-green `sync_open_tab` asset with the template `switchTab`
       icon from Ecosia.xcassets, tinted to match the design system.
     */
    func openTabBadgeImage(for theme: Theme) -> UIImage? {
        UIImage.templateImageNamed("switchTab")?
            .tinted(withColor: theme.colors.ecosia.buttonBackgroundPrimary)
    }
}

// MARK: - AI Chat Autocomplete Extensions
extension SearchViewController {

    // MARK: - Helper Methods

    func suggestionsCount() -> Int? {
        let max = 4 // Taken from Firefox code (it was hardcoded there)
        guard let count = viewModel.suggestions?.count else {
            return nil
        }
        return min(count, max)
    }

    /// Check if current row is the AI Chat item
    func isAIChatRow(_ indexPath: IndexPath) -> Bool {
        guard SearchListSection(rawValue: indexPath.section) == .searchSuggestions else { return false }
        let shouldShowAIChat = AIChatMVPExperiment.isEnabled && !viewModel.searchQuery.isEmpty
        guard shouldShowAIChat, let lastIndex = suggestionsCount() else { return false }
        return indexPath.row == lastIndex // Item after last suggestion (0-based index)
    }

    /// Calculate number of rows including AI Chat item if enabled
    func numberOfRowsForSearchSuggestions() -> Int {
        guard let count = suggestionsCount() else { return 0 }
        let shouldShowAIChat = AIChatMVPExperiment.isEnabled && !viewModel.searchQuery.isEmpty
        return shouldShowAIChat ? count + 1 : count
    }

    // MARK: - AI Chat Navigation

    /// Handle AI Chat navigation when item is selected
    func handleAIChatSelection(_ indexPath: IndexPath) {
        let url = Environment.current.urlProvider.aiChat(origin: .autocomplete, query: viewModel.searchQuery)
        searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: viewModel.searchQuery)
        Analytics.shared.aiChatAutocompleteForQuery(viewModel.searchQuery)
    }

    // MARK: - AI Chat Cell Configuration

    /// Configure AI Chat cell appearance
    func configureAIChatCell(_ cell: OneLineTableViewCell) -> OneLineTableViewCell {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        cell.titleLabel.text = viewModel.searchQuery
        applyOneLineHeadTruncation(to: cell.titleLabel)

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
        aiSearchLabel.text = String.localized(.aiChat)
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

        /* Ecosia: Wrap the pill in a transparent container so the pill sits flush to the left
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

    // MARK: - AI Chat Highlighting

    /// Handle AI Chat highlighting
    func handleAIChatHighlight(_ indexPath: IndexPath) {
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

    // MARK: - One-line Truncation

    /// Constrains a suggestion title to a single line truncated at the head so
    /// very long queries reveal the trailing portion (where the bold
    /// autocomplete completion lives) instead of wrapping over several rows.
    /// `OneLineTableViewCell.prepareForReuse` does not reset these label
    /// properties, but every suggestion-section cell configuration sets them
    /// explicitly, so reuse across sections stays consistent.
    func applyOneLineHeadTruncation(to titleLabel: UILabel) {
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingHead
    }
}
