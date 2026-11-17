// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia
import Combine
// swiftlint:disable closure_body_length

@MainActor
protocol NTPHeaderDelegate: AnyObject {
    func headerOpenCustomizeHomepage()
}

/// NTP header cell containing the navigation actions
final class NTPHeader: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPHeaderViewModel?
    private var glassAppearanceCancellable: AnyCancellable?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        /* The cell can briefly overlap the status bar during a forced rotation (e.g. closing a
           landscape tab). A hosting controller would then pad the header by the top safe area and
           the cell self-sizes taller, pushing the whole NTP down and TopSites under the omnibox.
         */
        if #available(iOS 16.4, *) {
            hostingController.safeAreaRegions = []
        }

        contentView.addSubview(hostingController.view)
        self.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Public Methods

    func configure(with viewModel: NTPHeaderViewModel,
                   windowUUID: WindowUUID) {
        self.viewModel = viewModel

        let swiftUIView = NTPHeaderView(
            viewModel: viewModel,
            windowUUID: windowUUID
        )

        hostingController?.rootView = AnyView(swiftUIView)

        // Set on the hosting view rather than the controller, so sheets presented from the header keep the app's style.
        glassAppearanceCancellable = viewModel.$glassAppearance.sink { [weak self] appearance in
            self?.hostingController?.view.overrideUserInterfaceStyle = appearance.interfaceStyle
        }

        // Pre-iOS 16.4 fallback for `safeAreaRegions = []` (see setup)
        hostingController?.rootView = AnyView(swiftUIView.ignoresSafeArea())
    }
}

// MARK: - Fallback glass button style (iOS 15)

/// Circle-specific glass button style for iOS 15 that avoids `AnyShape` (iOS 16+).
private struct NTPCircleGlassButtonStyle: ButtonStyle {
    let theme: NTPGlassTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    Color.clear.background(.ultraThinMaterial)
                    configuration.isPressed ? theme.tintPressed : theme.tint
                }
                // Ecosia: Force the dark-mode variant of ultraThinMaterial so the glass always
                // reads against the NTP wallpaper regardless of the system colour scheme.
                .environment(\.colorScheme, .dark)
                .clipShape(Circle())
            )
            .clipShape(Circle())
            .overlay(Circle().stroke(theme.border, lineWidth: 1))
    }
}

/// Uses glass on a wallpaper and a solid button on a plain background.
private struct CustomizeButtonBackground: ViewModifier {
    let appearance: NTPGlassAppearance
    let theme: EcosiaCustomizeButtonTheme

    func body(content: Content) -> some View {
        switch appearance {
        case .wallpaper:
            if #available(iOS 16, *) {
                content.buttonStyle(NTPGlassButtonStyle(Circle(), theme: theme.glass))
            } else {
                content.buttonStyle(NTPCircleGlassButtonStyle(theme: theme.glass))
            }
        case .themed:
            content.buttonStyle(NTPSolidButtonStyle(Circle(), theme: theme.solid))
        }
    }
}

/// Groups the header's glass buttons so iOS 26 and later render them together.
private struct NTPHeaderGlassContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            GlassEffectContainer {
                content
            }
        } else {
            content
        }
    }
}

// MARK: - Customize (Pencil) Button

struct EcosiaCustomizeButtonTheme: EcosiaThemeable {
    var glass = NTPGlassTheme()
    var solid = NTPSolidButtonTheme()
    var glassContent = NTPGlassContentTheme()

    mutating func applyTheme(theme: Theme) {
        glass.applyTheme(theme: theme)
        solid.applyTheme(theme: theme)
        glassContent.applyTheme(theme: theme)
    }
}

/// Circular button with a pencil icon for opening NTP customization.
struct EcosiaCustomizeButton: View {
    let windowUUID: WindowUUID
    var appearance: NTPGlassAppearance = .wallpaper
    let onTap: () -> Void
    @State private var theme = EcosiaCustomizeButtonTheme()

    private let buttonSize: CGFloat = .ecosia.space._3l // 40pt
    private let iconSize: CGFloat = 16

    var body: some View {
        Button(action: { onTap() }) {
            Image.ecosia("ntp-pencil-edit")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(theme.glassContent.contentColor(for: appearance))
                .frame(width: iconSize, height: iconSize)
                .frame(width: buttonSize, height: buttonSize)
        }
        .modifier(CustomizeButtonBackground(appearance: appearance, theme: theme))
        .ecosiaThemed(windowUUID, $theme)
        .hapticFeedback()
        .accessibilityLabel(String.localized(.customizeHomepage))
        .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.NTP.customizeButton)
    }
}

private struct AccountNavButtonBoundsKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

// MARK: - SwiftUI Multi-Purpose Header View
struct NTPHeaderView: View {
    @ObservedObject var viewModel: NTPHeaderViewModel
    let windowUUID: WindowUUID
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion: Bool

    var body: some View {
        HStack(spacing: .ecosia.space._1s) {
            EcosiaCustomizeButton(
                windowUUID: windowUUID,
                appearance: viewModel.glassAppearance,
                onTap: handleCustomizeTap
            )
            Spacer()
            if #available(iOS 16, *) {
                EcosiaAccountNavButton(
                    seedCount: viewModel.seedCount,
                    avatarURL: viewModel.userAvatarURL,
                    enableAnimation: !reduceMotion && viewModel.shouldAnimateSeed,
                    showSeedSparkles: viewModel.showSeedSparkles,
                    glassAppearance: viewModel.glassAppearance,
                    windowUUID: windowUUID,
                    onTap: handleTap
                )
                .anchorPreference(key: AccountNavButtonBoundsKey.self, value: .bounds) { $0 }
                .sheet(isPresented: $viewModel.showAccountImpactView) {
                    EcosiaAccountImpactView(
                        viewModel: EcosiaAccountImpactViewModel(
                            onLogin: {
                                viewModel.performLogin()
                            },
                            onDismiss: {
                                viewModel.dismissAccountImpact()
                            }
                        ),
                        windowUUID: windowUUID,
                        webViewUserAgent: EcosiaInAppWebViewUserAgent.mobileUserAgent()
                    )
                    .padding(.horizontal, .ecosia.space._m)
                    .dynamicHeightPresentationDetent()
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .modifier(NTPHeaderGlassContainerModifier())
        // Outside the glass container so the glass can't render over the balance increment.
        .overlayPreferenceValue(AccountNavButtonBoundsKey.self) { anchor in
            GeometryReader { proxy in
                if #available(iOS 16, *) {
                    if let anchor, let increment = viewModel.balanceIncrement {
                        let accountButtonFrame = proxy[anchor]
                        BalanceIncrementAnimationView(
                            increment: increment,
                            windowUUID: windowUUID
                        )
                        .offset(x: accountButtonFrame.minX + 18, y: accountButtonFrame.minY - 8)
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .padding(.horizontal, .ecosia.space._m)
        .padding(.vertical, .ecosia.space._m)
        .onAppear {
            viewModel.refreshSeedState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)) { _ in
            viewModel.refreshSeedState()
        }
    }

    private func handleCustomizeTap() {
        viewModel.openCustomizeHomepage()
    }

    private func handleTap() {
        viewModel.presentAccountImpact()
    }
}
// swiftlint:enable closure_body_length
