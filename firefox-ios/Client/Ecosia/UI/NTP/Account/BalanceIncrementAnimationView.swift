// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that displays a balance increment indicator with precise timing
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView: View {
    let increment: Int
    let textColor: Color

    var body: some View {
        Text("+\(increment)")
            .font(.system(size: 16, weight: .bold)) // 16-18pt as specified
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(EcosiaColor.Peach100)) // Original Ecosia peach color
            .clipShape(Circle()) // Original circular shape
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
