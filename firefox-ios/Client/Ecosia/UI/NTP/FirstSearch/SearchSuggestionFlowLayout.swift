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

    var body: some View {
        FlowLayoutContainer(
            items: suggestions,
            spacing: 8,
            theme: theme,
            onTap: onSuggestionTapped
        )
    }
}

/// Container that handles the flow layout using a simpler, more reliable approach
struct FlowLayoutContainer: View {
    let items: [String]
    let spacing: CGFloat
    let theme: Theme
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { row in
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
        .frame(maxWidth: .infinity)
    }

    private func computeRows() -> [[String]] {
        // Use a more realistic width estimation based on iPhone screen sizes
        // iPhone widths: iPhone SE: 375, iPhone Pro: 390-430, with padding ~16 on each side
        let estimatedAvailableWidth: CGFloat = 350 // More realistic estimate for most iPhones
        
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentRowWidth: CGFloat = 0
        
        for item in items {
            // Estimate pill width (this is approximate but should work well)
            let estimatedPillWidth = estimatePillWidth(for: item)
            let requiredWidth = currentRowWidth + estimatedPillWidth + (currentRow.isEmpty ? 0 : spacing)
            
            if requiredWidth <= estimatedAvailableWidth || currentRow.isEmpty {
                // Item fits in current row
                currentRow.append(item)
                currentRowWidth = requiredWidth
            } else {
                // Start new row
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = [item]
                currentRowWidth = estimatedPillWidth
            }
        }
        
        // Add the last row
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private func estimatePillWidth(for text: String) -> CGFloat {
        // More accurate estimation based on actual pill appearance
        let characterWidth: CGFloat = 7.5 // Slightly smaller based on subheadline font
        let iconSpace: CGFloat = 20 // Icon + spacing
        let horizontalPadding: CGFloat = 16 // 8 on each side
        let borderWidth: CGFloat = 2 // Account for stroke
        
        return CGFloat(text.count) * characterWidth + iconSpace + horizontalPadding + borderWidth
    }
}

/// Individual pill for search suggestions
struct SearchSuggestionPill: View {
    let text: String
    let theme: Theme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(Color(theme.colors.textPrimary))
                    .lineLimit(1)

                if let searchIcon = UIImage(named: "searchUrl") {
                    Image(uiImage: searchIcon)
                        .foregroundColor(Color(theme.colors.iconSecondary))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(theme.colors.borderPrimary), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.clear)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
