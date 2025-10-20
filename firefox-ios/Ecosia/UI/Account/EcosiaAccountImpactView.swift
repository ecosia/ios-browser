// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that displays account impact information for both logged-in and guest users
@available(iOS 16.0, *)
public struct EcosiaAccountImpactView: View {
    @ObservedObject private var viewModel: EcosiaAccountImpactViewModel
    @ObservedObject private var authStateProvider = EcosiaAuthUIStateProvider.shared
    private let windowUUID: WindowUUID

    @State private var theme = EcosiaAccountImpactViewTheme()
    @State private var showSeedsCounterInfoWebView = false
    @State private var showProfileWebView = false

    /// Layout configuration optimized for account impact cards
    private var impactCardLayout: NudgeCardLayout {
        NudgeCardLayout(
            imageSize: UX.imageImpactWidthHeight,
            closeButtonSize: UX.closeButtonSize,
            horizontalSpacing: .ecosia.space._m,
            borderWidth: UX.borderWidth
        )
    }

    public init(
        viewModel: EcosiaAccountImpactViewModel,
        windowUUID: WindowUUID
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
    }

    public var body: some View {
        VStack(spacing: .ecosia.space._l) {
            // Close button
            Button(action: viewModel.handleDismiss) {
                Image("close", bundle: .ecosia)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: UX.closeButtonSize, height: UX.closeButtonSize)
                    .foregroundStyle(theme.closeButtonColor)
                    .background(
                        Circle()
                            .fill(theme.closeButtonBackgroundColor)
                            .frame(width: UX.closeButtonBackgroundSize, height: UX.closeButtonBackgroundSize)
                    )
            }
            .padding(.horizontal, .ecosia.space._l)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel(String.localized(.close))
            .accessibilityIdentifier("account_impact_close_button")
            .accessibilityAddTraits(.isButton)

            // User info section with avatar (always present)
            HStack(alignment: .center, spacing: .ecosia.space._m) {
                EcosiaAccountProgressAvatar(
                    avatarURL: viewModel.avatarURL,
                    progress: viewModel.levelProgress,
                    showSparkles: viewModel.shouldShowLevelUpAnimation,
                    showProgress: true,
                    windowUUID: windowUUID
                )

                VStack(alignment: .leading, spacing: .ecosia.space._1s) {
                     Text(viewModel.userDisplayText)
                        .font(.title3.bold())
                        .foregroundColor(theme.textPrimaryColor)
                        .accessibilityIdentifier("account_impact_username")
                        .frame(minHeight: 25)

                     Text(viewModel.levelDisplayText)
                         .font(.body)
                         .foregroundColor(theme.levelTextColor)
                         .padding(.horizontal, 8)
                         .padding(.vertical, 2)
                         .background(
                             Capsule()
                                 .fill(theme.levelBackgroundColor)
                         )
                     .accessibilityIdentifier("account_impact_level")
                }
            }
            .padding(.horizontal, .ecosia.space._m)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Conditional content based on login state
            if viewModel.isLoggedIn {
                EcosiaAccountSignedInView(
                    viewModel: viewModel,
                    windowUUID: windowUUID,
                    onProfileTap: {
                        showProfileWebView = true
                    },
                    onSignOutTap: {
                        Task {
                            await viewModel.handleLogout()
                        }
                    }
                )
            } else {
                EcosiaAccountSignedOutView(
                    viewModel: viewModel,
                    windowUUID: windowUUID,
                    onLearnMoreTap: {
                        showSeedsCounterInfoWebView = true
                    }
                )
            }
        }
        .ecosiaThemed(windowUUID, $theme)
        .sheet(isPresented: $showSeedsCounterInfoWebView) {
            EcosiaWebViewModal(
                url: EcosiaEnvironment.current.urlProvider.seedCounterInfo,
                windowUUID: windowUUID
            )
        }
        .sheet(isPresented: $showProfileWebView) {
            EcosiaWebViewModal(
                url: EcosiaEnvironment.current.urlProvider.accountProfile,
                windowUUID: windowUUID,
                onLoadComplete: {
                    Analytics.shared.accountProfileViewed()
                },
                onDismiss: {
                    Analytics.shared.accountProfileDismissed()
                }
            )
        }
    }

    // MARK: - UX Constants
    private enum UX {
        static let closeButtonSize: CGFloat = 15
        static let closeButtonBackgroundSize: CGFloat = 30
        static let imageImpactWidthHeight: CGFloat = 80
        static let borderWidth: CGFloat = 1
    }
}

/// Theme configuration for EcosiaAccountImpactView
@available(iOS 16.0, *)
public struct EcosiaAccountImpactViewTheme: EcosiaThemeable {
    public var backgroundColor = Color.white
    public var cardBackgroundColor = Color.white
    public var textPrimaryColor = Color.black
    public var textSecondaryColor = Color.gray
    public var closeButtonColor = Color.black
    public var closeButtonBackgroundColor = Color.gray.opacity(0.2)
    public var actionButtonTextColor = Color.blue
    public var ctaButtonBackgroundColor = Color.green
    public var borderColor = Color.gray.opacity(0.2)
    public var avatarPlaceholderColor = Color.gray.opacity(0.3)
    public var avatarIconColor = Color.gray
    public var levelTextColor = Color.white
    public var levelBackgroundColor = Color.black

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.layer1)
        cardBackgroundColor = Color(theme.colors.layer2)
        textPrimaryColor = Color(theme.colors.textPrimary)
        textSecondaryColor = Color(theme.colors.textSecondary)
        closeButtonColor = Color(theme.colors.iconPrimary)
        closeButtonBackgroundColor = Color(theme.colors.actionSecondary)
        actionButtonTextColor = Color(theme.colors.ecosia.linkPrimary)
        ctaButtonBackgroundColor = Color(theme.colors.ecosia.brandPrimary)
        borderColor = Color(theme.colors.borderPrimary)
        avatarPlaceholderColor = Color(theme.colors.layer3)
        avatarIconColor = Color(theme.colors.iconSecondary)
        levelTextColor = Color(theme.colors.ecosia.textInversePrimary)
        levelBackgroundColor = Color(theme.colors.ecosia.backgroundNeutralInverse)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountImpactView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Guest user state
            EcosiaAccountImpactView(
                viewModel: EcosiaAccountImpactViewModel(
                    onLogin: {},
                    onDismiss: {}
                ),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("Guest User")

            // Logged in user state
            EcosiaAccountImpactView(
                viewModel: EcosiaAccountImpactViewModel(
                    onLogin: {},
                    onDismiss: {}
                ),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("Logged In User")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
