// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Bottom-sheet content shown when upload from the NTP omnibox requires authentication.
///
/// Presented from `BrowserViewController+Omnibox` via `NTPOmniboxSheetPresenter` on
/// `HomepageViewController` when the user taps the omnibox upload button while logged out
/// or while missing conversation scopes needed for AI chat attachments.
/// `NTPOmniboxSheetState` dismisses this sheet before starting auth and before opening
/// the upload drawer.
@available(iOS 16.0, *)
public struct OmniboxUploadSignInView: View {
    private let windowUUID: WindowUUID
    private let onSignIn: () -> Void
    private let onCreateAccount: () -> Void
    private let onDismiss: () -> Void

    @State private var theme = OmniboxUploadSignInViewTheme()

    public init(
        windowUUID: WindowUUID,
        onSignIn: @escaping () -> Void,
        onCreateAccount: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.onSignIn = onSignIn
        self.onCreateAccount = onCreateAccount
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._m) {
            Text(String.localized(.signInToUploadFiles))
                .font(.ecosia(size: .ecosia.font._2l, weight: .semibold))
                .foregroundColor(theme.textPrimaryColor)
                .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.signInSheetTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, .ecosia.space._m)

            Text(String.localized(.signInToUploadFilesMessage))
                .font(.ecosia(size: .ecosia.font._l, weight: .regular))
                .foregroundColor(theme.textPrimaryColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.signInSheetBody)
                .frame(maxWidth: .infinity, alignment: .leading)

            actionButtons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ecosiaThemed(windowUUID, $theme)
        .presentationBackgroundIfAvailable(theme.backgroundColor)
    }

    private var actionButtons: some View {
        VStack(spacing: .ecosia.space._1s) {
            Button(action: handleSignInTap) {
                signInButtonLabel
            }
            .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.signInButton)
            .accessibilityLabel(String.localized(.signIn))
            .accessibilityAddTraits(.isButton)

            Button(action: handleCreateAccountTap) {
                createAccountButtonLabel
            }
            .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.createAccountButton)
            .accessibilityLabel(String.localized(.createAccount))
            .accessibilityAddTraits(.isButton)
        }
    }

    private var signInButtonLabel: some View {
        HStack(spacing: .ecosia.space._2s) {
            Image.ecosia("sign-in")
                .renderingMode(.template)
                .foregroundColor(theme.ctaButtonTextColor)
                .accessibilityHidden(true)
            Text(String.localized(.signIn))
        }
        .font(.subheadline)
        .foregroundColor(theme.ctaButtonTextColor)
        .padding(.ecosia.space._m)
        .frame(maxWidth: .infinity)
        .frame(height: UX.ctaButtonHeight)
        .cornerRadius(.ecosia.borderRadius._m)
        .background(theme.ctaButtonBackgroundColor)
        .clipShape(Capsule())
    }

    private var createAccountButtonLabel: some View {
        Text(String.localized(.createAccount))
            .font(.subheadline)
            .foregroundColor(theme.secondaryButtonTextColor)
            .padding(.ecosia.space._m)
            .frame(maxWidth: .infinity)
            .frame(height: UX.ctaButtonHeight)
            .overlay(
                Capsule()
                    .stroke(theme.secondaryButtonBorderColor, lineWidth: UX.secondaryButtonBorderWidth)
            )
    }

    private func handleSignInTap() {
        onSignIn()
    }

    private func handleCreateAccountTap() {
        onCreateAccount()
    }

    private enum UX {
        static let ctaButtonHeight: CGFloat = 40
        static let secondaryButtonBorderWidth: CGFloat = 1
    }
}

private enum OmniboxUploadSignInSheetUX {
    /// Fallback detent while content height is measured.
    static let minDetentHeight: CGFloat = 216
}

/// Sheet wrapper that sizes the detent from measured content so the subtitle can wrap.
@available(iOS 16.0, *)
public struct OmniboxUploadSignInSheet: View {
    private let windowUUID: WindowUUID
    private let onSignIn: () -> Void
    private let onCreateAccount: () -> Void
    private let onDismiss: () -> Void

    public init(
        windowUUID: WindowUUID,
        onSignIn: @escaping () -> Void,
        onCreateAccount: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.onSignIn = onSignIn
        self.onCreateAccount = onCreateAccount
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: .ecosia.space._m)

            OmniboxUploadSignInView(
                windowUUID: windowUUID,
                onSignIn: onSignIn,
                onCreateAccount: onCreateAccount,
                onDismiss: onDismiss
            )
        }
        .padding(.horizontal, .ecosia.space._m)
        .padding(.bottom, .ecosia.space._m)
        .dynamicHeightPresentationDetent(
            minHeight: OmniboxUploadSignInSheetUX.minDetentHeight,
            padding: 0
        )
        .presentationDragIndicator(.visible)
    }
}

@available(iOS 16.0, *)
public struct OmniboxUploadSignInViewTheme: EcosiaThemeable {
    public var backgroundColor = Color.white
    public var textPrimaryColor = Color.black
    public var ctaButtonTextColor = Color.white
    public var ctaButtonBackgroundColor = Color.green
    public var secondaryButtonTextColor = Color.black
    public var secondaryButtonBorderColor = Color.gray

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundPrimaryDecorative)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        ctaButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondaryStatic)
        ctaButtonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundFeatured)
        secondaryButtonTextColor = Color(theme.colors.ecosia.textPrimary)
        secondaryButtonBorderColor = Color(theme.colors.ecosia.borderDecorative)
    }
}

// MARK: - Conditional presentation background

private extension View {
    @ViewBuilder
    func presentationBackgroundIfAvailable(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(color)
        } else {
            self
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct OmniboxUploadSignInView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: .ecosia.space._m)

            OmniboxUploadSignInView(
                windowUUID: .XCTestDefaultUUID,
                onSignIn: {},
                onCreateAccount: {},
                onDismiss: {}
            )
        }
        .padding(.horizontal, .ecosia.space._m)
        .padding(.bottom, .ecosia.space._m)
        .previewLayout(.sizeThatFits)
    }
}
#endif
