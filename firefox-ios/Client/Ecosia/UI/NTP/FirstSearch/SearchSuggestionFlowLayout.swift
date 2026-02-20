// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

/// SwiftUI view that provides a stable flow layout for search suggestion pills
struct SearchSuggestionFlowLayout: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void
    let theme: Theme
    let availableWidth: CGFloat?

    var body: some View {
        FlowLayoutContainer(
            items: suggestions,
            spacing: 8,
            theme: theme,
            availableWidth: availableWidth,
            onTap: onSuggestionTapped
        )
    }
}

/// Container that handles the flow layout
struct FlowLayoutContainer: View {
    let items: [String]
    let spacing: CGFloat
    let theme: Theme
    let availableWidth: CGFloat?
    let onTap: (String) -> Void

    var body: some View {
        let width = availableWidth ?? UIScreen.main.bounds.width - 32 // Minus margins
        let rows = computeRows(availableWidth: width)

        VStack(alignment: .center, spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        SearchSuggestionPill(
                            text: item,
                            theme: theme,
                            onTap: { onTap(item) }
                        )
                    }
                }
            }
        }
    }

    private func computeRows(availableWidth: CGFloat) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentRowWidth: CGFloat = 0

        for item in items {
            let estimatedPillWidth = estimatePillWidth(for: item)
            let requiredWidth = currentRowWidth + estimatedPillWidth + (currentRow.isEmpty ? 0 : spacing)

            if requiredWidth <= availableWidth || currentRow.isEmpty {
                currentRow.append(item)
                currentRowWidth = requiredWidth
            } else {
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [item]
                currentRowWidth = estimatedPillWidth
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private func estimatePillWidth(for text: String) -> CGFloat {
        let textSize = measureText(text, font: SearchSuggestionPill.UX.font)
        return textSize.width + SearchSuggestionPill.UX.totalNonTextWidth
    }

    private func measureText(_ text: String, font: UIFont) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}

/// Individual pill for search suggestions
struct SearchSuggestionPill: View {
    let text: String
    let theme: Theme
    let onTap: () -> Void

    struct UX {
        static let fontSize: CGFloat = 15 // subheadline equivalent
        static let fontWeight: UIFont.Weight = .regular
        static let iconSize: CGFloat = 16
        static let iconTextSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 12
        static let height: CGFloat = 44
        static let cornerRadius: CGFloat = 22
        static let borderWidth: CGFloat = 1

        static var totalHorizontalPadding: CGFloat {
            horizontalPadding * 2
        }

        static var totalNonTextWidth: CGFloat {
            iconSize + iconTextSpacing + totalHorizontalPadding + borderWidth
        }

        static var font: UIFont {
            UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UX.iconTextSpacing) {
                Text(text)
                    .preferredBodyFont(size: UX.fontSize)
                    .foregroundColor(Color(theme.colors.ecosia.buttonContentSecondary))
                    .lineLimit(1)
                    .fixedSize()

                if let searchIcon = UIImage(named: "searchUrl") {
                    Image(uiImage: searchIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(theme.colors.ecosia.iconDecorative))
                        .frame(width: UX.iconSize, height: UX.iconSize)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, UX.horizontalPadding)
            .padding(.vertical, UX.verticalPadding)
            .frame(height: UX.height)
        }
        .buttonStyle(HighlightButtonStyle(theme: theme))
    }
}

/// Button style that shows highlight state during tap
struct HighlightButtonStyle: ButtonStyle {
    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: SearchSuggestionPill.UX.cornerRadius)
                    .stroke(Color(theme.colors.ecosia.borderDecorative), lineWidth: SearchSuggestionPill.UX.borderWidth)
                    .background(
                        RoundedRectangle(cornerRadius: SearchSuggestionPill.UX.cornerRadius)
                            .fill(Color(configuration.isPressed
                                ? theme.colors.ecosia.buttonBackgroundSecondaryActive
                                : theme.colors.ecosia.buttonBackgroundSecondary))
                    )
            )
    }
}
