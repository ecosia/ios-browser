// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A complete account navigation button component that combines seed view and avatar
@available(iOS 16.0, *)
public struct EcosiaAccountNavButton: View {
    private let seedCount: Int
    private let avatarURL: URL?
    private let onTap: () -> Void
    private let enableAnimation: Bool
    private let windowUUID: WindowUUID
    @State private var theme = EcosiaAccountNavButtonTheme()

    public init(
        seedCount: Int,
        avatarURL: URL? = nil,
        enableAnimation: Bool = true,
        windowUUID: WindowUUID,
        onTap: @escaping () -> Void
    ) {
        self.seedCount = seedCount
        self.avatarURL = avatarURL
        self.enableAnimation = enableAnimation
        self.windowUUID = windowUUID
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: .ecosia.space._1s) {
                EcosiaSeedView(
                    seedCount: seedCount,
                    iconSize: .ecosia.space._1l,
                    spacing: .ecosia.space._1s,
                    enableAnimation: enableAnimation,
                    windowUUID: windowUUID
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
            .background(theme.backgroundColor)
            .cornerRadius(.ecosia.borderRadius._1l)
        }
        .buttonStyle(PlainButtonStyle())
        .ecosiaThemed(windowUUID, $theme)
    }
}

// MARK: - Theme
struct EcosiaAccountNavButtonTheme: EcosiaThemeable {
    var backgroundColor = Color.gray.opacity(0.2)

    mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundElevation1)
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
                windowUUID: .XCTestDefaultUUID,
                onTap: {}
            )

            // Logged in state with avatar
            EcosiaAccountNavButton(
                seedCount: 42,
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                windowUUID: .XCTestDefaultUUID,
                onTap: {}
            )

            // High seed count
            EcosiaAccountNavButton(
                seedCount: 999,
                windowUUID: .XCTestDefaultUUID,
                onTap: {}
            )

            // Different avatar
            EcosiaAccountNavButton(
                seedCount: 25,
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                windowUUID: .XCTestDefaultUUID,
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
