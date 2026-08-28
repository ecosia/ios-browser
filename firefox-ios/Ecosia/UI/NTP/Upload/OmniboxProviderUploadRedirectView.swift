// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Shown when the user asks to upload a file while a third-party provider is selected.
/// Those providers cannot receive an upload from the app, so the drawer points the user
/// at the provider's own site instead.
@available(iOS 16.0, *)
public struct OmniboxProviderUploadRedirectView: View {
    private let windowUUID: WindowUUID
    private let provider: SearchProvider
    private let onGoToProvider: () -> Void
    private let onBack: () -> Void

    @State private var theme = OmniboxUploadSignInViewTheme()

    public init(
        windowUUID: WindowUUID,
        provider: SearchProvider,
        onGoToProvider: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.provider = provider
        self.onGoToProvider = onGoToProvider
        self.onBack = onBack
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._m) {
            Text(String.localized(.uploadFilesTitle))
                .font(.ecosia(size: .ecosia.font._2l, weight: .semibold))
                .foregroundColor(theme.textPrimaryColor)
                .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.providerRedirectTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, .ecosia.space._m)

            Text(String(format: .localized(.uploadFilesProviderMessage), provider.aiDisplayName))
                .font(.ecosia(size: .ecosia.font._l, weight: .regular))
                .foregroundColor(theme.textPrimaryColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.providerRedirectBody)
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
            Button(action: onGoToProvider) {
                Text(String(format: .localized(.goToProvider), provider.aiDisplayName))
                    .font(.subheadline)
                    .foregroundColor(theme.ctaButtonTextColor)
                    .padding(.ecosia.space._m)
                    .frame(maxWidth: .infinity)
                    .frame(height: UX.ctaButtonHeight)
                    .background(theme.ctaButtonBackgroundColor)
                    .clipShape(Capsule())
            }
            .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.providerRedirectGoButton)
            .accessibilityAddTraits(.isButton)

            Button(action: onBack) {
                Text(String.localized(.back))
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
            .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.OmniboxUpload.providerRedirectBackButton)
            .accessibilityAddTraits(.isButton)
        }
    }

    private enum UX {
        static let ctaButtonHeight: CGFloat = 40
        static let secondaryButtonBorderWidth: CGFloat = 1
    }
}

// Local copy of the same helper in `OmniboxUploadSignInView` and `OmniboxUploadDrawerView`,
// both of which keep it fileprivate.
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

private enum OmniboxProviderUploadRedirectSheetUX {
    /// Fallback detent while content height is measured.
    static let minDetentHeight: CGFloat = 216
}

/// Sheet wrapper that sizes the detent from measured content so the message can wrap.
@available(iOS 16.0, *)
public struct OmniboxProviderUploadRedirectSheet: View {
    private let windowUUID: WindowUUID
    private let provider: SearchProvider
    private let onGoToProvider: () -> Void
    private let onBack: () -> Void

    public init(
        windowUUID: WindowUUID,
        provider: SearchProvider,
        onGoToProvider: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.provider = provider
        self.onGoToProvider = onGoToProvider
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: .ecosia.space._m)

            OmniboxProviderUploadRedirectView(
                windowUUID: windowUUID,
                provider: provider,
                onGoToProvider: onGoToProvider,
                onBack: onBack
            )
        }
        .padding(.horizontal, .ecosia.space._m)
        .padding(.bottom, .ecosia.space._m)
        .dynamicHeightPresentationDetent(
            minHeight: OmniboxProviderUploadRedirectSheetUX.minDetentHeight,
            padding: 0
        )
        .presentationDragIndicator(.visible)
    }
}
