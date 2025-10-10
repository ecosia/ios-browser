// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A generic error view component that displays error messages with optional title and subtitle
/// Can be used standalone or wrapped within EcosiaErrorToast for toast functionality
@available(iOS 16.0, *)
public struct EcosiaErrorView: View {
    private let title: String?
    private let subtitle: String
    private let windowUUID: WindowUUID
    private let onClose: (() -> Void)?

    @State private var theme = EcosiaErrorViewTheme()

    private struct UX {
        static let borderWidth: CGFloat = 1
        static let closeButtonSize: CGFloat = 16
    }

    /// Initialize error view with title and subtitle
    /// - Parameters:
    ///   - title: Optional bold title text. If nil, only subtitle is shown
    ///   - subtitle: Main error message text
    ///   - windowUUID: Window UUID for theming
    ///   - onClose: Optional closure called when close button is tapped. If nil, no close button is shown
    public init(title: String? = nil, subtitle: String, windowUUID: WindowUUID, onClose: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.windowUUID = windowUUID
        self.onClose = onClose
    }

    public var body: some View {
        HStack(alignment: .center, spacing: .ecosia.space._s) {
            // Error icon
            Image("problem", bundle: .ecosia)
                .resizable()
                .frame(width: .ecosia.space._1l, height: .ecosia.space._1l)
                .foregroundColor(theme.iconColor)

            // Text content
            VStack(alignment: .leading, spacing: .ecosia.space._1s) {
                if let title = title {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(theme.textPrimaryColor)
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(title != nil ? theme.textSecondaryColor : theme.textPrimaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Optional close button
            if let onClose = onClose {
                Button(action: onClose) {
                    Image("close", bundle: .ecosia)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: UX.closeButtonSize, height: UX.closeButtonSize)
                        .foregroundColor(theme.closeButtonColor)
                }
                .accessibilityLabel(String.localized(.close))
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, .ecosia.space._s)
        .padding(.vertical, .ecosia.space._1s)
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
struct EcosiaErrorViewTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var borderColor = Color.pink
    var textPrimaryColor = Color.black
    var textSecondaryColor = Color.gray
    var iconColor = Color.red
    var closeButtonColor = Color.gray

    mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundNegative)
        borderColor = Color(theme.colors.ecosia.borderNegative)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        textSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        iconColor = Color(theme.colors.ecosia.stateError)
        closeButtonColor = Color(theme.colors.ecosia.buttonContentSecondary)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {
            // With title and subtitle
            EcosiaErrorView(
                title: String.localized(.couldNotLoadSeedCounter),
                subtitle: String.localized(.couldNotLoadSeedCounterMessage),
                windowUUID: .XCTestDefaultUUID
            )

            // Subtitle only (for toasts)
            EcosiaErrorView(
                subtitle: String.localized(.signInErrorMessage),
                windowUUID: .XCTestDefaultUUID
            )

            // With close button
            EcosiaErrorView(
                title: "Error Title",
                subtitle: "This is a longer error message that should wrap to multiple lines to show how the component handles longer text content.",
                windowUUID: .XCTestDefaultUUID,
                onClose: { print("Close tapped") }
            )

            // Subtitle only with close button
            EcosiaErrorView(
                subtitle: String.localized(.signInErrorMessage),
                windowUUID: .XCTestDefaultUUID,
                onClose: { print("Close tapped") }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
