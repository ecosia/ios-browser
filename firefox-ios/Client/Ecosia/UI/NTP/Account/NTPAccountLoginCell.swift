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

    var body: some View {
        HStack {
            Spacer()

            ZStack(alignment: .topLeading) {
                EcosiaAccountNavButton(
                    seedCount: viewModel.seedCount,
                    avatarURL: viewModel.userAvatarURL,
                    backgroundColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.backgroundElevation1),
                    textColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.textPrimary),
                    enableAnimation: !reduceMotion,
                    onTap: handleTap
                )

                // Balance increment indicator positioned above-left of counter
                if let increment = viewModel.balanceIncrement {
                    BalanceIncrementAnimationView(
                        increment: increment,
                        textColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.textPrimary)
                    )
                    .offset(x: 20, y: -10) // Position above-left of the counter number
                }
            }
        }
        .padding(.trailing, .ecosia.space._m)
        .onAppear {
            viewModel.registerVisitIfNeeded()
        }
    }

    private func handleTap() {
        if viewModel.isLoggedIn {
            viewModel.performLogout()
        } else {
            viewModel.performLogin()
        }
    }
}

// MARK: - UIKit Wrapper for Collection View Cell

@available(iOS 16.0, *)
final class NTPAccountLoginCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

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
