// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia
import Redux

// MARK: - SwiftUI Account Login Cell View
@available(iOS 16.0, *)
struct NTPAccountLoginCellView: View {
    @ObservedObject var viewModel: NTPAccountLoginViewModel
    let windowUUID: WindowUUID

    // Use explicit SwiftUI.Environment to avoid ambiguity
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion: Bool

    private enum UX {
        static let seedIconSize: CGFloat = 24
        static let avatarSize: CGFloat = 32
        static let height: CGFloat = 40
        static let minWidth: CGFloat = 88
        // Using Ecosia design system values
        static let gap: CGFloat = .ecosia.space._1s // space-1s = 8pt
        static let paddingVertical: CGFloat = .ecosia.space._2s // space-2s = 4pt
        static let paddingHorizontal: CGFloat = .ecosia.space._2s // space-2s = 4pt
        static let paddingLeft: CGFloat = .ecosia.space._1s // space-1s = 8pt
        static let cornerRadius: CGFloat = 20 // border-radius-full (height/2)
    }

    var body: some View {
        HStack {
            Spacer() // Push content to the right

            Button(action: handleTap) {
                HStack(spacing: UX.gap) {
                    // Seed icon from Ecosia framework
                    Image("seed", bundle: .ecosia)
                        .resizable()
                        .frame(width: UX.seedIconSize, height: UX.seedIconSize)

                    // Animated seed count
                    Text("\(viewModel.seedCount)")
                        .font(.headline)
                        .foregroundColor(Color(themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary))
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.seedCount)

                    // Avatar - real user image or placeholder
                    Group {
                        if let avatarURL = viewModel.userAvatarURL {
                            AsyncImage(url: avatarURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                // Show loading placeholder
                                Circle()
                                    .fill(Color(themeManager.getCurrentTheme(for: windowUUID).colors.iconSecondary))
                            }
                            .frame(width: UX.avatarSize, height: UX.avatarSize)
                            .clipShape(Circle())
                        } else {
                            // Fallback to Ecosia avatar placeholder
                            Circle()
                                .fill(Color(themeManager.getCurrentTheme(for: windowUUID).colors.iconSecondary))
                                .frame(width: UX.avatarSize, height: UX.avatarSize)
                                .overlay(
                                    Image("avatar", bundle: .ecosia)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(6)
                                        .foregroundColor(Color(themeManager.getCurrentTheme(for: windowUUID).colors.iconPrimary))
                                )
                        }
                    }
                }
                .padding(.top, UX.paddingVertical)
                .padding(.bottom, UX.paddingVertical)
                .padding(.leading, UX.paddingLeft)
                .padding(.trailing, UX.paddingHorizontal)
                .frame(minWidth: UX.minWidth, minHeight: UX.height, maxHeight: UX.height)
                .background(Color(themeManager.getCurrentTheme(for: windowUUID).colors.layer1))
                .cornerRadius(UX.cornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func handleTap() {
        if viewModel.isLoggedIn {
            viewModel.performLogout()
        } else {
            viewModel.performLogin()
        }
    }

    private func applyTheme() {
        // Theme is already applied through environment
    }
}

// MARK: - UIKit Wrapper for Collection View Cell

@available(iOS 16.0, *)
final class NTPAccountLoginCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let containerHeight: CGFloat = 64
        static let insetMargin: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let stackSpacing: CGFloat = 4
    }

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPAccountLoginViewModel?

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
        // Create a placeholder hosting controller - will be configured later
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

    func configure(with viewModel: NTPAccountLoginViewModel, windowUUID: WindowUUID) {
        self.viewModel = viewModel

        // Update the SwiftUI view with the new view model
        let swiftUIView = NTPAccountLoginCellView(
            viewModel: viewModel,
            windowUUID: windowUUID
        )

        hostingController?.rootView = AnyView(swiftUIView)
    }

    func updateSeedCount(_ count: Int) {
        viewModel?.updateSeedCount(count)
    }

    // MARK: - Theming
    func applyTheme(theme: Theme) {
        // Theme is handled by the SwiftUI view
    }
}
