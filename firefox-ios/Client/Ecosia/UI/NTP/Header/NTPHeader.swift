// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

// MARK: - SwiftUI Color helpers for NTP glass tokens

private extension Color {
    static var ntpGlassDarkTint: Color {
        Color(uiColor: EcosiaColor.Gray90).opacity(0.32)
    }

    static func ntpGlassBorder(opacity: Double = 0x3D / 255.0) -> Color {
        Color.white.opacity(opacity)
    }
}

@MainActor
protocol NTPHeaderDelegate: AnyObject {
    func headerOpenCustomizeHomepage()
}

/// NTP header cell containing the Ecosia logo and navigation actions
@available(iOS 16.0, *)
final class NTPHeader: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPHeaderViewModel?

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
    }
}

// MARK: - Customize (Pencil) Button

/// Glass-style circular button with a pencil icon for opening NTP customization.
@available(iOS 16.0, *)
private struct EcosiaCustomizeButton: View {
    let onTap: () -> Void

    private let buttonSize: CGFloat = .ecosia.space._3l // 40pt
    private let iconSize: CGFloat = 16

    var body: some View {
        Button(action: onTap) {
            Image.ecosia("ntp-pencil-edit")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: iconSize, height: iconSize)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    ZStack {
                        Color.clear.background(.ultraThinMaterial)
                        Color.ntpGlassDarkTint
                    }
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.ntpGlassBorder(), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(String.localized(.customizeHomepage))
        .accessibilityIdentifier("ntp_customize_button")
    }
}

// MARK: - Ecosia Logo (centered in header)

@available(iOS 16.0, *)
private struct NTPHeaderLogoView: View {
    private let logoHeight: CGFloat = 20

    var body: some View {
        Image("ecosiaLogoLaunch")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(.white)
            .frame(height: logoHeight)
            .accessibilityLabel(String.localized(.ecosiaLogoAccessibilityLabel))
            .accessibilityIdentifier("ntp_header_logo")
    }
}

// MARK: - SwiftUI Multi-Purpose Header View
@available(iOS 16.0, *)
struct NTPHeaderView: View {
    @ObservedObject var viewModel: NTPHeaderViewModel
    let windowUUID: WindowUUID
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion: Bool
    @State private var showAccountImpactView = false

    var body: some View {
        ZStack {
            // Wordmark centered regardless of button widths
            NTPHeaderLogoView()

            HStack(spacing: .ecosia.space._1s) {
                EcosiaCustomizeButton(
                    onTap: handleCustomizeTap
                )
                Spacer()
                ZStack(alignment: .topLeading) {
                    EcosiaAccountNavButton(
                        seedCount: viewModel.seedCount,
                        avatarURL: viewModel.userAvatarURL,
                        enableAnimation: !reduceMotion && viewModel.shouldAnimateSeed,
                        showSeedSparkles: viewModel.showSeedSparkles,
                        windowUUID: windowUUID,
                        onTap: handleTap
                    )
                    .sheet(isPresented: $showAccountImpactView) {
                        EcosiaAccountImpactView(
                            viewModel: EcosiaAccountImpactViewModel(
                                onLogin: {
                                    viewModel.performLogin()
                                },
                                onDismiss: {
                                    showAccountImpactView = false
                                }
                            ),
                            windowUUID: windowUUID
                        )
                        .padding(.horizontal, .ecosia.space._m)
                        .dynamicHeightPresentationDetent()
                    }
                    if let increment = viewModel.balanceIncrement {
                        BalanceIncrementAnimationView(
                            increment: increment,
                            windowUUID: windowUUID
                        )
                        .offset(x: 18, y: -8)
                    }
                }
            }
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
        showAccountImpactView = true
        Analytics.shared.accountHeaderClicked()
    }
}
