// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

@available(iOS 16.0, *)
public struct EcosiaAIChatButton: View {
    private let windowUUID: WindowUUID
    private let onTap: () -> Void

    @State private var theme = EcosiaAIChatButtonTheme()

    public init(
        windowUUID: WindowUUID,
        onTap: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Image("ai-sparkle", bundle: .ecosia)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(theme.iconColor)
                .frame(width: .ecosia.space._1l, height: .ecosia.space._1l)
                .accessibilityHidden(true)
                .padding(.ecosia.space._2s)
                .frame(width: .ecosia.space._3l, height: .ecosia.space._3l)
                .background(theme.backgroundColor)
                .cornerRadius(.ecosia.borderRadius._1l)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(String.localized(.aiChat))
        .accessibilityHint(String.localized(.aiChatAccessibilityHint))
        .ecosiaThemed(windowUUID, $theme)
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAIChatButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {

            EcosiaAIChatButton(
                windowUUID: .XCTestDefaultUUID,
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
