// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// One error toast row hosted in the overlapping z-stacked toast container.
@available(iOS 16.0, *)
public struct EcosiaErrorToastRowContent: View {
    private struct UX {
        static let cardMinHeight: CGFloat = 56
    }

    let message: String
    let windowUUID: WindowUUID
    let onCloseTapped: () -> Void

    public init(
        message: String,
        windowUUID: WindowUUID,
        onCloseTapped: @escaping () -> Void
    ) {
        self.message = message
        self.windowUUID = windowUUID
        self.onCloseTapped = onCloseTapped
    }

    public var body: some View {
        EcosiaErrorView(
            subtitle: message,
            windowUUID: windowUUID,
            onCloseTapped: onCloseTapped
        )
        .frame(minHeight: UX.cardMinHeight)
        .padding(.horizontal, .ecosia.space._m)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorToastRowContent_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaErrorToastRowContent(
            message: "The file is too large, the maximum file size is 5MB.",
            windowUUID: .XCTestDefaultUUID,
            onCloseTapped: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
