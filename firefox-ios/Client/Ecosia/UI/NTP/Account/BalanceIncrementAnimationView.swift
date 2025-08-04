// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that displays a balance increment indicator with precise timing
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView: View {
    let increment: Int

    var body: some View {
        Text("+\(increment)")
            .font(.system(size: 16, weight: .bold)) // 16-18pt as specified
            .foregroundColor(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(red: 0.96, green: 0.96, blue: 0.86)) // Light cream/beige #F5F5DC
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BalanceIncrementAnimationView(increment: 1)
            BalanceIncrementAnimationView(increment: 3)
            BalanceIncrementAnimationView(increment: 10)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
