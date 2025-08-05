// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that displays a balance increment indicator with simple fade animation
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView: View {
    let increment: Int
    let textColor: Color
    @State private var opacity: Double = 0

    var body: some View {
        Text("+\(increment)")
            .font(.caption.weight(.bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(EcosiaColor.Peach100))
            .clipShape(Circle())
            .opacity(opacity)
            .onAppear {
                // Start after seed animation completes
                let delayBeforeStart = 1.0
                let fadeInDuration = 0.3
                let visibleDuration = 2.0
                let fadeOutDuration = 0.5
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeStart) {
                    // Fade in
                    withAnimation(.easeIn(duration: fadeInDuration)) {
                        opacity = 1.0
                    }
                    
                    // Fade out after being visible
                    DispatchQueue.main.asyncAfter(deadline: .now() + visibleDuration) {
                        withAnimation(.easeOut(duration: fadeOutDuration)) {
                            opacity = 0
                        }
                    }
                }
            }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BalanceIncrementAnimationView(increment: 1, textColor: .primary)
            BalanceIncrementAnimationView(increment: 3, textColor: .primary)
            BalanceIncrementAnimationView(increment: 10, textColor: .primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
