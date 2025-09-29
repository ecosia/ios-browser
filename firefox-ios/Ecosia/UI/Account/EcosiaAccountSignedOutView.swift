// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that displays the signed-out state of the account impact view
@available(iOS 16.0, *)
public struct EcosiaAccountSignedOutView: View {
    @ObservedObject private var viewModel: EcosiaAccountImpactViewModel
    private let windowUUID: WindowUUID
    private let onLearnMoreTap: () -> Void
    
    @State private var theme = EcosiaAccountSignedOutViewTheme()
    @StateObject private var nudgeCardDelegate = NudgeCardActionHandler()
    
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
        windowUUID: WindowUUID,
        onLearnMoreTap: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.onLearnMoreTap = onLearnMoreTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._l) {
            // Impact card
            ConfigurableNudgeCardView(
                viewModel: NudgeCardViewModel(
                    title: String.localized(.seedsSymbolizeYourOwnImpact),
                    description: String.localized(.collectSeedsEveryDayYouUse),
                    buttonText: String.localized(.learnMoreAboutSeeds),
                    image: UIImage(named: "account-menu-impact-flag", in: .ecosia, with: nil),
                    showsCloseButton: false,
                    style: NudgeCardStyle(
                        backgroundColor: theme.cardBackgroundColor,
                        textPrimaryColor: theme.textPrimaryColor,
                        textSecondaryColor: theme.textSecondaryColor,
                        closeButtonTextColor: theme.closeButtonColor,
                        actionButtonTextColor: theme.actionButtonTextColor
                    ),
                    layout: impactCardLayout
                ),
                delegate: nudgeCardDelegate
            )

            // Sign Up CTA button
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
            .accessibilityIdentifier("account_impact_cta_button")
            .accessibilityLabel(viewModel.mainCTAText)
            .accessibilityAddTraits(.isButton)
        }
        .ecosiaThemed(windowUUID, $theme)
        .onAppear {
            nudgeCardDelegate.onActionTap = {
                viewModel.handleLearnMoreTap()
                onLearnMoreTap()
            }
        }
    }
    
    // MARK: - UX Constants
    private enum UX {
        static let closeButtonSize: CGFloat = 15
        static let imageImpactWidthHeight: CGFloat = 80
        static let borderWidth: CGFloat = 1
    }
}

/// Theme configuration for EcosiaAccountSignedOutView
@available(iOS 16.0, *)
public struct EcosiaAccountSignedOutViewTheme: EcosiaThemeable {
    public var cardBackgroundColor = Color.white
    public var textPrimaryColor = Color.black
    public var textSecondaryColor = Color.gray
    public var closeButtonColor = Color.black
    public var actionButtonTextColor = Color.blue
    public var ctaButtonBackgroundColor = Color.green
    public var levelTextColor = Color.white
    public var levelBackgroundColor = Color.black
    
    public init() {}
    
    public mutating func applyTheme(theme: Theme) {
        cardBackgroundColor = Color(theme.colors.layer2)
        textPrimaryColor = Color(theme.colors.textPrimary)
        textSecondaryColor = Color(theme.colors.textSecondary)
        closeButtonColor = Color(theme.colors.iconPrimary)
        actionButtonTextColor = Color(theme.colors.ecosia.brandPrimary)
        ctaButtonBackgroundColor = Color(theme.colors.ecosia.brandPrimary)
        levelTextColor = Color(theme.colors.textInverted)
        levelBackgroundColor = Color(theme.colors.textPrimary)
    }
}

// MARK: - Nudge Card Action Handler

@available(iOS 16.0, *)
private class NudgeCardActionHandler: ObservableObject, ConfigurableNudgeCardActionDelegate {
    var onActionTap: (() -> Void)?

    func nudgeCardRequestToPerformAction() {
        onActionTap?()
    }

    func nudgeCardRequestToDimiss() {
        // Impact card doesn't have a close button, so this won't be called
    }

    func nudgeCardTapped() {
        // Optional: Handle card tap if needed
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountSignedOutView_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaAccountSignedOutView(
            viewModel: EcosiaAccountImpactViewModel(
                isLoggedIn: false,
                onLogin: {},
                onDismiss: {}
            ),
            windowUUID: .XCTestDefaultUUID,
            onLearnMoreTap: { print("Learn more tapped") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

