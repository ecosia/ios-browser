// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// An inline error view component for displaying errors within the account impact view
@available(iOS 16.0, *)
struct EcosiaAccountErrorView: View {
    private let title: String
    private let subtitle: String
    private let windowUUID: WindowUUID

    @State private var theme = EcosiaAccountErrorViewTheme()

    private struct UX {
        static let borderWidth: CGFloat = 1
    }

    init(title: String, subtitle: String, windowUUID: WindowUUID) {
        self.title = title
        self.subtitle = subtitle
        self.windowUUID = windowUUID
    }

    var body: some View {
        HStack(alignment: .top, spacing: .ecosia.space._m) {
            Image("problem", bundle: .ecosia)
                .resizable()
                .frame(width: .ecosia.space._1l, height: .ecosia.space._1l)
                .foregroundColor(theme.iconColor)

            VStack(alignment: .leading, spacing: .ecosia.space._1s) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.textPrimaryColor)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondaryColor)
            }
        }
        .padding(.ecosia.space._m)
        .background(
            RoundedRectangle(cornerRadius: .ecosia.borderRadius._m)
                .fill(theme.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: .ecosia.borderRadius._m)
                        .stroke(theme.borderColor, lineWidth: UX.borderWidth)
                )
        )
        .ecosiaThemed(windowUUID, $theme)
    }
}

// MARK: - Theme
@available(iOS 16.0, *)
struct EcosiaAccountErrorViewTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var borderColor = Color.pink
    var textPrimaryColor = Color.black
    var textSecondaryColor = Color.gray
    var iconColor = Color.red

    mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundNegative)
        borderColor = Color(theme.colors.ecosia.borderNegative)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        textSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        iconColor = Color(theme.colors.ecosia.stateError)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {
            EcosiaAccountErrorView(
                title: "Could not load seed counter",
                subtitle: "Something went wrong with displaying your seeds. Please try again later.",
                windowUUID: .XCTestDefaultUUID
            )

            EcosiaAccountErrorView(
                title: "Error Title",
                subtitle: "This is a longer error message that should wrap to multiple lines to show how the component handles longer text content.",
                windowUUID: .XCTestDefaultUUID
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

