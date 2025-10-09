// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI error toast view for auth flow errors
@available(iOS 16.0, *)
public struct EcosiaErrorToast: View {
    private let subtitle: String
    private let windowUUID: WindowUUID
    private let onDismiss: () -> Void

    @State private var theme = EcosiaErrorToastTheme()
    @State private var isVisible = false

    private struct UX {
        static let toastHeight: CGFloat = 56
        static let borderWidth: CGFloat = 1
        static let animationDuration: TimeInterval = 0.5
        static let displayDuration: TimeInterval = 4.5
    }

    public init(
        subtitle: String,
        windowUUID: WindowUUID,
        onDismiss: @escaping () -> Void
    ) {
        self.subtitle = subtitle
        self.windowUUID = windowUUID
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .center, spacing: .ecosia.space._m) {
            // Error icon
            Image("problem", bundle: .ecosia)
                .resizable()
                .frame(width: .ecosia.space._1l, height: .ecosia.space._1l)
                .foregroundColor(theme.iconColor)

            // Text content
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(theme.textColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
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
        .frame(minHeight: UX.toastHeight)
        .padding(.horizontal, .ecosia.space._m)
        .offset(y: isVisible ? 0 : UX.toastHeight + .ecosia.space._m)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            // Animate in
            withAnimation(.easeOut(duration: UX.animationDuration)) {
                isVisible = true
            }

            // Auto-dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + UX.displayDuration) {
                dismiss()
            }
        }
        .onTapGesture {
            dismiss()
        }
        .ecosiaThemed(windowUUID, $theme)
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: UX.animationDuration)) {
            isVisible = false
        }

        // Call onDismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.animationDuration) {
            onDismiss()
        }
    }
}

// MARK: - Theme
@available(iOS 16.0, *)
struct EcosiaErrorToastTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var borderColor = Color.pink
    var textColor = Color.black
    var iconColor = Color.red

    mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundNegative)
        borderColor = Color(theme.colors.ecosia.borderNegative)
        textColor = Color(theme.colors.ecosia.textPrimary)
        iconColor = Color(theme.colors.ecosia.stateError)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorToast_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            EcosiaErrorToast(
                subtitle: "Something went wrong. Please sign in again.",
                windowUUID: .XCTestDefaultUUID,
                onDismiss: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
