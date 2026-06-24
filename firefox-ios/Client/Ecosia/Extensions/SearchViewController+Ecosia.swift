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

    /* Ecosia: Upstream uses `viewModel.shouldShowHeader(for:)` directly. The redesigned
       suggestions list has no section headers for the typed-search state, so the per-engine
       search header ("Ecosia-Suche") and the relocated Suggest header ("Ecosia-Vorschläge")
       are both suppressed. Only the zero-search `recentSearches`/`trendingSearches` headers
       remain — they carry their section titles and the "Clear" accessory.
     */
    func shouldShowSearchSectionHeader(for section: Int, in tableView: UITableView) -> Bool {
        switch SearchListSection(rawValue: section) {
        case .searchSuggestions, .firefoxSuggestions, .openedTabs, .bookmarks, .remoteTabs, .history:
            return false
        default:
            return viewModel.shouldShowHeader(for: section)
        }
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

    /// Whether the AI Chat row should be rendered in the suggestions section.
    var shouldShowAIChatRow: Bool {
        AIChatMVPExperiment.isEnabled && !viewModel.searchQuery.isEmpty && suggestionsCount() != nil
    }

    /// Row index of the AI Chat item within the `searchSuggestions` section.
    /// It sits as the *second* row — directly after the first (typed) suggestion —
    /// to match the redesigned suggestions list. When there are no suggestions at
    /// all it collapses to the first (and only) row.
    var aiChatRowIndex: Int {
        min(1, suggestionsCount() ?? 0)
    }

    /// Check if current row is the AI Chat item
    func isAIChatRow(_ indexPath: IndexPath) -> Bool {
        guard SearchListSection(rawValue: indexPath.section) == .searchSuggestions else { return false }
        guard shouldShowAIChatRow else { return false }
        return indexPath.row == aiChatRowIndex
    }

    /// Maps a `searchSuggestions` table row to its index in `viewModel.suggestions`,
    /// accounting for the AI Chat row inserted at `aiChatRowIndex`. Rows after the
    /// insertion point are shifted back by one. Callers must already have excluded
    /// the AI Chat row itself via `isAIChatRow`.
    func suggestionIndex(forRow row: Int) -> Int {
        guard shouldShowAIChatRow else { return row }
        return row < aiChatRowIndex ? row : row - 1
    }

    /// Calculate number of rows including AI Chat item if enabled
    func numberOfRowsForSearchSuggestions() -> Int {
        guard let count = suggestionsCount() else { return 0 }
        return shouldShowAIChatRow ? count + 1 : count
    }

    // MARK: - AI Chat Navigation

    /// Handle AI Chat navigation when item is selected
    func handleAIChatSelection(_ indexPath: IndexPath) {
        let url = Environment.current.urlProvider.aiChat(origin: .autocomplete, query: viewModel.searchQuery)
        searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: viewModel.searchQuery)
        Analytics.shared.aiChatAutocompleteForQuery(viewModel.searchQuery)
    }

    // MARK: - AI Chat Cell Configuration

    /// Configure AI Chat cell appearance.
    ///
    /// The AI Search indicator is the `ai-sparkle` glyph shown as the row's *left*
    /// icon (replacing the magnifying glass), so the entry reads like a regular
    /// suggestion whose leading icon signals AI. The previous right-aligned "AI Chat"
    /// pill has been removed. `applyTheme` (run after this in `cellForRowAt`) tints
    /// the template glyph with `textPrimary`, matching the sibling suggestion icons.
    func configureAIChatCell(_ cell: OneLineTableViewCell) -> OneLineTableViewCell {
        cell.titleLabel.text = viewModel.searchQuery
        applyOneLineHeadTruncation(to: cell.titleLabel)

        let aiSparkle = UIImage.ecosia(named: "ai-sparkle")?.withRenderingMode(.alwaysTemplate)
        cell.leftImageView.layer.borderWidth = 0
        cell.leftImageView.backgroundColor = nil
        cell.leftImageView.manuallySetImage(aiSparkle ?? UIImage())
        // Render the sparkle at the 16×16 design size, matching the sibling suggestion icons.
        applySuggestionLeadingIconSize(to: cell)

        cell.accessoryView = nil
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

    /// Safely access the suggestion for a `searchSuggestions` table row, translating
    /// the row through `suggestionIndex(forRow:)` so the AI Chat row offset is handled.
    func safeSuggestion(forRow row: Int) -> String? {
        safeSuggestion(at: suggestionIndex(forRow: row))
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

// MARK: - Section Spacing
extension SearchViewController {
    enum SectionSpacingUX {
        /// Vertical gap between adjacent suggestion cards. The default grouped/insetGrouped
        /// footer height is much larger, which made the cards feel far apart.
        static let interSection: CGFloat = .ecosia.space._1s
    }

    /* Ecosia: `.insetGrouped` derives the gap between cards from the section footer height.
       Upstream provides no footer delegate, so the system default (large) gap was used.
       Override it with a small fixed gap — only for sections that actually have rows, so
       empty middle sections don't stack phantom spacing.
     */
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        tableView.numberOfRows(inSection: section) > 0 ? SectionSpacingUX.interSection : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
}

// MARK: - Suggestion Icon Sizing
extension SearchViewController {
    enum SuggestionListUX {
        /// Design size for the leading icons (magnifying glass, AI sparkle) in the
        /// suggestions list.
        static let leadingIconSize: CGFloat = 16
    }

    /// Returns `image` rasterised at the 16×16 suggestion-icon size, preserving template
    /// rendering so the cell theme can still tint it. `OneLineTableViewCell` constrains its
    /// left image view to a larger box, so we draw the glyph at this exact size and display
    /// it with `.center` content mode (see `applySuggestionLeadingIconSize`) instead of
    /// scaling the asset up.
    func suggestionLeadingIcon(_ image: UIImage?) -> UIImage? {
        guard let image else { return nil }
        let size = CGSize(width: SuggestionListUX.leadingIconSize, height: SuggestionListUX.leadingIconSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysTemplate)
    }

    /// Shrinks a configured suggestion cell's leading icon to the 16×16 design size.
    func applySuggestionLeadingIconSize(to cell: OneLineTableViewCell) {
        cell.leftImageView.contentMode = .center
        cell.leftImageView.manuallySetImage(suggestionLeadingIcon(cell.leftImageView.image) ?? UIImage())
    }
}

// MARK: - Close Button
extension SearchViewController {
    private enum CloseButtonUX {
        static let size: CGFloat = 36
        static let trailingPadding: CGFloat = .ecosia.space._s
        static let topPadding: CGFloat = .ecosia.space._s
        static let glyphSize: CGFloat = .ecosia.space._m
        /// Gap between the bottom of the close button and the first suggestion.
        static let listClearance: CGFloat = .ecosia.space._2s
    }

    /// Top inset reserved above the first suggestion so the list clears the floating
    /// close button — restores the top breathing room the (now hidden) section header
    /// used to provide, matching the original design. Applied as the table's top
    /// content inset in both the URL-bar and omnibox contexts.
    var ecosiaSuggestionsTopInset: CGFloat {
        CloseButtonUX.topPadding + CloseButtonUX.size + CloseButtonUX.listClearance
    }

    /// Floating button that dismisses the whole suggestions overlay (returns focus to
    /// the page / homepage). Built here to keep the Ecosia-specific UI out of the
    /// Firefox-core `SearchViewController`.
    func makeEcosiaCloseButton() -> UIButton {
        let button: UIButton = .build { button in
            button.setImage(.templateImageNamed("crossLarge"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.accessibilityLabel = .CloseButtonTitle
            button.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.Search.closeButton
            button.layer.cornerRadius = CloseButtonUX.size / 2
            button.addTarget(self, action: #selector(self.ecosiaCloseButtonTapped), for: .touchUpInside)
        }
        return button
    }

    /// Pins the close button to the top-trailing corner of the overlay, above the table.
    func setupEcosiaCloseButton() {
        view.addSubview(ecosiaCloseButton)
        NSLayoutConstraint.activate([
            ecosiaCloseButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: CloseButtonUX.topPadding
            ),
            ecosiaCloseButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -CloseButtonUX.trailingPadding
            ),
            ecosiaCloseButton.widthAnchor.constraint(equalToConstant: CloseButtonUX.size),
            ecosiaCloseButton.heightAnchor.constraint(equalToConstant: CloseButtonUX.size)
        ])

        if let glyph = ecosiaCloseButton.imageView {
            glyph.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                glyph.widthAnchor.constraint(equalToConstant: CloseButtonUX.glyphSize),
                glyph.heightAnchor.constraint(equalToConstant: CloseButtonUX.glyphSize)
            ])
        }
        applyEcosiaCloseButtonTheme()

        // Reserve room at the top of the list so the first suggestion clears the close
        // button. The omnibox context re-applies this in `updateOmniboxSuggestionsScrollInsets`.
        tableView.contentInset.top = ecosiaSuggestionsTopInset
        tableView.verticalScrollIndicatorInsets.top = ecosiaSuggestionsTopInset
    }

    /// Keeps the close button above newly inserted/refreshed cells in z-order.
    func bringEcosiaCloseButtonToFront() {
        view.bringSubviewToFront(ecosiaCloseButton)
    }

    func applyEcosiaCloseButtonTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        ecosiaCloseButton.backgroundColor = theme.colors.ecosia.backgroundElevation1
        ecosiaCloseButton.tintColor = theme.colors.ecosia.textPrimary
    }

    @objc
    func ecosiaCloseButtonTapped() {
        searchDelegate?.searchViewControllerDidTapCloseButton(self)
    }
}
