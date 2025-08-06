// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A circular button for AI search functionality with twinkle icon
@available(iOS 16.0, *)
public struct EcosiaAISearchButton: View {
    private let backgroundColor: Color
    private let iconColor: Color
    private let onTap: () -> Void
    
    public init(
        backgroundColor: Color = .gray.opacity(0.2),
        iconColor: Color = .primary,
        onTap: @escaping () -> Void
    ) {
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            Image("twinkle", bundle: .ecosia)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(iconColor)
                .frame(width: .ecosia.space._1l, height: .ecosia.space._1l)
                .padding(.ecosia.space._2s)
                .frame(width: .ecosia.space._3l, height: .ecosia.space._3l)
                .background(backgroundColor)
                .cornerRadius(.ecosia.borderRadius._1l)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("AI Search")
        .accessibilityHint("Opens AI search functionality")
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAISearchButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {
            // Light theme
            EcosiaAISearchButton(
                backgroundColor: .gray.opacity(0.2),
                iconColor: .primary,
                onTap: {}
            )
            
            // Dark theme
            EcosiaAISearchButton(
                backgroundColor: .black.opacity(0.8),
                iconColor: .white,
                onTap: {}
            )
            
            // Green theme
            EcosiaAISearchButton(
                backgroundColor: .green.opacity(0.2),
                iconColor: .green,
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif