// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that displays account impact information for both logged-in and guest users
@available(iOS 16.0, *)
public struct EcosiaAccountImpactView: View {
    @ObservedObject private var viewModel: EcosiaAccountImpactViewModel
    private let windowUUID: WindowUUID
    
    @State private var theme = EcosiaAccountImpactViewTheme()
    @State private var showWebViewModal = false
    
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

            // User info section
            HStack(alignment: .center, spacing: .ecosia.space._s) {
                
                EcosiaAccountProgressAvatar(
                    avatarURL: viewModel.avatarURL,
                    progress: viewModel.levelProgress,
                    showSparkles: viewModel.shouldShowLevelUpAnimation,
                    showProgress: true,
                    windowUUID: windowUUID
                )

                VStack(alignment: .leading, spacing: .ecosia.space._1s) {
                     Text(viewModel.userDisplayText)
                         .font(.title3)
                         .foregroundColor(theme.textPrimaryColor)
                         .accessibilityIdentifier("account_impact_username")
                         .frame(minHeight: 25)
                     
                     Text(viewModel.levelDisplayText)
                         .font(.body)
                         .foregroundColor(theme.levelTextColor)
                         .padding(.horizontal, 8)
                         .padding(.vertical, 1)
                         .background(
                             Capsule()
                                 .fill(theme.levelBackgroundColor)
                         )
                     .accessibilityIdentifier("account_impact_level")
                }
            }
            .padding(.horizontal, .ecosia.space._m)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Impact card
            impactCard
                .padding(.horizontal, .ecosia.space._m)
            
            // Main CTA button
            Button(action: viewModel.handleMainCTATap) {
                Text(viewModel.mainCTAText)
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.ecosia.space._m)
                    .foregroundColor(.white)
                    .background(theme.ctaButtonBackgroundColor)
                    .cornerRadius(.ecosia.borderRadius._m)
            }
            .clipShape(Capsule())
            .padding(.horizontal, .ecosia.space._m)
            .accessibilityIdentifier("account_impact_cta_button")
            .accessibilityLabel(viewModel.mainCTAText)
            .accessibilityAddTraits(.isButton)
        }
        .ecosiaThemed(windowUUID, $theme)
        .sheet(isPresented: $showWebViewModal) {
            EcosiaWebViewModal(
                url: EcosiaEnvironment.current.urlProvider.seedCounterInfo,
                windowUUID: windowUUID
            )
        }
    }
    
    private var impactCard: some View {
        HStack(alignment: .top, spacing: .ecosia.space._m) {
            // Impact flag image
            Image("account-menu-impact-flag", bundle: .ecosia)
                .resizable()
                .frame(width: UX.impactImageSize, height: UX.impactImageSize)
                .accessibilityHidden(true)
            
            // Text and Action Stack
            VStack(alignment: .leading, spacing: .ecosia.space._2s) {
                Text(String.localized(.seedsSymbolizeYourOwnImpact))
                    .font(.headline.bold())
                    .foregroundColor(theme.textPrimaryColor)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("impact_card_title")
                
                Text(String.localized(.collectSeedsEveryDayYouUse))
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondaryColor)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("impact_card_description")
                
                Button(action: {
                    viewModel.handleLearnMoreTap()
                    showWebViewModal = true
                }) {
                    Text(String.localized(.learnMoreAboutSeeds))
                        .font(.subheadline)
                        .foregroundColor(theme.actionButtonTextColor)
                }
                .padding(.top, .ecosia.space._1s)
                .accessibilityLabel(String.localized(.learnMoreAboutSeeds))
                .accessibilityIdentifier("impact_card_cta_button")
                .accessibilityAddTraits(.isButton)
            }
            
            Spacer()
        }
        .padding(.ecosia.space._m)
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: .ecosia.borderRadius._l))
        .overlay(
            RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                .stroke(theme.borderColor, lineWidth: UX.borderWidth)
        )
    }
    
    
    // MARK: - UX Constants
    private enum UX {
        static let closeButtonSize: CGFloat = 15
        static let closeButtonBackgroundSize: CGFloat = 30
        static let impactImageSize: CGFloat = 40
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
        actionButtonTextColor = Color(theme.colors.ecosia.textLinkPrimary)
        ctaButtonBackgroundColor = Color(theme.colors.ecosia.brandPrimary)
        borderColor = Color(theme.colors.borderPrimary)
        avatarPlaceholderColor = Color(theme.colors.layer3)
        avatarIconColor = Color(theme.colors.iconSecondary)
        levelTextColor = Color(theme.colors.ecosia.textInversePrimary)
        levelBackgroundColor = Color(theme.colors.ecosia.backgroundInverseNeutral)
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
                    isLoggedIn: false,
                    onLogin: {},
                    onDismiss: {}
                ),
                windowUUID: .XCTestDefaultUUID
            )
            .previewDisplayName("Guest User")
            
            // Logged in user state
            EcosiaAccountImpactView(
                viewModel: EcosiaAccountImpactViewModel(
                    isLoggedIn: true,
                    username: "EcoUser",
                    currentLevel: "Level 3 - Forest Friend",
                    avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                    seedCount: 247,
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
