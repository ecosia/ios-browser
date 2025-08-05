// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that displays a balance increment with web-style upward slide animation
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView: View {
    let increment: Int
    let textColor: Color
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Text("+\(increment)")
            .font(.caption.weight(.bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(EcosiaColor.Peach100))
            .clipShape(Circle())
            .opacity(opacity)
            .offset(y: yOffset)
            .onAppear {
                // Appear when seed reaches maximum compression (0.3s)
                let seedCompressionDuration = 0.3
                
                DispatchQueue.main.asyncAfter(deadline: .now() + seedCompressionDuration) {
                    // Stay in place for 15% of animation time (like web's 0%-15%)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) { // 0.075 = 15% of 0.5s
                        
                        // Web's bouncy slide up animation: translateY(-100%)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.45, blendDuration: 0)) {
                            yOffset = -40 // Slide up (equivalent to -100% of its height)
                            opacity = 0.0 // Fade out as it slides up
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
