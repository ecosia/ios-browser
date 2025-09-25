// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A view that displays a balance increment with fade in/out animation
@available(iOS 16.0, *)
public struct BalanceIncrementAnimationView: View {
    let increment: Int
    let windowUUID: WindowUUID
    @State private var opacity: Double
    @State private var theme = BalanceIncrementAnimationViewTheme()

    public init(increment: Int,
                windowUUID: WindowUUID,
                opacity: Double = 0.0) {
        self.increment = increment
        self.windowUUID = windowUUID
        self.opacity = opacity
    }

    public var body: some View {
        Text("+\(increment)")
            .font(.caption.weight(.bold))
            .foregroundColor(theme.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.backgroundColor)
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
            .ecosiaThemed(windowUUID, $theme)
    }
}

// MARK: - Theme
struct BalanceIncrementAnimationViewTheme: EcosiaThemeable {
    var textColor = Color.primary
    var backgroundColor = Color.secondary

    mutating func applyTheme(theme: Theme) {
        textColor = Color(EcosiaColor.Peach100)
        backgroundColor = Color(theme.colors.ecosia.brandImpact)
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BalanceIncrementAnimationView(increment: 1, windowUUID: .XCTestDefaultUUID)
            BalanceIncrementAnimationView(increment: 3, windowUUID: .XCTestDefaultUUID)
            BalanceIncrementAnimationView(increment: 10, windowUUID: .XCTestDefaultUUID)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
