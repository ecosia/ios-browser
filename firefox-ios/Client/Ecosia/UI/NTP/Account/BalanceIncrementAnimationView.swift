// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that displays a balance increment animation with a circled number and + prefix
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView: View {
    let increment: Int
    let textColor: Color
    @State private var isAnimating = false
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 4) {
            Text("+\(increment)")
                .font(.caption.weight(.bold))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(EcosiaColor.Peach100))
        .clipShape(Circle())
        .scaleEffect(isAnimating ? 1.2 : 1.0)
        .opacity(opacity)
        .offset(y: isAnimating ? -50 : 0)
        .animation(.easeOut(duration: 1.5), value: isAnimating)
        .animation(.easeInOut(duration: 0.7), value: opacity)
        .onAppear {
            // Start animation sequence after seed count animation finishes
            let delayBeforeStart = 0.5 // Start shortly before the seedCountText animation (0.6 delay)
            let animationDuration = 1.5 // Much slower than seedCountText (0.3)
            let fadeOutDuration = 0.7
            let totalDisplayTime = 3.5
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeStart) {
                opacity = 1.0
                
                withAnimation(.easeOut(duration: animationDuration)) {
                    isAnimating = true
                }
                
                // Fade out after total display time
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDisplayTime) {
                    withAnimation(.easeInOut(duration: fadeOutDuration)) {
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
