// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A complete account navigation button component that combines seed view and avatar
@available(iOS 16.0, *)
public struct EcosiaAccountNavButton: View {
    private let seedCount: Int
    private let avatarURL: URL?
    private let backgroundColor: Color
    private let textColor: Color
    private let onTap: () -> Void
    private let enableAnimation: Bool

    public init(
        seedCount: Int,
        avatarURL: URL? = nil,
        backgroundColor: Color = .gray.opacity(0.2),
        textColor: Color = .primary,
        enableAnimation: Bool = true,
        onTap: @escaping () -> Void
    ) {
        self.seedCount = seedCount
        self.avatarURL = avatarURL
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.enableAnimation = enableAnimation
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: .ecosia.space._1s) {
                EcosiaSeedView(
                    seedCount: seedCount,
                    iconSize: .ecosia.space._1l,
                    textColor: textColor,
                    spacing: .ecosia.space._1s,
                    enableAnimation: enableAnimation
                )

                EcosiaAvatar(
                    avatarURL: avatarURL,
                    size: .ecosia.space._2l
                )
            }
            .padding(.top, .ecosia.space._2s)
            .padding(.bottom, .ecosia.space._2s)
            .padding(.leading, .ecosia.space._1s)
            .padding(.trailing, .ecosia.space._2s)
            .frame(minWidth: .ecosia.space._8l, minHeight: .ecosia.space._3l, maxHeight: .ecosia.space._3l)
            .background(backgroundColor)
            .cornerRadius(.ecosia.borderRadius._1l)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAccountNavButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {

            // Logged out state
            EcosiaAccountNavButton(
                seedCount: 1,
                backgroundColor: .gray.opacity(0.2),
                onTap: {}
            )

            // Logged in state with avatar
            EcosiaAccountNavButton(
                seedCount: 42,
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                backgroundColor: .blue.opacity(0.2),
                onTap: {}
            )

            // High seed count
            EcosiaAccountNavButton(
                seedCount: 999,
                backgroundColor: .green.opacity(0.2),
                textColor: .green,
                onTap: {}
            )

            // Dark background
            EcosiaAccountNavButton(
                seedCount: 25,
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                backgroundColor: .black.opacity(0.8),
                textColor: .white,
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
