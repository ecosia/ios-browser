// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Ecosia

struct NTPFirstSearchView: View {

    struct UX {
        static let contentTopSpacing: CGFloat = 40 // Includes space for the icon
        static let contentSpacing: CGFloat = 8
        static let extraSuggestionsSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 36
        static let iconCircleSize: CGFloat = 56
        static let closeButtonSize: CGFloat = 40
        static let closeButtonImageSize: CGFloat = 16
        static let closeButtonMargin: CGFloat = 8
        static let contentHorizontalPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 24
    }

    // MARK: - Properties

    let title: String
    let description: String
    let suggestions: [String]
    let windowUUID: WindowUUID
    let onClose: () -> Void
    let onSearchSuggestionTapped: (String) -> Void

    @State private var theme = NTPFirstSearchViewTheme()
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Main container
            VStack(spacing: 0) {
                // Top spacing for icon overlap
                Color.clear
                    .frame(height: UX.iconCircleSize / 2)

                // Content container
                ZStack(alignment: .topTrailing) {
                    // Main content
                    VStack(spacing: UX.contentSpacing) {
                        Text(title)
                            .font(.callout.weight(.semibold))
                            .foregroundColor(theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)

                        // Search suggestions
                        if !suggestions.isEmpty {
                            SearchSuggestionFlowLayout(
                                suggestions: suggestions,
                                onSuggestionTapped: onSearchSuggestionTapped,
                                theme: themeManager.getCurrentTheme(for: windowUUID),
                                availableWidth: nil // Will use parent width
                            )
                            .padding(.top, UX.extraSuggestionsSpacing)
                        }
                    }
                    .padding(.horizontal, UX.contentHorizontalPadding)
                    .padding(.top, UX.contentTopSpacing)
                    .padding(.bottom, UX.contentBottomPadding)

                    // Close button
                    Button(action: onClose) {
                        Image(uiImage: closeButtonImage)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UX.closeButtonImageSize, height: UX.closeButtonImageSize)
                            .foregroundColor(theme.buttonContentSecondary)
                            .frame(width: UX.closeButtonSize, height: UX.closeButtonSize)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(Text(verbatim: .localized(.close)))
                    .padding(.top, UX.closeButtonMargin)
                    .padding(.trailing, UX.closeButtonMargin)
                }
                .background(
                    RoundedRectangle(cornerRadius: UX.cornerRadius)
                        .fill(theme.backgroundElevation1)
                )
            }

            // Icon circle (overlapping the top)
            VStack(spacing: 0) {
                Circle()
                    .fill(theme.backgroundElevation1)
                    .frame(width: UX.iconCircleSize, height: UX.iconCircleSize)
                    .overlay(
                        Image(uiImage: iconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UX.iconSize, height: UX.iconSize)
                    )
                    .accessibilityHidden(true)

                Spacer()
            }
        }
        .ecosiaThemed(windowUUID, $theme)
    }

    // MARK: - Helper Properties

    private var iconImage: UIImage {
        UIImage(named: "plantedSeedling") ?? UIImage()
    }

    private var closeButtonImage: UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: UX.closeButtonImageSize, weight: .medium)
        return UIImage(named: "close", in: .ecosia, with: config) ?? UIImage()
    }
}

// MARK: - Theme

/// Theme configuration for NTPFirstSearchView
struct NTPFirstSearchViewTheme: EcosiaThemeable {
    var textPrimary = Color.black
    var textSecondary = Color.gray
    var backgroundElevation1 = Color.white
    var buttonContentSecondary = Color.gray

    mutating func applyTheme(theme: Theme) {
        textPrimary = Color(theme.colors.ecosia.textPrimary)
        textSecondary = Color(theme.colors.ecosia.textSecondary)
        backgroundElevation1 = Color(theme.colors.ecosia.backgroundElevation1)
        buttonContentSecondary = Color(theme.colors.ecosia.buttonContentSecondary)
    }
}
