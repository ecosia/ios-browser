// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that displays the signed-in state of the account impact view
@available(iOS 16.0, *)
public struct EcosiaAccountSignedInView: View {
    @ObservedObject private var viewModel: EcosiaAccountImpactViewModel
    private let windowUUID: WindowUUID
    private let onProfileTap: () -> Void
    private let onSignOutTap: () -> Void

    @State private var theme = EcosiaAccountSignedInViewTheme()

    public init(
        viewModel: EcosiaAccountImpactViewModel,
        windowUUID: WindowUUID,
        onProfileTap: @escaping () -> Void,
        onSignOutTap: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.onProfileTap = onProfileTap
        self.onSignOutTap = onSignOutTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._m) {
            VStack(alignment: .leading, spacing: 0) {
                // "Your Ecosia" section title
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 40)
                    Text(String.localized(.yourEcosia))
                        .font(.body)
                        .foregroundColor(theme.titleColor)
                        .padding(.leading, .ecosia.space._s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("account_signed_in_title")
                }
                // "Your profile" section title
                Button(action: {
                    Analytics.shared.accountProfileClicked()
                    onProfileTap()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                            .fill(theme.menuItemBackgroundColor)
                            .frame(height: 40)
                        Text(String.localized(.yourProfile))
                                .font(.title3)
                                .foregroundColor(theme.menuItemTextColor)
                                .padding(.leading, .ecosia.space._s)
                                .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .accessibilityIdentifier("account_profile_button")
                .accessibilityLabel(String.localized(.yourProfile))
                .accessibilityAddTraits(.isButton)
            }

            // Sign Out button
            Button(action: {
                Analytics.shared.accountSignOutClicked()
                onSignOutTap()
            }) {
                HStack(alignment: .center, spacing: .ecosia.space._2s) {
                    Image("sign-out", bundle: .ecosia)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(theme.signOutIconColor)

                    Text(String.localized(.signOut))
                        .font(.title3)
                        .foregroundColor(theme.signOutTextColor)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .accessibilityIdentifier("account_sign_out_button")
            .accessibilityLabel(String.localized(.signOut))
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, .ecosia.space._m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ecosiaThemed(windowUUID, $theme)
    }
}

/// Theme configuration for EcosiaAccountSignedInView
@available(iOS 16.0, *)
public struct EcosiaAccountSignedInViewTheme: EcosiaThemeable {
    public var titleColor = Color.black
    public var menuBackgroundColor = Color.white
    public var menuItemBackgroundColor = Color.clear
    public var menuItemTextColor = Color.black
    public var chevronColor = Color.gray
    public var signOutTextColor = Color.red
    public var signOutIconColor = Color.red

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        titleColor = Color(theme.colors.ecosia.textSecondary)
        menuBackgroundColor = Color(theme.colors.layer2)
        menuItemBackgroundColor = Color(theme.colors.ecosia.backgroundElevation1)
        menuItemTextColor = Color(theme.colors.textPrimary)
        chevronColor = Color(theme.colors.textSecondary)
        signOutTextColor = Color(theme.colors.ecosia.buttonContentSecondary)
        signOutIconColor = Color(theme.colors.ecosia.buttonContentSecondary)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountSignedInView_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaAccountSignedInView(
            viewModel: EcosiaAccountImpactViewModel(
                onLogin: {},
                onDismiss: {}
            ),
            windowUUID: .XCTestDefaultUUID,
            onProfileTap: { print("Profile tapped") },
            onSignOutTap: { print("Sign out tapped") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
