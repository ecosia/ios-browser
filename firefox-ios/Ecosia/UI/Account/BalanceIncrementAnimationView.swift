// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that displays a balance increment with fade in/out animation
@available(iOS 16.0, *)
public struct BalanceIncrementAnimationView: View {
    let increment: Int
    let textColor: Color
    let backgroundColor: Color
    @State private var opacity: Double

    public init(increment: Int,
                textColor: Color,
                backgroundColor: Color,
                opacity: Double = 0.0) {
        self.increment = increment
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.opacity = opacity
    }

    public var body: some View {
        Text("+\(increment)")
            .font(.caption.weight(.bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Circle())
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0.0
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
            BalanceIncrementAnimationView(increment: 1,
                                          textColor: .primary,
                                          backgroundColor: .secondary)
            BalanceIncrementAnimationView(increment: 3,
                                          textColor: .primary,
                                          backgroundColor: .secondary)
            BalanceIncrementAnimationView(increment: 10,
                                          textColor: .primary,
                                          backgroundColor: .secondary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
