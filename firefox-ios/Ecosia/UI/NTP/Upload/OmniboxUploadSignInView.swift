// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Bottom-sheet content shown when a logged-out user tries to upload files from the NTP omnibox.
///
/// Future integration (MOB-4582): present from `BrowserViewController+Omnibox` via
/// `NTPOmniboxSheetPresenter` on `HomepageViewController`. Apply dismiss-before-next-presentation
/// so upload drawers and system pickers open only after this sheet has fully dismissed.
@available(iOS 16.0, *)
public struct OmniboxUploadSignInView: View {
    private let windowUUID: WindowUUID
    private let onSignIn: () -> Void
    private let onCreateAccount: () -> Void
    private let onDismiss: () -> Void

    @State private var theme = OmniboxUploadSignInViewTheme()
    @ObservedObject private var authStateProvider = EcosiaAuthUIStateProvider.shared

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
        VStack(alignment: .leading, spacing: .ecosia.space._l) {
            headerSection
            actionButtons
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .ecosiaThemed(windowUUID, $theme)
        .presentationBackgroundIfAvailable(theme.backgroundColor)
        .onChange(of: authStateProvider.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                onDismiss()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._s) {
            Text(String.localized(.signInToUploadFiles))
                .font(.ecosia(size: .ecosia.font._2l, weight: .bold))
                .foregroundColor(theme.titleColor)
                .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.signInSheetTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(String.localized(.signInToUploadFilesMessage))
                .font(.ecosia(size: .ecosia.font._m, weight: .regular))
                .foregroundColor(theme.bodyColor)
                .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.signInSheetBody)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: .ecosia.space._m) {
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
        HStack(spacing: .ecosia.space._s) {
            Image.ecosia("sign-in")
                .renderingMode(.template)
                .foregroundColor(theme.primaryButtonTextColor)
                .accessibilityHidden(true)
            Text(String.localized(.signIn))
        }
        .font(.ecosia(size: .ecosia.font._m, weight: .medium))
        .foregroundColor(theme.primaryButtonTextColor)
        .frame(maxWidth: .infinity)
        .frame(height: UX.ctaButtonHeight)
        .background(theme.primaryButtonBackgroundColor)
        .clipShape(Capsule())
    }

    private var createAccountButtonLabel: some View {
        Text(String.localized(.createAccount))
            .font(.ecosia(size: .ecosia.font._m, weight: .medium))
            .foregroundColor(theme.secondaryButtonTextColor)
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
        static let ctaButtonHeight: CGFloat = 48
        static let secondaryButtonBorderWidth: CGFloat = 1
    }
}

@available(iOS 16.0, *)
public struct OmniboxUploadSignInViewTheme: EcosiaThemeable {
    public var backgroundColor = Color.white
    public var titleColor = Color.black
    public var bodyColor = Color.black
    public var primaryButtonBackgroundColor = Color.green
    public var primaryButtonTextColor = Color.black
    public var secondaryButtonTextColor = Color.black
    public var secondaryButtonBorderColor = Color.gray

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundPrimaryDecorative)
        titleColor = Color(theme.colors.ecosia.textPrimary)
        bodyColor = Color(theme.colors.ecosia.textPrimary)
        primaryButtonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundFeatured)
        primaryButtonTextColor = Color(theme.colors.ecosia.buttonContentSecondaryStatic)
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
        OmniboxUploadSignInView(
            windowUUID: .XCTestDefaultUUID,
            onSignIn: {},
            onCreateAccount: {},
            onDismiss: {}
        )
        .padding(.horizontal, .ecosia.space._m)
        .previewLayout(.sizeThatFits)
    }
}
#endif
